// lib/utils/qr_share_helper.dart
//
// Helper yang robust untuk screenshot EticketWidget dan share via system sheet.
//
// Tiga masalah yang diselesaikan:
// 1. Guard frame render — toImage() dipanggil setelah frame selesai di-paint
// 2. Cleanup file lama — tidak ada akumulasi file di cache
// 3. Custom exception — pesan error yang informatif, bukan generic Object.toString()

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;


import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QrShareHelper {
  QrShareHelper._(); // utility class

  static const _eticketDirName = 'etickets';
  static const _pixelRatio = 3.0; // resolusi tinggi untuk kualitas gambar bagus

  /// Screenshot widget di [repaintKey] dan buka system share sheet.
  ///
  /// Throws [QrShareException] dengan pesan informatif jika gagal sebelum share.
  static Future<void> share({
    required GlobalKey repaintKey,
    required String fileName, // tanpa ekstensi, hanya nama file
    String? shareText,        // opsional: teks yang menyertai gambar
  }) async {
    // 1. Tunggu frame selesai di-render sebelum capture
    //    Ini mencegah toImage() menghasilkan gambar kosong/blank
    await _waitForPaintedFrame();

    // 2. Dapatkan RenderRepaintBoundary — validasi awal
    final boundary = _getBoundary(repaintKey);

    // 3. Tunggu satu frame lagi untuk memastikan boundary sudah di-paint.
    //    CATATAN: JANGAN pakai boundary.debugNeedsPaint — property itu
    //    menggunakan `late` + `assert()` di Flutter internal, yang CRASH
    //    di release mode (assert dihapus → late variable tidak di-assign).
    await _waitForPaintedFrame();

    // 4. Render ke PNG bytes
    final bytes = await _renderToBytes(boundary);

    // 5. Simpan ke direktori cache yang bersih
    final file = await _saveToCache(bytes, fileName);

    // 6. Buka share sheet — TIDAK await result.
    //
    // share_plus v10+ punya bug di beberapa device Android:
    // broadcast receiver untuk share result tidak terpanggil →
    // variabel `late result` tidak pernah di-assign →
    // LateInitializationError.
    //
    // Solusi: panggil shareXFiles tapi JANGAN await Future-nya.
    // Kita hanya perlu share sheet terbuka — tidak perlu tahu
    // user memilih app mana.
    // ignore: unawaited_futures
    Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: 'E-Ticket Kebun Rojo Camp',
      text: shareText,
    );
  }

  // ── Private helpers ─────────────────────────────────────────

  /// Menunggu sampai SchedulerBinding sudah selesai satu frame paint.
  /// Ini cara yang benar untuk memastikan render tree sudah committed.
  static Future<void> _waitForPaintedFrame() {
    final completer = Completer<void>();
    // scheduleFrameCallback dipanggil setelah frame selesai di-compose
    SchedulerBinding.instance.scheduleFrameCallback(
      (_) => completer.complete(),
      rescheduling: false,
    );
    // Force schedule frame kalau belum ada yang pending
    SchedulerBinding.instance.scheduleFrame();
    return completer.future;
  }

  static RenderRepaintBoundary _getBoundary(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      throw QrShareException(
        'Widget belum di-render atau sudah di-dispose.\n'
        'Pastikan RepaintBoundary sudah tampil di layar sebelum share.',
      );
    }
    final renderObj = context.findRenderObject();
    if (renderObj is! RenderRepaintBoundary) {
      throw QrShareException(
        'GlobalKey tidak menunjuk ke RepaintBoundary.\n'
        'Pastikan key dipakai tepat di widget RepaintBoundary.',
      );
    }
    return renderObj;
  }

  static Future<List<int>> _renderToBytes(
      RenderRepaintBoundary boundary) async {
    ui.Image? image;
    try {
      image = await boundary.toImage(pixelRatio: _pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw QrShareException('Gagal mengkonversi gambar ke format PNG.');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      if (e is QrShareException) rethrow;
      throw QrShareException('Gagal render widget ke gambar: $e');
    } finally {
      // PENTING: dispose image untuk bebaskan memori GPU
      image?.dispose();
    }
  }

  static Future<File> _saveToCache(List<int> bytes, String rawName) async {
    final tempDir = await getTemporaryDirectory();
    final eticketDir = Directory('${tempDir.path}/$_eticketDirName');

    // Hapus semua file e-ticket lama sebelum simpan yang baru
    // Mencegah akumulasi file di cache device
    if (await eticketDir.exists()) {
      await for (final entity in eticketDir.list()) {
        if (entity is File) {
          await entity.delete().catchError(
            (e) {/* Abaikan error delete — tidak kritis */},
          );
        }
      }
    } else {
      await eticketDir.create(recursive: true);
    }

    // Sanitasi nama file: hapus karakter spesial, ganti spasi dengan _
    final safeName = rawName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    // Timestamp sebagai suffix agar nama file selalu unik
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file =
        File('${eticketDir.path}/${safeName}_$timestamp.png');

    await file.writeAsBytes(bytes);
    return file;
  }
}

// ── Custom exception ─────────────────────────────────────────────
//
// Dipakai agar calling screen bisa distinguish antara error yang
// harus ditampilkan ke user vs error internal/bug yang cukup di-log.

class QrShareException implements Exception {
  final String message;
  const QrShareException(this.message);

  @override
  String toString() => message;
}
