// lib/screens/daftar_pengunjung/daftar_pengunjung_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/pengunjung.dart';
import '../../providers/pengunjung_provider.dart';
import '../detail_pengunjung/detail_pengunjung_screen.dart';
import '../scan_qr/scan_qr_screen.dart';

class DaftarPengunjungScreen extends StatefulWidget {
  const DaftarPengunjungScreen({super.key});

  @override
  State<DaftarPengunjungScreen> createState() =>
      _DaftarPengunjungScreenState();
}

class _DaftarPengunjungScreenState extends State<DaftarPengunjungScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _selectedTab = 0; // 0: Aktif, 1: Non-Aktif

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Pengunjung> _filter(List<Pengunjung> list) {
    // Filter by Tab (0 = AKTIF, 1 = NON_AKTIF)
    final tabStatus = _selectedTab == 0 ? 'AKTIF' : 'NON_AKTIF';
    var filtered = list.where((p) => p.status == tabStatus).toList();

    // Sort based on Tab
    if (_selectedTab == 0) {
      // AKTIF: Check-in terdekat (tanggal_mulai ASC)
      filtered.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));
    } else {
      // NON-AKTIF: Checkout terbaru / dibuat terbaru (DESC)
      filtered.sort((a, b) {
        final dateA = a.waktuCheckout ?? a.createdAt;
        final dateB = b.waktuCheckout ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
    }

    // Filter by Query
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.nama.toLowerCase().contains(q) ||
              p.alamat.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Background for inactive tab area and search bar
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Daftar Pengunjung',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0088FF)),
            tooltip: 'Scan QR Checkout',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanQrScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama pengunjung',
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade500),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(color: Color(0xFF0088FF), width: 1.5),
                ),
              ),
            ),
          ),

          // ── Tab Switcher ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : const Color(0xFFF9F9F9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTab == 0 ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : const Color(0xFFF9F9F9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Non-Aktif',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTab == 1 ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content Area (White Background) ───────────────
          Expanded(
            child: Container(
              color: Colors.white, // Active tab and list background
              child: Column(
                children: [
                  // ── Header Daftar ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nama Pengunjung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── List (filtered) ──────────────────────────
                  Expanded(
                    child: Consumer<PengunjungProvider>(
                      builder: (ctx, provider, _) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF0088FF)),
                          );
                        }

                        // Filter by tab only to check if the category is empty
                        final tabStatus = _selectedTab == 0 ? 'AKTIF' : 'NON_AKTIF';
                        final allInTab = provider.list.where((p) => p.status == tabStatus).toList();

                        if (allInTab.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada pengunjung\ndalam kategori ini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        final filtered = _filter(provider.list);

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tidak ada pengunjung\nyang sesuai pencarian.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: const Color(0xFF0088FF),
                          backgroundColor: Colors.white,
                          onRefresh: () => provider.loadAll(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: Color(0xFFEEEEEE),
                              height: 1,
                              thickness: 1,
                            ),
                            itemBuilder: (ctx, i) => _PengunjungRow(pengunjung: filtered[i]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PengunjungRow extends StatelessWidget {
  final Pengunjung pengunjung;
  const _PengunjungRow({required this.pengunjung});

  // ponytail: normalizeDate lebih dulu — DateFormat.parse hanya membaca
  // potongan awal string ISO, jadi "2026-08-07T17:00:00.000Z" terbaca
  // sebagai 07-08 padahal hari lokalnya 08-08.
  String _formatDate(String yyyyMmDd) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(normalizeDate(yyyyMmDd));
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAktif = pengunjung.status == 'AKTIF';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPengunjungScreen(pengunjungId: pengunjung.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(pengunjung.tanggalMulai)} - ${_formatDate(pengunjung.tanggalSelesai)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pengunjung.jenisPesanan} • ${pengunjung.jumlahPengunjung} orang',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isAktif ? const Color(0xFF00E832) : const Color(0xFFFF3B3B),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isAktif ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  color: isAktif ? const Color(0xFF1A1A1A) : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
