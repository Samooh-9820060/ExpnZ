import 'currency_utils.dart';

String animatedNumber(double animationValue, double targetValue, Map<String, dynamic> currencyMap) {
  String formattedSymbol = formatCurrencySymbol(
      currencyMap['symbol'] ?? '\$',
      currencyMap['spaceBetweenAmountAndSymbol'] ?? false,
      currencyMap['symbolOnLeft'] ?? true
  );

  double value = (targetValue * animationValue).toDouble();
  String formattedAmount = formatAmountWithSeparator(
      value,
      currencyMap['thousandsSeparator'] ?? ',',
      currencyMap['decimalDigits'] ?? 2
  );

  return currencyMap['symbolOnLeft']
      ? '$formattedSymbol$formattedAmount'
      : '$formattedAmount$formattedSymbol';
}

String animatedNumberString(double animationValue, String targetValue, Map<String, dynamic> currencyMap) {
  String formattedSymbol = formatCurrencySymbol(
      currencyMap['symbol'] ?? '\$',
      currencyMap['spaceBetweenAmountAndSymbol'] ?? false,
      currencyMap['symbolOnLeft'] ?? true
  );

  double value = (double.parse(targetValue) * animationValue).toDouble();
  String formattedAmount = formatAmountWithSeparator(
      value,
      currencyMap['thousandsSeparator'] ?? ',',
      currencyMap['decimalDigits'] ?? 2
  );

  return currencyMap['symbolOnLeft']
      ? '$formattedSymbol$formattedAmount'
      : '$formattedAmount$formattedSymbol';
}
