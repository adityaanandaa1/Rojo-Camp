// lib/services/sync_service.dart

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/database/seed_data.dart';
import '../data/models/pengunjung.dart';
import '../data/repositories/pengunjung_repository.dart';

// ── Push Result ───────────────────────────────────────────────────

class SyncResult {
  final int synced;      // jumlah record yang berhasil di-sync
  final int skipped;     // jumlah record yang sudah synced sebelumnya
  final String? error;   // pesan error jika gagal, null jika sukses

  const SyncResult({
    required this.synced,
    this.skipped = 0,
    this.error,
  });

  bool get isSuccess => error == null;

  @override
  String toString() => isSuccess
      ? 'SyncResult: $synced synced, $skipped skipped'
      : 'SyncResult error: $error';
}

// ── Pull Result ───────────────────────────────────────────────────

class PullResult {
  final int pulled;    // record BARU yang berhasil ditarik dari cloud
  final int updated;  // record yang STATUS-nya berubah (checkout/batal)
  final int skipped;  // record yang tidak ada perubahan
  final String? error;

  const PullResult({
    required this.pulled,
    this.updated = 0,
    this.skipped = 0,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get hasChanges => pulled > 0 || updated > 0;

  @override
  String toString() => isSuccess
      ? 'PullResult: $pulled inserted, $updated updated, $skipped unchanged'
      : 'PullResult error: $error';
}

// ── Exception ────────────────────────────────────────────────────

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);

  @override
  String toString() => message;
}

// ── Service ──────────────────────────────────────────────────────

class SyncService {
  SyncService._();

  static final Map<String, String> _slotLabels = {
    for (final s in kSemuaSlot) s.id: s.labelDisplay,
  };

  // ── PUSH: Kirim data lokal → Google Sheets ────────────────────

  /// Sync semua record yang belum ter-sync ke Google Sheets.
  ///
  /// Throws [SyncException] dengan pesan yang bisa ditampilkan ke user.
  static Future<SyncResult> syncAll() async {
    // Guard: pastikan URL sudah dikonfigurasi
    if (!AppConfig.isConfigured) {
      throw const SyncException(
        'URL Apps Script belum dikonfigurasi.\n'
        'Edit lib/config/app_config.dart dan isi appScriptUrl.',
      );
    }

    // Cek koneksi internet
    await _checkConnectivity();

    // Ambil record yang belum ter-sync
    final repo = PengunjungRepository();
    final unsynced = await repo.getUnsynced();

    if (unsynced.isEmpty) {
      return const SyncResult(synced: 0, skipped: 0);
    }

    // Kirim ke Apps Script (toleran terhadap redirect 302)
    await _postToAppScript(unsynced);

    // Tandai semua sebagai ter-sync
    await repo.markSynced(unsynced.map((p) => p.id).toList());

    debugPrint('[Sync] ${unsynced.length} records synced successfully.');
    return SyncResult(synced: unsynced.length);
  }

  // ── PULL: Ambil data dari Google Sheets → simpan lokal ────────

  /// Tarik semua data dari Google Sheets dan simpan ke SQLite lokal.
  ///
  /// Berguna untuk device baru / HP teman yang belum punya data.
  /// Record yang sudah ada di lokal tidak akan di-overwrite.
  ///
  /// Throws [SyncException] dengan pesan yang bisa ditampilkan ke user.
  static Future<PullResult> pullFromCloud() async {
    if (!AppConfig.isConfigured) {
      throw const SyncException(
        'URL Apps Script belum dikonfigurasi.\n'
        'Edit lib/config/app_config.dart dan isi appScriptUrl.',
      );
    }

    await _checkConnectivity();

    // GET ke Apps Script dengan parameter action=getData
    final records = await _getFromAppScript();

    if (records.isEmpty) {
      return const PullResult(pulled: 0, skipped: 0);
    }

    final repo = PengunjungRepository();
    int pulled = 0;
    int updated = 0;
    int skipped = 0;

    for (final record in records) {
      final pengunjung = _fromCloudJson(record);
      if (pengunjung == null) continue;

      // Slot ids dari field slot_terpilih_id (semicolon-separated string)
      final slotStr = record['slot_terpilih_id'] as String? ?? '';
      final slotIds = slotStr.isEmpty
          ? <String>[]
          : slotStr.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      final action = await repo.upsertFromCloud(pengunjung, slotIds);
      switch (action) {
        case UpsertCloudAction.inserted:
          pulled++;
        case UpsertCloudAction.updated:
          updated++;
        case UpsertCloudAction.unchanged:
          skipped++;
      }
    }

    debugPrint('[Pull] $pulled inserted, $updated updated, $skipped unchanged.');
    return PullResult(pulled: pulled, updated: updated, skipped: skipped);
  }

  // ── Private helpers ──────────────────────────────────────────

  static Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      // connectivity_plus 6.x mengembalikan List<ConnectivityResult>
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!isOnline) {
        throw const SyncException(
          'Tidak ada koneksi internet.\n'
          'Sambungkan ke WiFi atau data seluler lalu coba lagi.',
        );
      }
    } on SyncException {
      rethrow;
    } catch (e) {
      // Kalau connectivity check error sendiri, coba tetap lanjut sync
      debugPrint('[Sync] Connectivity check error (ignored): $e');
    }
  }

  /// POST data ke Apps Script.
  ///
  /// Google Apps Script sering mengembalikan HTTP 302 (redirect) sebelum
  /// memproses POST — data SUDAH masuk ke Sheets, ini bukan error.
  /// Kita follow redirect dengan http.Client agar dapat response body yang benar.
  static Future<void> _postToAppScript(List<Pengunjung> records) async {
    final payload = jsonEncode({
      'records': records.map(_toJson).toList(),
    });

    final client = http.Client();
    try {
      // Kirim POST; http.Client secara default follow redirect
      final response = await client
          .post(
            Uri.parse(AppConfig.appScriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(
            Duration(seconds: AppConfig.httpTimeoutSeconds),
            onTimeout: () => throw const SyncException(
              'Koneksi timeout (${AppConfig.httpTimeoutSeconds}s).\n'
              'Apps Script mungkin sedang lambat. Coba lagi.',
            ),
          );

      // Terima 200 (sukses langsung) ATAU 302 (redirect — data sudah masuk)
      // Google Apps Script hampir selalu 302 untuk POST yang berhasil
      if (response.statusCode == 302) {
        // Data sudah masuk ke Sheets — redirect ini normal dari Apps Script
        debugPrint('[Sync] HTTP 302 dari Apps Script — data berhasil diterima.');
        return;
      }

      if (response.statusCode != 200) {
        throw SyncException(
          'Server mengembalikan error HTTP ${response.statusCode}.\n'
          'Cek Apps Script deployment URL dan permission "Anyone".',
        );
      }

      // Parse respons Apps Script (hanya untuk status 200)
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] != 'ok') {
          final msg = data['message'] as String? ?? 'Unknown error';
          throw SyncException('Apps Script error: $msg');
        }
      } catch (e) {
        if (e is SyncException) rethrow;
        // Jika body tidak bisa di-parse tapi status 200, anggap berhasil
        debugPrint('[Sync] Response body tidak bisa di-parse (ignored): $e');
      }
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException('Gagal terhubung ke server: $e');
    } finally {
      client.close();
    }
  }

  /// GET semua data dari Apps Script (endpoint ?action=getData).
  static Future<List<Map<String, dynamic>>> _getFromAppScript() async {
    final url = Uri.parse('${AppConfig.appScriptUrl}?action=getData');

    final client = http.Client();
    try {
      final response = await client
          .get(url)
          .timeout(
            Duration(seconds: AppConfig.httpTimeoutSeconds),
            onTimeout: () => throw const SyncException(
              'Koneksi timeout saat mengambil data dari cloud.\n'
              'Coba lagi.',
            ),
          );

      // Apps Script GET biasanya return 200 langsung (bukan redirect)
      if (response.statusCode != 200) {
        throw SyncException(
          'Gagal mengambil data dari cloud (HTTP ${response.statusCode}).\n'
          'Pastikan Code.gs sudah di-update dan di-deploy ulang.',
        );
      }

      try {
        final decoded = jsonDecode(response.body);

        // Jika response adalah HTML (bukan JSON) — Code.gs belum di-update
        if (decoded is! List) {
          if (response.body.contains('<html') || response.body.contains('<!DOCTYPE')) {
            throw const SyncException(
              'Apps Script mengembalikan halaman HTML, bukan JSON.\n'
              'Pastikan Code.gs sudah di-update dengan endpoint ?action=getData\n'
              'dan sudah di-deploy ulang (New Deployment).',
            );
          }
          throw const SyncException('Format respons dari server tidak valid.');
        }

        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        if (e is SyncException) rethrow;
        throw SyncException('Gagal membaca data dari server: $e');
      }
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException('Gagal terhubung ke server: $e');
    } finally {
      client.close();
    }
  }

  /// Konversi row dari Google Sheets (JSON) ke model Pengunjung.
  /// Return null jika data tidak valid / tidak lengkap.
  static Pengunjung? _fromCloudJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final nama = json['nama'] as String?;
      final alamat = json['alamat'] as String?;
      final tanggalMulai = json['tanggal_mulai'] as String?;
      final tanggalSelesai = json['tanggal_selesai'] as String?;
      final createdAt = json['created_at'] as String?;

      // Field wajib — skip jika kosong
      if (id == null || id.isEmpty) return null;
      if (nama == null || nama.isEmpty) return null;
      if (alamat == null) return null;
      if (tanggalMulai == null || tanggalMulai.isEmpty) return null;
      if (tanggalSelesai == null || tanggalSelesai.isEmpty) return null;

      final jumlahPengunjung = json['jumlah_pengunjung'];
      final int jumlah = jumlahPengunjung is int
          ? jumlahPengunjung
          : int.tryParse(jumlahPengunjung.toString()) ?? 1;

      return Pengunjung(
        id: id,
        nama: nama,
        alamat: alamat,
        tanggalMulai: normalizeDate(tanggalMulai),
        tanggalSelesai: normalizeDate(tanggalSelesai),
        jumlahPengunjung: jumlah,
        jenisPesanan: json['jenis_pesanan'] as String? ?? 'ONSITE',
        keterangan: json['keterangan'] as String?,
        status: json['status'] as String? ?? 'AKTIF',
        waktuCheckout: json['waktu_checkout'] as String?,
        createdAt: createdAt ?? DateTime.now().toIso8601String(),
        synced: 1, // Data dari cloud = sudah synced
      );
    } catch (e) {
      debugPrint('[Pull] Skip record karena error parse: $e — data: $json');
      return null;
    }
  }

  /// Konversi Pengunjung ke format JSON yang diharapkan Code.gs.
  static Map<String, dynamic> _toJson(Pengunjung p) {
    return {
      'id': p.id,
      'nama': p.nama,
      'alamat': p.alamat,
      'tanggal_mulai': p.tanggalMulai,
      'tanggal_selesai': p.tanggalSelesai,
      'jumlah_pengunjung': p.jumlahPengunjung,
      'jenis_pesanan': p.jenisPesanan,
      'keterangan': p.keterangan ?? '',
      'status': p.status,
      'waktu_checkout': p.waktuCheckout ?? '',
      // Slot terpilih dikirim sebagai list ID + label untuk readability di Sheets
      'slot_terpilih_id': p.slotIds,
      'slot_terpilih_label': p.slotIds
          .map((id) => _slotLabels[id] ?? id)
          .join('; '),
      'created_at': p.createdAt,
    };
  }
}
