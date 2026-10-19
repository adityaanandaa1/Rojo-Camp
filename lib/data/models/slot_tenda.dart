// lib/data/models/slot_tenda.dart

class SlotTenda {
  final String id;          // Kode unik: 'VIP1', 'REG_A', 'CL_4C', dll
  final String kategori;    // 'MEGA' | 'BIG' | 'CITYLIGHT'
  final String labelDisplay; // Label denah: 'Mega 1', 'Big A', 'Ground 4 C', dll
  final int sortOrder;

  const SlotTenda({
    required this.id,
    required this.kategori,
    required this.labelDisplay,
    required this.sortOrder,
  });

  /// Label tenda terpilih (detail, e-ticket, scan QR, CSV, sync):
  /// 'Mega 1', 'Big A', 'Citylight 4 C'.
  String get labelTampil => kategori == 'CITYLIGHT'
      ? labelDisplay.replaceFirst('Ground', 'Citylight')
      : labelDisplay;

  Map<String, dynamic> toMap() => {
        'id': id,
        'kategori': kategori,
        'label_display': labelDisplay,
        'sort_order': sortOrder,
      };

  factory SlotTenda.fromMap(Map<String, dynamic> map) => SlotTenda(
        id: map['id'] as String,
        kategori: map['kategori'] as String,
        labelDisplay: map['label_display'] as String,
        sortOrder: map['sort_order'] as int,
      );
}
