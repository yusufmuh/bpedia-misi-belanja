/// Formats whole rupiah as `Rp` plus dot-grouped thousands, without a space:
/// `Rp0`, `Rp1.000`, `Rp1.250.000`, `-Rp25.000`.
String rupiah(int amount) {
  final String digits = amount.toString();
  final bool negative = digits.startsWith('-');
  final String magnitude = negative ? digits.substring(1) : digits;
  final int leadLength = magnitude.length % 3 == 0 ? 3 : magnitude.length % 3;
  final StringBuffer buffer = StringBuffer(negative ? '-Rp' : 'Rp')
    ..write(magnitude.substring(0, leadLength));
  for (int start = leadLength; start < magnitude.length; start += 3) {
    buffer
      ..write('.')
      ..write(magnitude.substring(start, start + 3));
  }
  return buffer.toString();
}
