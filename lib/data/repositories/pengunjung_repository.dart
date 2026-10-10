// lib/data/repositories/pengunjung_repository.dart

import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/seed_data.dart';
import '../models/pengunjung.dart';

// Tiga kemungkinan hasil [PengunjungRepository.upsertFromCloud]:
enum UpsertCloudAction {
  inserted, // record baru -> berhasil di-insert
  updated, // record sudah ada -> ada field yang di-update
  unchanged, // record sudah ada -> tidak ada perubahan
}

class PengunjungRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<Database> get _database => _db.database;

  // ── Write ────────────────────────────────────────────────────

  /// INSERT pengunjung + semua slotnya dalam satu transaksi atomic.
  Future<void> insert(Pengunjung pengunjung, List<String> slotIds) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'pengunjung',
        pengunjung.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final slotId in slotIds) {
        await txn.insert('pengunjung_slot', {
          'pengunjung_id': pengunjung.id,
          'slot_id': slotId,
        });
      }
    });
  }

  /// Edit data pengunjung yang sudah ada + ganti seluruh slot assignment.
  ///
  /// SENGAJA tidak menyentuh: id, status, waktu_checkout, created_at —
  /// itu hanya boleh berubah lewat checkout()/batalkan(), bukan lewat edit
  /// biasa. Set synced=0 supaya perubahan ini ke-sync ulang; Code.gs sudah
  /// pakai upsert-by-id jadi baris Sheets yang lama akan ter-update, bukan
  /// terduplikasi.
  Future<void> update(Pengunjung pengunjung, List<String> slotIds) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update(
        'pengunjung',
        {
          'nama': pengunjung.nama,
          'alamat': pengunjung.alamat,
          'tanggal_mulai': pengunjung.tanggalMulai,
          'tanggal_selesai': pengunjung.tanggalSelesai,
          'jumlah_pengunjung': pengunjung.jumlahPengunjung,
          'jenis_pesanan': pengunjung.jenisPesanan,
          'keterangan': pengunjung.keterangan,
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [pengunjung.id],
      );
      // Ganti seluruh slot assignment: hapus yang lama, insert yang baru.
      // Lebih sederhana dan aman daripada diff-insert/delete parsial.
      await txn.delete(
        'pengunjung_slot',
        where: 'pengunjung_id = ?',
        whereArgs: [pengunjung.id],
      );
      for (final slotId in slotIds) {
        await txn.insert('pengunjung_slot', {
          'pengunjung_id': pengunjung.id,
          'slot_id': slotId,
        });
      }
    });
  }

  /// Checkout: ubah status ke NON_AKTIF dan catat waktu.
  Future<void> checkout(String id, String waktuCheckout) async {
    final db = await _database;
    await db.update(
      'pengunjung',
      {'status': 'NON_AKTIF', 'waktu_checkout': waktuCheckout, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batalkan pesanan manual — sama dengan checkout dari sisi data.
  Future<void> batalkan(String id) async {
    final db = await _database;
    await db.update(
      'pengunjung',
      {
        'status': 'NON_AKTIF',
        'waktu_checkout': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hapus pengunjung — slot di pengunjung_slot ikut CASCADE DELETE.
  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('pengunjung', where: 'id = ?', whereArgs: [id]);
  }

  // ── Read ─────────────────────────────────────────────────────

  /// Ambil semua pengunjung beserta slot-nya, urut terbaru dulu.
  Future<List<Pengunjung>> getAll() async {
    final db = await _database;
    final rows = await db.query('pengunjung', orderBy: 'created_at DESC');
    return _withSlots(db, rows);
  }

  /// Ambil satu pengunjung by UUID beserta slot-nya.
  Future<Pengunjung?> getById(String id) async {
    final db = await _database;
    final rows = await db.query('pengunjung', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final slots = await _getSlotIds(db, id);
    return Pengunjung.fromMap(rows.first, slotIds: slots);
  }

  /// Ambil pengunjung yang tanggal_mulai-nya dalam rentang [mulai, selesai].
  /// Dipakai oleh CsvGenerator untuk unduh laporan.
  ///
  /// Filter: `tanggal_mulai >= mulai AND tanggal_mulai <= selesai`
  /// Ini menampilkan pengunjung yang *mulai* camping dalam rentang tersebut.
  Future<List<Pengunjung>> getByDateRange(String mulai, String selesai) async {
    final db = await _database;
    final rows = await db.query(
      'pengunjung',
      where: 'tanggal_mulai >= ? AND tanggal_mulai <= ?',
      whereArgs: [mulai, selesai],
      orderBy: 'tanggal_mulai ASC, nama ASC',
    );
    return _withSlots(db, rows);
  }

  // ── Stats ────────────────────────────────────────────────────

  /// Jumlah slot terpakai per kategori di [tanggal].
  ///
  /// Predikat overlap sama dengan [SlotRepository.getBookedSlotIds]
  /// (window [tanggal, tanggal+1)) supaya statistik dan denah selalu sepakat.
  ///
  /// Kategori diambil dari [kSemuaSlot], BUKAN dari tabel slot_tenda: tabel
  /// itu hanya di-seed di onCreate, jadi install lama masih menyimpan
  /// kategori 'VIP'/'REGULER' setelah seed diganti ke 'MEGA'/'BIG'.
  Future<Map<String, int>> getStatsByDate(String tanggal) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT ps.slot_id
      FROM pengunjung_slot ps
      INNER JOIN pengunjung p ON ps.pengunjung_id = p.id
      WHERE p.status          = 'AKTIF'
        AND p.tanggal_mulai   < date(?, '+1 day')
        AND p.tanggal_selesai > ?
    ''', [tanggal, tanggal]);

    final kategoriById = {for (final s in kSemuaSlot) s.id: s.kategori};
    final stats = <String, int>{'MEGA': 0, 'BIG': 0, 'CITYLIGHT': 0};
    for (final row in rows) {
      final kategori = kategoriById[row['slot_id']];
      if (kategori != null) stats[kategori] = stats[kategori]! + 1;
    }
    return stats;
  }

  // ── Sync (Phase 6) ───────────────────────────────────────────

  Future<List<Pengunjung>> getUnsynced() async {
    final db = await _database;
    final rows = await db.query('pengunjung', where: 'synced = 0');
    return _withSlots(db, rows);
  }

  Future<void> markSynced(List<String> ids) async {
    final db = await _database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'pengunjung',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Helpers ──────────────────────────────────────────────────

  /// Simpan/update data yang ditarik dari cloud ke SQLite lokal.
  ///
  /// - Record **belum ada** -> INSERT lengkap beserta slot-nya
  /// - Record **sudah ada** -> UPDATE field yang bisa berubah:
  ///   `status`, `waktu_checkout`, `keterangan`, `synced`
  ///   Field statis (nama, alamat, tanggal, dll.) tidak di-overwrite.
  /// - Tidak ada perubahan -> return [UpsertCloudAction.unchanged]
  Future<UpsertCloudAction> upsertFromCloud(
    Pengunjung pengunjung,
    List<String> slotIds,
  ) async {
    final db = await _database;

    // Cek apakah record dengan id ini sudah ada
    final existing = await db.query(
      'pengunjung',
      where: 'id = ?',
      whereArgs: [pengunjung.id],
      limit: 1,
    );

    if (existing.isEmpty) {
      // ── INSERT: record baru dari cloud ──────────────────────
      await db.transaction((txn) async {
        await txn.insert(
          'pengunjung',
          pengunjung.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        for (final slotId in slotIds) {
          await txn.insert('pengunjung_slot', {
            'pengunjung_id': pengunjung.id,
            'slot_id': slotId,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
      return UpsertCloudAction.inserted;
    }

    // ── UPDATE: sinkronisasi field yang bisa berubah ─────────
    // Hanya update jika ada perubahan (cegah write berlebihan)
    final localStatus = existing.first['status'] as String?;
    final localCheckout = existing.first['waktu_checkout'] as String?;
    final localKeterangan = existing.first['keterangan'] as String?;

    final cloudStatus = pengunjung.status;
    final cloudCheckout = pengunjung.waktuCheckout;
    final cloudKeterangan = pengunjung.keterangan;

    final statusChanged = localStatus != cloudStatus;
    final checkoutChanged = localCheckout != cloudCheckout;
    final keteranganChanged = localKeterangan != cloudKeterangan;

    if (!statusChanged && !checkoutChanged && !keteranganChanged) {
      // Data sudah sama persis — tidak perlu update
      return UpsertCloudAction.unchanged;
    }

    // Ada perubahan -> update field yang berubah
    await db.update(
      'pengunjung',
      {
        'status': cloudStatus,
        'waktu_checkout': cloudCheckout,
        'keterangan': cloudKeterangan,
        'synced': 1, // data dari cloud = sudah synced
      },
      where: 'id = ?',
      whereArgs: [pengunjung.id],
    );

    return UpsertCloudAction.updated;
  }

  Future<List<Pengunjung>> _withSlots(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    final result = <Pengunjung>[];
    for (final row in rows) {
      final slots = await _getSlotIds(db, row['id'] as String);
      result.add(Pengunjung.fromMap(row, slotIds: slots));
    }
    return result;
  }

  Future<List<String>> _getSlotIds(Database db, String pengunjungId) async {
    final rows = await db.query(
      'pengunjung_slot',
      columns: ['slot_id'],
      where: 'pengunjung_id = ?',
      whereArgs: [pengunjungId],
    );
    return rows.map((r) => r['slot_id'] as String).toList();
  }
}
