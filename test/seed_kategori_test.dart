import 'package:flutter_test/flutter_test.dart';
import 'package:rojo_camp/data/database/seed_data.dart';

void main() {
  test('setiap kategori slot punya kartu statistik di beranda', () {
    const kunciStatistik = {'MEGA', 'BIG', 'CITYLIGHT'};
    for (final slot in kSemuaSlot) {
      expect(kunciStatistik, contains(slot.kategori), reason: slot.id);
    }
  });
}
