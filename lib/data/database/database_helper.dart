// lib/data/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'seed_data.dart';
import '../models/pengunjung.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rojocamp_v2.db'); // Nama baru agar tidak crash dengan DB lama
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// v1 → v2: baris yang di-pull dari cloud sebelum perbaikan menyimpan
  /// tanggal sebagai ISO-8601 UTC, bukan YYYY-MM-DD. Re-pull tidak
  /// memperbaikinya karena upsertFromCloud hanya menyinkronkan status,
  /// waktu_checkout, dan keterangan — kolom tanggal tidak pernah di-update.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= 2) return;

    final rows = await db.query(
      'pengunjung',
      columns: ['id', 'tanggal_mulai', 'tanggal_selesai'],
      where: "tanggal_mulai LIKE '%T%' OR tanggal_selesai LIKE '%T%'",
    );

    final batch = db.batch();
    for (final row in rows) {
      batch.update(
        'pengunjung',
        {
          'tanggal_mulai': normalizeDate(row['tanggal_mulai'] as String),
          'tanggal_selesai': normalizeDate(row['tanggal_selesai'] as String),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Tabel 1: pengunjung ───────────────────────────────────
    await db.execute('''
      CREATE TABLE pengunjung (
        id              TEXT PRIMARY KEY,
        nama            TEXT NOT NULL,
        alamat          TEXT NOT NULL,
        tanggal_mulai   TEXT NOT NULL,
        tanggal_selesai TEXT NOT NULL,
        jumlah_pengunjung INTEGER NOT NULL,
        jenis_pesanan   TEXT NOT NULL,
        keterangan      TEXT,
        status          TEXT NOT NULL DEFAULT 'AKTIF',
        waktu_checkout  TEXT,
        created_at      TEXT NOT NULL,
        synced          INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Tabel 2: slot_tenda (master, statis) ──────────────────
    await db.execute('''
      CREATE TABLE slot_tenda (
        id            TEXT PRIMARY KEY,
        kategori      TEXT NOT NULL,
        label_display TEXT NOT NULL,
        sort_order    INTEGER NOT NULL
      )
    ''');

    // ── Tabel 3: pengunjung_slot (junction many-to-many) ──────
    await db.execute('''
      CREATE TABLE pengunjung_slot (
        pengunjung_id TEXT NOT NULL,
        slot_id       TEXT NOT NULL,
        PRIMARY KEY (pengunjung_id, slot_id),
        FOREIGN KEY (pengunjung_id) REFERENCES pengunjung(id) ON DELETE CASCADE,
        FOREIGN KEY (slot_id)       REFERENCES slot_tenda(id)
      )
    ''');

    // ── Seed semua 47 slot master dalam satu batch ────────────
    final batch = db.batch();
    for (final slot in kSemuaSlot) {
      batch.insert('slot_tenda', slot.toMap());
    }
    await batch.commit(noResult: true);
  }
}
