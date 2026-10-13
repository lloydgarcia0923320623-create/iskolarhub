import '../data/document_guide.dart';
import '../screens/models/income_bracket.dart';
import '../screens/models/scholarship.dart';
import '../screens/models/student.dart';
import 'matching_service.dart';

/// A stored record the guidance answer was derived from.
class GuidanceSource {
  final String title;
  final String detail;

  const GuidanceSource({required this.title, required this.detail});
}

/// An informational answer built only from records already stored in IskolarHub.
///
/// When [isInsufficient] is `true`, no stored record was relevant enough to
/// answer the question and the student is told the information is unavailable
/// rather than being given an unsupported conclusion.
class GuidanceAnswer {
  final String question;
  final String body;
  final List<GuidanceSource> sources;
  final bool isInsufficient;

  const GuidanceAnswer({
    required this.question,
    required this.body,
    required this.sources,
    required this.isInsufficient,
  });
}

/// Local retrieval-based guidance over the scholarship directory.
///
/// The retrieval source is limited to the scholarship records and document
/// guide entries stored in the system. The service never searches the open web,
/// never determines official eligibility, and never issues scholarship
/// decisions.
class GuidanceService {
  const GuidanceService({MatchingService matchingService = const MatchingService()})
      : _matchingService = matchingService;

  final MatchingService _matchingService;

  static const Set<String> _stopWords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'can', 'do', 'does',
    'for', 'from', 'how', 'i', 'in', 'is', 'it', 'its', 'me', 'my', 'of',
    'on', 'or', 'should', 'that', 'the', 'their', 'them', 'there', 'these',
    'this', 'to', 'was', 'what', 'when', 'where', 'which', 'who', 'why',
    'will', 'with', 'you', 'your',
  };

  GuidanceAnswer answer({
    required String question,
    required List<Scholarship> scholarships,
    Student? student,
  }) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return GuidanceAnswer(
        question: question,
        body: 'Type a question about a scholarship, its requirements, or its '
            'deadline. Answers are built only from the records stored in '
            'IskolarHub.',
        sources: const [],
        isInsufficient: true,
      );
    }

    final tokens = _tokenize(trimmed);
    if (tokens.isEmpty) {
      return _insufficient(trimmed);
    }

    final guideEntry = _findGuideEntry(trimmed);
    final scored = _rankScholarships(tokens, scholarships);

    if (scored.isEmpty) {
      if (guideEntry != null) {
        return _guideAnswer(trimmed, guideEntry);
      }
      return _insufficient(trimmed);
    }

    final best = scored.first;
    return _scholarshipAnswer(
      question: trimmed,
      scholarship: best.scholarship,
      related: scored.skip(1).take(2).map((r) => r.scholarship).toList(),
      student: student,
      guideEntry: guideEntry,
    );
  }

  List<String> _tokenize(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9\u00F1\u20B1]+'))
        .where((token) => token.length > 2 && !_stopWords.contains(token))
        .toList();
  }

  DocumentGuideEntry? _findGuideEntry(String question) {
    for (final entry in documentGuideEntries) {
      if (entry.matches(question)) return entry;
    }
    return null;
  }

  List<_RankedScholarship> _rankScholarships(
    List<String> tokens,
    List<Scholarship> scholarships,
  ) {
    final ranked = <_RankedScholarship>[];
    for (final scholarship in scholarships) {
      final haystack = _searchableText(scholarship);
      var score = 0;
      for (final token in tokens) {
        if (haystack.contains(token)) score++;
      }
      if (score > 0) {
        ranked.add(_RankedScholarship(scholarship, score));
      }
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  String _searchableText(Scholarship scholarship) {
    return [
      scholarship.name,
      scholarship.provider,
      scholarship.description,
      scholarship.benefits,
      scholarship.applicationPeriod,
      scholarship.requirements.join(' '),
      scholarship.descriptiveRequirements.join(' '),
      scholarship.courses.join(' '),
    ].join(' ').toLowerCase();
  }

  GuidanceAnswer _scholarshipAnswer({
    required String question,
    required Scholarship scholarship,
    required List<Scholarship> related,
    Student? student,
    DocumentGuideEntry? guideEntry,
  }) {
    final buffer = StringBuffer()
      ..writeln('${scholarship.name} — ${scholarship.provider}')
      ..writeln()
      ..writeln(scholarship.description.isEmpty
          ? 'No description is recorded for this program.'
          : scholarship.description)
      ..writeln()
      ..writeln('Preliminary criteria recorded in IskolarHub:')
      ..writeln('- GWA: ${scholarship.minGwa.toStringAsFixed(2)} or better')
      ..writeln(
          '- Household income: up to \u20B1${scholarship.maxIncome.toStringAsFixed(0)} per month')
      ..writeln('- Course: ${_courseLine(scholarship)}')
      ..writeln('- Year level: ${_yearLine(scholarship)}');

    if (scholarship.benefits.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Benefits: ${scholarship.benefits}');
    }

    buffer
      ..writeln()
      ..writeln('Application deadline: ${_formatDate(scholarship.deadline)}');

    if (scholarship.requirements.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Documentary requirements:')
        ..writeln(scholarship.requirements.map((r) => '- $r').join('\n'));
    }

    if (scholarship.descriptiveRequirements.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Criteria that require your own review (not evaluated '
            'automatically):')
        ..writeln(
            scholarship.descriptiveRequirements.map((r) => '- $r').join('\n'));
    }

    if (student != null && student.gwa > 0) {
      final evaluation = _matchingService.evaluate(student, scholarship);
      buffer
        ..writeln()
        ..writeln(evaluation.isPreliminaryMatch
            ? 'Based on your saved profile, this program is a preliminary match. '
                'This is not official eligibility.'
            : 'Based on your saved profile, this program is not currently a '
                'preliminary match. The criteria not met are listed on the '
                'scholarship page.');
    }

    if (guideEntry != null) {
      buffer
        ..writeln()
        ..writeln('Document preparation — ${guideEntry.name}:')
        ..writeln(guideEntry.summary)
        ..writeln(guideEntry.steps.map((step) => '- $step').join('\n'));
    }

    if (related.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Related records stored in the system: '
            '${related.map((r) => r.name).join('; ')}');
    }

    final sources = <GuidanceSource>[
      GuidanceSource(
        title: scholarship.name,
        detail: 'Provider ${scholarship.provider}; deadline '
            '${_formatDate(scholarship.deadline)}; '
            '${scholarship.verificationStatus.label} record.',
      ),
    ];
    if (guideEntry != null) {
      sources.add(GuidanceSource(
        title: 'Document Assistance Guide — ${guideEntry.name}',
        detail: 'Issued by ${guideEntry.issuingOffice}.',
      ));
    }

    return GuidanceAnswer(
      question: question,
      body: buffer.toString().trim(),
      sources: sources,
      isInsufficient: false,
    );
  }

  GuidanceAnswer _guideAnswer(String question, DocumentGuideEntry entry) {
    final buffer = StringBuffer()
      ..writeln('${entry.name} — ${entry.issuingOffice}')
      ..writeln()
      ..writeln(entry.summary)
      ..writeln()
      ..writeln('Preparation steps:')
      ..writeln(entry.steps.map((step) => '- $step').join('\n'));

    if (entry.reminders.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Reminders:')
        ..writeln(entry.reminders.map((r) => '- $r').join('\n'));
    }

    buffer
      ..writeln()
      ..writeln('No scholarship record matched your question, so this answer '
          'comes from the Document Assistance Guide only.');

    return GuidanceAnswer(
      question: question,
      body: buffer.toString().trim(),
      sources: [
        GuidanceSource(
          title: 'Document Assistance Guide — ${entry.name}',
          detail: 'Issued by ${entry.issuingOffice}.',
        ),
      ],
      isInsufficient: false,
    );
  }

  GuidanceAnswer _insufficient(String question) {
    return GuidanceAnswer(
      question: question,
      body: 'IskolarHub does not have enough information stored in the system to '
          'answer that question. The guidance feature only uses scholarship '
          'records and document guide entries saved in the app, and it does not '
          'search the open web or make official eligibility decisions. Try '
          'naming a scholarship, a requirement, or a deadline.',
      sources: const [],
      isInsufficient: true,
    );
  }

  String _courseLine(Scholarship scholarship) => scholarship.courses.isEmpty
      ? 'open to all courses'
      : scholarship.courses.join(', ');

  String _yearLine(Scholarship scholarship) => scholarship.yearLevels.isEmpty
      ? 'open to all year levels'
      : (scholarship.yearLevels.toList()..sort())
          .map((level) => 'Year $level')
          .join(', ');

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _RankedScholarship {
  final Scholarship scholarship;
  final int score;

  const _RankedScholarship(this.scholarship, this.score);
}

/// Convenience helper so callers can describe an income figure consistently.
String describeIncomeBracket(double monthlyIncome) =>
    IncomeBracket.fromMonthlyIncome(monthlyIncome).label;
