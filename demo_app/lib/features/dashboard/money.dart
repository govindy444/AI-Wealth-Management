
library;


String formatInr(double amount) {
  final negative = amount < 0;
  final whole = amount.abs().round().toString();

  if (whole.length <= 3) {
    return '${negative ? '-' : ''}₹$whole';
  }

  final last3 = whole.substring(whole.length - 3);
  final groupsOfTwo = <String>[];
  var rest = whole.substring(0, whole.length - 3);
  while (rest.length > 2) {
    groupsOfTwo.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groupsOfTwo.insert(0, rest);

  return '${negative ? '-' : ''}₹${groupsOfTwo.join(',')},$last3';
}


String formatInrCompact(double amount) {
  final negative = amount < 0;
  final v = amount.abs();
  String body;
  if (v >= 10000000) {
    body = '₹${(v / 10000000).toStringAsFixed(2)}Cr';
  } else if (v >= 100000) {
    body = '₹${(v / 100000).toStringAsFixed(2)}L';
  } else {
    return formatInr(amount);
  }
  return '${negative ? '-' : ''}$body';
}
