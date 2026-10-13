/// Categorized representation of a student's monthly household income.
///
/// Matching compares the recorded numeric income against a program's income
/// ceiling. The bracket gives that comparison a stable, readable label for the
/// profile, the evaluation summary, and the scholarship record.
enum IncomeBracket {
  upToTenThousand(0, 10000, 'Up to \u20B110,000'),
  upToTwentyThousand(10000, 20000, '\u20B110,001 \u2013 \u20B120,000'),
  upToThirtyThousand(20000, 30000, '\u20B120,001 \u2013 \u20B130,000'),
  upToFiftyThousand(30000, 50000, '\u20B130,001 \u2013 \u20B150,000'),
  upToHundredThousand(50000, 100000, '\u20B150,001 \u2013 \u20B1100,000'),
  aboveHundredThousand(100000, double.infinity, 'Above \u20B1100,000');

  const IncomeBracket(this.lowerBound, this.upperBound, this.label);

  /// Exclusive lower bound of the bracket.
  final double lowerBound;

  /// Inclusive upper bound of the bracket.
  final double upperBound;

  final String label;

  String get storageValue => name;

  static IncomeBracket? fromStorageValue(String? value) {
    for (final bracket in IncomeBracket.values) {
      if (bracket.name == value) return bracket;
    }
    return null;
  }

  static IncomeBracket fromMonthlyIncome(double monthlyIncome) {
    for (final bracket in IncomeBracket.values) {
      if (monthlyIncome > bracket.lowerBound &&
          monthlyIncome <= bracket.upperBound) {
        return bracket;
      }
    }
    return IncomeBracket.aboveHundredThousand;
  }
}
