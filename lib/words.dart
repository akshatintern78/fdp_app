const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

String _twoDigits(int n) {
  if (n < 20) return _ones[n];
  final ten = _tens[n ~/ 10];
  final one = _ones[n % 10];
  return one.isEmpty ? ten : '$ten $one';
}

String _threeDigits(int n) {
  final hundred = n ~/ 100;
  final rest = n % 100;
  final head = hundred == 0 ? '' : '${_ones[hundred]} Hundred';
  if (rest == 0) return head;
  return head.isEmpty ? _twoDigits(rest) : '$head ${_twoDigits(rest)}';
}

String _indianIntegerWords(int n) {
  if (n == 0) return 'Zero';
  const groups = [
    (10000000, 'Crore'),
    (100000, 'Lakh'),
    (1000, 'Thousand'),
  ];
  var remaining = n;
  final parts = <String>[];
  for (final group in groups) {
    final count = remaining ~/ group.$1;
    remaining %= group.$1;
    if (count > 0) parts.add('${_threeDigits(count)} ${group.$2}');
  }
  if (remaining > 0) parts.add(_threeDigits(remaining));
  return parts.join(' ');
}

String amountInWords(num amount) {
  final totalPaise = (amount * 100).round();
  if (totalPaise < 0) return '';
  final rupees = totalPaise ~/ 100;
  final paise = totalPaise % 100;
  var words = 'Rupees ${rupees == 0 ? 'Zero' : _indianIntegerWords(rupees)}';
  if (paise > 0) words += ' and ${_indianIntegerWords(paise)} Paise';
  return '$words Only';
}
