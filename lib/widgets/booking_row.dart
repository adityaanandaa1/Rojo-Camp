// lib/widgets/booking_row.dart
// Baris rombongan: nama + chip ground yang dipesan + jumlah orang.
// Dipakai di card "Booking Hari Ini" (Home) dan PengunjungHariIniScreen.

import 'package:flutter/material.dart';

import '../data/database/seed_data.dart';
import '../data/models/pengunjung.dart';
import '../screens/detail_pengunjung/detail_pengunjung_screen.dart';

const _kategoriUrut = ['MEGA', 'BIG', 'CITYLIGHT'];

final _kategoriById = {for (final s in kSemuaSlot) s.id: s.kategori};

class _ChipStyle {
  final String label;
  final Color bg;
  final Color fg;
  const _ChipStyle(this.label, this.bg, this.fg);
}

const _chipStyles = {
  'MEGA': _ChipStyle('Mega', Color(0xFFE0F0FF), Color(0xFF0062B8)),
  'BIG': _ChipStyle('Big', Color(0xFFFEF3C7), Color(0xFF92400E)),
  'CITYLIGHT': _ChipStyle('Citylight', Color(0xFFFFEDD5), Color(0xFF9A3412)),
};

/// Kategori unik yang dipesan rombongan — 2 slot Big tetap tampil "Big" sekali.
List<String> kategoriDipesan(Pengunjung p) {
  final set = p.slotIds.map((id) => _kategoriById[id]).whereType<String>().toSet();
  return _kategoriUrut.where(set.contains).toList();
}

class BookingRow extends StatelessWidget {
  final Pengunjung pengunjung;
  final EdgeInsetsGeometry padding;

  const BookingRow({
    super.key,
    required this.pengunjung,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPengunjungScreen(pengunjungId: pengunjung.id),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pengunjung.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final k in kategoriDipesan(pengunjung))
                        _KategoriChip(_chipStyles[k]!),
                      Text(
                        '· ${pengunjung.jumlahPengunjung} orang',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _KategoriChip extends StatelessWidget {
  final _ChipStyle style;
  const _KategoriChip(this.style);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.fg,
        ),
      ),
    );
  }
}
