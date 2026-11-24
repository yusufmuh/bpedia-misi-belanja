import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/src/wib_date.dart';

import 'support/test_app.dart';

void main() {
  test('hari WIB 0 adalah 1 Jan 1970', () {
    expect(formatWibDateShort(0), '1 Jan 1970');
    expect(formatWibDateLong(0), '1 Januari 1970');
  });

  test('singkatan bulan Indonesia', () {
    const List<String> expected = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    for (int month = 1; month <= 12; month++) {
      expect(
        formatWibDateShort(wibDayOf(2026, month, 5)),
        '5 ${expected[month - 1]} 2026',
      );
    }
  });

  test('tanggal berlaku voucher dan pergantian tahun', () {
    expect(formatWibDateShort(wibDayOf(2026, 12, 24)), '24 Des 2026');
    expect(formatWibDateLong(wibDayOf(2026, 12, 24)), '24 Desember 2026');
    expect(formatWibDateShort(wibDayOf(2026, 12, 24) + 8), '1 Jan 2027');
    expect(formatWibDateShort(wibDayOf(2028, 2, 29)), '29 Feb 2028');
  });
}
