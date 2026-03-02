class NumberToWords {
  static const List<String> units = [
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
    "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
  ];
  static const List<String> tens = [
    "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
  ];

  static String convertAmount(double amount) {
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    if (rupees == 0 && paise == 0) return "Zero Rupees Only";

    String result = "";
    if (rupees > 0) {
      result += _convertToWords(rupees) + " Rupees";
    }

    if (paise > 0) {
      if (result.isNotEmpty) result += " and ";
      result += _convertToWords(paise) + " Paise";
    }

    return result.trim() + " only";
  }

  static String _convertToWords(int n) {
    if (n == 0) return "Zero";

    String result = "";

    if (n >= 10000000) { // Crores
      result += _convertToWords(n ~/ 10000000) + " Crore ";
      n %= 10000000;
    }

    if (n >= 100000) { // Lakhs
      result += _convertToWords(n ~/ 100000) + " Lakh ";
      n %= 100000;
    }

    if (n >= 1000) { // Thousands
      result += _convertToWords(n ~/ 1000) + " Thousand ";
      n %= 1000;
    }

    if (n >= 100) { // Hundreds
      result += _convertToWords(n ~/ 100) + " Hundred ";
      n %= 100;
    }

    if (n > 0) {
      if (n < 20) {
        result += units[n] + " ";
      } else {
        result += tens[n ~/ 10] + " ";
        if (n % 10 > 0) {
          result += units[n % 10] + " ";
        }
      }
    }

    return result.trim();
  }
}
