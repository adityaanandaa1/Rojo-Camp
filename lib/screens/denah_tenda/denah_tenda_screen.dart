// lib/screens/denah_tenda/denah_tenda_screen.dart
//
// Dua mode, tanggal SELALU wajib diisi sebelum screen ini dibuka:
// 1. Selection mode (readOnly=false): pilih slot untuk rombongan baru.
//    Pemanggil (TambahPengunjungScreen) WAJIB validasi tanggal sudah
//    terisi sebelum push ke sini — screen ini tidak punya fallback
//    "tanpa tanggal" lagi.
// 2. View-only mode (readOnly=true): admin cek ketersediaan ground
//    per tanggal, tanpa bisa memilih apapun. Punya date picker sendiri
//    untuk ganti tanggal yang dilihat (terpisah dari filter di Beranda).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/database/seed_data.dart';
import '../../providers/denah_provider.dart';
import 'widgets/vip_section.dart';
import 'widgets/reguler_section.dart';
import 'widgets/citylight_section.dart';

class DenahTendaScreen extends StatefulWidget {
  /// Untuk readOnly=true: dipakai sebagai tanggal awal yang ditampilkan,
  /// admin bisa ganti lewat date picker bawaan screen ini.
  /// Untuk readOnly=false: rentang tanggal booking yang sedang diisi
  /// di form Tambah Pengunjung — WAJIB sudah valid (non-empty).
  final String tanggalMulai;
  final String tanggalSelesai;
  final Set<String> initialSelected;
  final String? excludePengunjungId;
  final bool readOnly;

  const DenahTendaScreen({
    super.key,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.initialSelected = const {},
    this.excludePengunjungId,
    this.readOnly = false,
  });

  @override
  State<DenahTendaScreen> createState() => _DenahTendaScreenState();
}

class _DenahTendaScreenState extends State<DenahTendaScreen> {
  late final DenahProvider _provider;
  late DateTime _viewDate; // hanya dipakai saat readOnly

  static final _fmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _provider = DenahProvider();
    _viewDate = _fmt.parse(widget.tanggalMulai);
    _loadData();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.readOnly) {
      // View-only: cek ketersediaan untuk SATU hari (_viewDate).
      // Window [viewDate, viewDate] (inklusif) menangkap rombongan yang
      // sedang menginap di hari itu lewat overlap query yang sama dengan
      // mode selection.
      await _provider.init(
        tanggalMulai: _fmt.format(_viewDate),
        tanggalSelesai: _fmt.format(_viewDate),
        initialSelected: const {},
        readOnly: true,
      );
    } else {
      await _provider.init(
        tanggalMulai: widget.tanggalMulai,
        tanggalSelesai: widget.tanggalSelesai,
        initialSelected: widget.initialSelected,
        excludePengunjungId: widget.excludePengunjungId,
        readOnly: false,
      );
    }
  }

  Future<void> _pickViewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0088FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _viewDate = picked);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: _DenahContent(
        readOnly: widget.readOnly,
        viewDate: widget.readOnly ? _viewDate : null,
        onTapDate: widget.readOnly ? _pickViewDate : null,
        rangeLabel: widget.readOnly
            ? null
            : '${widget.tanggalMulai} → ${widget.tanggalSelesai}',
      ),
    );
  }
}

class _DenahContent extends StatelessWidget {
  final bool readOnly;
  final DateTime? viewDate;
  final VoidCallback? onTapDate;
  final String? rangeLabel;

  const _DenahContent({
    required this.readOnly,
    this.viewDate,
    this.onTapDate,
    this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenahProvider>();

    final vipSlots = kSemuaSlot.where((s) => s.kategori == 'MEGA').toList();
    final regulerSlots =
        kSemuaSlot.where((s) => s.kategori == 'BIG').toList();
    final citylightSlots =
        kSemuaSlot.where((s) => s.kategori == 'CITYLIGHT').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(readOnly ? 'Ketersediaan Ground' : 'Denah Tenda'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        actions: [
          if (!readOnly && !provider.isLoading && provider.selectedCount > 0)
            TextButton(
              onPressed: () {
                for (final id in Set.from(provider.selected)) {
                  provider.toggleSlot(id);
                }
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0088FF)),
                  SizedBox(height: 14),
                  Text('Mengecek ketersediaan tenda...',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(20, 16, 20, readOnly ? 24 : 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (readOnly)
                        _DateViewPill(date: viewDate!, onTap: onTapDate!)
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            'Ketersediaan: $rangeLabel',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      const SizedBox(height: 14),
                      _Legend(showSelected: !readOnly),
                      const SizedBox(height: 20),
                      VipSection(slots: vipSlots),
                      const SizedBox(height: 24),
                      RegulerSection(slots: regulerSlots),
                      const SizedBox(height: 24),
                      CitylightSection(slots: citylightSlots),
                    ],
                  ),
                ),
                if (!readOnly)
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: provider.selectedCount == 0
                                ? null
                                : () =>
                                    Navigator.pop(context, provider.selected),
                            child: Text(
                              provider.selectedCount == 0
                                  ? 'Pilih Tenda'
                                  : 'Pilih  (${provider.selectedCount} slot dipilih)',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Date pill untuk mode view-only ───────────────────────────────

class _DateViewPill extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateViewPill({required this.date, required this.onTap});

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final label = _isToday
        ? 'Hari ini, ${DateFormat('d MMM yyyy').format(date)}'
        : DateFormat('d MMMM yyyy').format(date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0088FF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 15, color: Color(0xFF0088FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ketersediaan tanggal: $label',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0088FF),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: Color(0xFF0088FF)),
          ],
        ),
      ),
    );
  }
}

// ── Legend ──────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final bool showSelected;
  const _Legend({this.showSelected = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
            color: Colors.white,
            borderColor: Colors.grey.shade400,
            label: 'Tersedia'),
        if (showSelected) ...[
          const SizedBox(width: 14),
          const _LegendItem(
              color: Color(0xFF0088FF),
              borderColor: Color(0xFF0088FF),
              label: 'Dipilih'),
        ],
        const SizedBox(width: 14),
        const _LegendItem(
            color: Color(0xFF7A7979),
            borderColor: Color(0xFF7A7979),
            label: 'Terisi'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
