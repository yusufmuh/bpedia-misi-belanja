const List<String> _shortMonths = <String>[
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

const List<String> _longMonths = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Calendar date (as a UTC [DateTime]) of a WIB day number.
DateTime wibCalendarDate(int wibDay) =>
    DateTime.utc(1970).add(Duration(days: wibDay));

/// `24 Des 2026`: visible date label.
String formatWibDateShort(int wibDay) => _format(wibDay, _shortMonths);

/// `24 Desember 2026`: date read by screen readers.
String formatWibDateLong(int wibDay) => _format(wibDay, _longMonths);

String _format(int wibDay, List<String> months) {
  final DateTime date = wibCalendarDate(wibDay);
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
