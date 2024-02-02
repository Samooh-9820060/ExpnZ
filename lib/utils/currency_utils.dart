// currency_utils.dart

String formatCurrencySymbol(String symbol, bool spaceBetween, bool symbolOnLeft) {
  return spaceBetween ? (symbolOnLeft ? "$symbol " : " $symbol") : symbol;
}

String formatAmountWithSeparator(double amount, String thousandsSeparator, int decimalDigits) {
  String formattedAmount = amount.toStringAsFixed(decimalDigits);
  var parts = formattedAmount.split('.');
  parts[0] = parts[0].replaceAllMapped(
      RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[0]}$thousandsSeparator'
  );
  return parts.join('.');
}

double roundToTwoDecimalPlaces(double value) {
  return double.parse(value.toStringAsFixed(2));
}