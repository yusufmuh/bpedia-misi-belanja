import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

void main() {
  test('rupiah memakai titik ribuan tanpa spasi', () {
    const Map<int, String> cases = <int, String>{
      0: 'Rp0',
      7: 'Rp7',
      999: 'Rp999',
      1000: 'Rp1.000',
      5000: 'Rp5.000',
      10000: 'Rp10.000',
      74999: 'Rp74.999',
      75000: 'Rp75.000',
      100000: 'Rp100.000',
      1250000: 'Rp1.250.000',
      1000000000: 'Rp1.000.000.000',
      -1: '-Rp1',
      -25000: '-Rp25.000',
      -1250000: '-Rp1.250.000',
    };
    cases.forEach((int amount, String expected) {
      expect(rupiah(amount), expected, reason: '$amount');
    });
  });
}
