import 'package:flutter_test/flutter_test.dart';
import 'package:rojo_camp/data/models/pengunjung.dart';

void main() {
  test('input YYYY-MM-DD tidak berubah (idempoten)', () {
    expect(normalizeDate('2026-08-08'), '2026-08-08');
    expect(normalizeDate(normalizeDate('2026-08-08')), '2026-08-08');
  });

  test('ISO-8601 UTC dipetakan ke hari kalender lokal', () {
    final utc = DateTime.utc(2026, 8, 7, 17);
    final expected = utc.toLocal().toIso8601String().substring(0, 10);
    expect(normalizeDate(utc.toIso8601String()), expected);
  });

  test('string tak terbaca dikembalikan apa adanya', () {
    expect(normalizeDate('bukan tanggal'), 'bukan tanggal');
  });

  // Kolom tanggal bertipe TEXT, jadi SQLite membandingkannya sebagai string.
  // Ini alasan denah dan statistik beranda bisa berbeda untuk baris yang sama.
  group('batas atas tanggal harus eksklusif hari berikutnya', () {
    const isoHariSama = '2026-09-12T00:00:00.000Z';

    test('<= tanggal MENOLAK timestamp ISO di hari yang sama', () {
      expect(isoHariSama.compareTo('2026-09-12') <= 0, isFalse);
    });

    test('< tanggal+1 MENERIMA timestamp ISO di hari yang sama', () {
      expect(isoHariSama.compareTo('2026-09-13') < 0, isTrue);
    });

    test('kedua predikat setuju untuk tanggal bersih', () {
      const bersih = '2026-09-12';
      expect(bersih.compareTo('2026-09-12') <= 0, isTrue);
      expect(bersih.compareTo('2026-09-13') < 0, isTrue);
    });
  });
}
