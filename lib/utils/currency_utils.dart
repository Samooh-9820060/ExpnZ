// currency_utils.dart

String formatCurrencySymbol(String symbol, bool spaceBetween, bool symbolOnLeft) {
  return spaceBetween ? (symbolOnLeft ? "$symbol " : " $symbol") : symbol;
}
