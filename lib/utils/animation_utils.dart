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
  // Formatting currency symbol
  String formattedSymbol = formatCurrencySymbol(
      currencyMap['symbol'] ?? '\$',
      currencyMap['spaceBetweenAmountAndSymbol'] ?? false,
      currencyMap['symbolOnLeft'] ?? true
  );

  // Default value if targetValue is null or empty
  double value = 0.0;

  if (targetValue != null && targetValue.isNotEmpty) {
    try {
      // Parse targetValue to double
      value = double.parse(targetValue) * animationValue;
    } catch (e) {
    }
  }

  // Formatting the amount
  String formattedAmount = formatAmountWithSeparator(
      value,
      currencyMap['thousandsSeparator'] ?? ',',
      currencyMap['decimalDigits'] ?? 2
  );

  // Building the final string
  return currencyMap['symbolOnLeft']
      ? '$formattedSymbol$formattedAmount'
      : '$formattedAmount$formattedSymbol';
}

