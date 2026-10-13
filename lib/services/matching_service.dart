import '../screens/models/income_bracket.dart';
import '../screens/models/scholarship.dart';
import '../screens/models/student.dart';

/// Outcome of a single deterministic criterion evaluation.
enum CriterionOutcome {
  satisfied,
  notSatisfied,

  /// The student profile does not yet contain the value this criterion needs.
  missingProfileData,
}

/// One evaluated deterministic criterion of a scholarship program.
class MatchCriterion {
  final String label;
  final String requirement;
  final String studentValue;
  final CriterionOutcome outcome;

  const MatchCriterion({
    required this.label,
    required this.requirement,
    required this.studentValue,
    required this.outcome,
  });

  bool get isSatisfied => outcome == CriterionOutcome.satisfied;
}

/// Full evaluation of one scholarship against one student profile.
///
/// A [isPreliminaryMatch] value of `true` means every deterministic criterion
/// was satisfied by the recorded profile. It is a preliminary result only and
/// never constitutes official eligibility.
class MatchEvaluation {
  final Scholarship scholarship;
  final List<MatchCriterion> criteria;
  final List<String> descriptiveRequirements;

  const MatchEvaluation({
    required this.scholarship,
    required this.criteria,
    required this.descriptiveRequirements,
  });

  bool get isPreliminaryMatch =>
      criteria.isNotEmpty && criteria.every((criterion) => criterion.isSatisfied);

  bool get needsProfileData => criteria
      .any((criterion) => criterion.outcome == CriterionOutcome.missingProfileData);

  List<MatchCriterion> get unmetCriteria =>
      criteria.where((criterion) => !criterion.isSatisfied).toList();

  bool get hasDescriptiveRequirements => descriptiveRequirements.isNotEmpty;
}

/// Rule-based comparison of structured student profile variables against the
/// deterministic criteria encoded for a scholarship program.
///
/// Evaluated variables: GWA, course, year level, and household income.
/// Qualitative criteria such as essays, interviews, or residency conditions are
/// returned separately for manual student review.
class MatchingService {
  const MatchingService();

  MatchEvaluation evaluate(Student student, Scholarship scholarship) {
    final criteria = <MatchCriterion>[
      _evaluateGwa(student, scholarship),
      _evaluateCourse(student, scholarship),
      _evaluateYearLevel(student, scholarship),
      _evaluateIncome(student, scholarship),
    ];

    return MatchEvaluation(
      scholarship: scholarship,
      criteria: criteria,
      descriptiveRequirements: scholarship.descriptiveRequirements,
    );
  }

  MatchCriterion _evaluateGwa(Student student, Scholarship scholarship) {
    final requirement = 'GWA of ${scholarship.minGwa.toStringAsFixed(2)} or better';
    if (student.gwa <= 0) {
      return MatchCriterion(
        label: 'General Weighted Average',
        requirement: requirement,
        studentValue: 'Not provided',
        outcome: CriterionOutcome.missingProfileData,
      );
    }
    return MatchCriterion(
      label: 'General Weighted Average',
      requirement: requirement,
      studentValue: student.gwa.toStringAsFixed(2),
      outcome: student.gwa <= scholarship.minGwa
          ? CriterionOutcome.satisfied
          : CriterionOutcome.notSatisfied,
    );
  }

  MatchCriterion _evaluateCourse(Student student, Scholarship scholarship) {
    if (scholarship.courses.isEmpty) {
      return const MatchCriterion(
        label: 'Course',
        requirement: 'Open to all courses',
        studentValue: 'Any course accepted',
        outcome: CriterionOutcome.satisfied,
      );
    }

    final requirement = 'One of: ${scholarship.courses.join(', ')}';
    if (student.course.trim().isEmpty) {
      return MatchCriterion(
        label: 'Course',
        requirement: requirement,
        studentValue: 'Not provided',
        outcome: CriterionOutcome.missingProfileData,
      );
    }

    final normalizedCourse = student.course.toLowerCase();
    final matched = scholarship.courses.any(
      (course) => normalizedCourse.contains(course.toLowerCase()),
    );
    return MatchCriterion(
      label: 'Course',
      requirement: requirement,
      studentValue: student.course,
      outcome: matched ? CriterionOutcome.satisfied : CriterionOutcome.notSatisfied,
    );
  }

  MatchCriterion _evaluateYearLevel(Student student, Scholarship scholarship) {
    if (scholarship.yearLevels.isEmpty) {
      return const MatchCriterion(
        label: 'Year Level',
        requirement: 'Open to all year levels',
        studentValue: 'Any year level accepted',
        outcome: CriterionOutcome.satisfied,
      );
    }

    final sortedLevels = [...scholarship.yearLevels]..sort();
    final requirement =
        'Year level ${sortedLevels.map((level) => '$level').join(', ')}';
    return MatchCriterion(
      label: 'Year Level',
      requirement: requirement,
      studentValue: 'Year ${student.yearLevel}',
      outcome: scholarship.yearLevels.contains(student.yearLevel)
          ? CriterionOutcome.satisfied
          : CriterionOutcome.notSatisfied,
    );
  }

  MatchCriterion _evaluateIncome(Student student, Scholarship scholarship) {
    final requirement =
        'Household income up to \u20B1${scholarship.maxIncome.toStringAsFixed(0)} per month';
    final bracket = student.incomeBracket ??
        (student.householdIncome <= 0
            ? null
            : IncomeBracket.fromMonthlyIncome(student.householdIncome));
    if (bracket == null) {
      return MatchCriterion(
        label: 'Household Income',
        requirement: requirement,
        studentValue: 'Not provided',
        outcome: CriterionOutcome.missingProfileData,
      );
    }

    return MatchCriterion(
      label: 'Household Income',
      requirement: requirement,
      studentValue: bracket.label,
      outcome: bracket.upperBound <= scholarship.maxIncome
          ? CriterionOutcome.satisfied
          : CriterionOutcome.notSatisfied,
    );
  }
}
