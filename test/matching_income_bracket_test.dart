import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarhub/screens/models/income_bracket.dart';
import 'package:iskolarhub/screens/models/scholarship.dart';
import 'package:iskolarhub/screens/models/student.dart';
import 'package:iskolarhub/services/matching_service.dart';

void main() {
  const matchingService = MatchingService();

  Scholarship scholarshipWithIncomeLimit(double maxIncome) => Scholarship(
        id: 'income-test',
        name: 'Income Test Scholarship',
        provider: 'Test Provider',
        description: '',
        minGwa: 2.0,
        courses: const [],
        yearLevels: const [],
        maxIncome: maxIncome,
        deadline: DateTime(2027, 1, 1),
        requirements: const [],
        applicationUrl: 'https://example.org',
      );

  test('income bracket qualifies at its inclusive upper boundary', () {
    final result = matchingService.evaluate(
      Student(gwa: 1.5, incomeBracket: IncomeBracket.upToTenThousand),
      scholarshipWithIncomeLimit(10000),
    );

    expect(result.criteria.last.outcome, CriterionOutcome.satisfied);
  });

  test('income bracket does not qualify if its range exceeds the limit', () {
    final result = matchingService.evaluate(
      Student(gwa: 1.5, incomeBracket: IncomeBracket.upToTwentyThousand),
      scholarshipWithIncomeLimit(15000),
    );

    expect(result.criteria.last.outcome, CriterionOutcome.notSatisfied);
  });
}
