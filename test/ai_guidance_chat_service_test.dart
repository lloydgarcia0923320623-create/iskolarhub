import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarhub/screens/models/scholarship.dart';
import 'package:iskolarhub/services/ai_guidance_chat_service.dart';

void main() {
  final scholarship = Scholarship(
    id: 'north-valley-grant',
    name: 'North Valley Grant',
    provider: 'North Valley Foundation',
    description: 'Financial support for undergraduate students.',
    minGwa: 2.0,
    courses: ['Education'],
    yearLevels: [1, 2],
    maxIncome: 30000,
    deadline: DateTime(2026, 12, 31),
    requirements: ['Certified grades'],
    applicationUrl: 'https://example.org/apply',
    sourceUrl: 'https://example.org/grant',
  );

  test('retrieves scholarship records relevant to a question', () {
    final passages = AiGuidanceChatService.retrieveContext(
      'What is the North Valley Grant deadline?',
      [scholarship],
    );

    expect(passages, hasLength(1));
    expect(passages.single, contains('Deadline: 2026-12-31'));
    expect(passages.single, contains('North Valley Foundation'));
  });

  test('retrieves matching document-guide information', () {
    final passages = AiGuidanceChatService.retrieveContext(
      'How can I request certified grades?',
      [scholarship],
    );

    expect(passages, isNotEmpty);
    expect(
        passages.any((passage) => passage.contains('Document guide: Grades')),
        isTrue);
  });

  test('returns no passages for unrelated general-knowledge questions', () {
    final passages = AiGuidanceChatService.retrieveContext(
      'How do I cook adobo?',
      [scholarship],
    );

    expect(passages, isEmpty);
  });
}
