// lib/providers/denah_provider.dart

import 'package:flutter/foundation.dart';
import '../data/repositories/slot_repository.dart';

enum SlotState { available, selected, booked }

class DenahProvider extends ChangeNotifier {
  final SlotRepository _repo = SlotRepository();

  Set<String> _selectedSlotIds = {};
  Set<String> _bookedSlotIds = {};
  bool _isLoading = true;
  bool _readOnly = false;

  Set<String> get selected => Set.unmodifiable(_selectedSlotIds);
  Set<String> get booked => _bookedSlotIds;
  bool get isLoading => _isLoading;
  bool get isReadOnly => _readOnly;
  int get selectedCount => _selectedSlotIds.length;

  /// Tanggal selalu wajib diisi (baik mode pilih maupun mode lihat-saja).
  /// Tidak ada lagi mode "tanpa tanggal" — itu sudah dihapus karena
  /// requirement balik ke: tanggal harus diisi dulu sebelum buka Denah.
  Future<void> init({
    required String tanggalMulai,
    required String tanggalSelesai,
    required Set<String> initialSelected,
    String? excludePengunjungId,
    bool readOnly = false,
  }) async {
    _readOnly = readOnly;
    _selectedSlotIds = Set.from(initialSelected);
    _isLoading = true;
    notifyListeners();

    _bookedSlotIds = await _repo.getBookedSlotIds(
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      excludePengunjungId: excludePengunjungId,
    );

    _isLoading = false;
    notifyListeners();
  }

  SlotState getState(String slotId) {
    if (_bookedSlotIds.contains(slotId)) return SlotState.booked;
    if (_selectedSlotIds.contains(slotId)) return SlotState.selected;
    return SlotState.available;
  }

  void toggleSlot(String slotId) {
    if (_readOnly) return;
    if (_bookedSlotIds.contains(slotId)) return;
    if (_selectedSlotIds.contains(slotId)) {
      _selectedSlotIds.remove(slotId);
    } else {
      _selectedSlotIds.add(slotId);
    }
    notifyListeners();
  }
}
