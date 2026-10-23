// lib/screens/pengunjung_hari_ini/pengunjung_hari_ini_screen.dart
// Daftar lengkap rombongan aktif di satu tanggal — dibuka dari
// "Lihat semua" di card Booking Hari Ini (HomeScreen).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/pengunjung_provider.dart';
import '../../widgets/booking_row.dart';

class PengunjungHariIniScreen extends StatefulWidget {
  final DateTime tanggal;

  const PengunjungHariIniScreen({super.key, required this.tanggal});

  @override
  State<PengunjungHariIniScreen> createState() =>
      _PengunjungHariIniScreenState();
}

class _PengunjungHariIniScreenState extends State<PengunjungHariIniScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tanggalStr = DateFormat('yyyy-MM-dd').format(widget.tanggal);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          children: [
            const Text(
              'Daftar Pengunjung',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('d MMMM yyyy').format(widget.tanggal),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama pengunjung',
                prefixIcon:
                    Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            size: 18, color: Colors.grey.shade500),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0088FF), width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Consumer<PengunjungProvider>(
                builder: (ctx, provider, _) {
                  final semua = provider.aktifPadaTanggal(tanggalStr);
                  final q = _query.trim().toLowerCase();
                  final list = q.isEmpty
                      ? semua
                      : semua
                          .where((p) => p.nama.toLowerCase().contains(q))
                          .toList();

                  if (list.isEmpty) {
                    return _EmptyState(
                      icon: semua.isEmpty
                          ? Icons.holiday_village_outlined
                          : Icons.search_off,
                      text: semua.isEmpty
                          ? 'Tidak ada pengunjung\ndi tanggal ini.'
                          : 'Tidak ada pengunjung\nyang sesuai pencarian.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Color(0xFFEEEEEE),
                      height: 1,
                      thickness: 1,
                    ),
                    itemBuilder: (_, i) => BookingRow(pengunjung: list[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
