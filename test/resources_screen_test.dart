import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarhub/screens/resources_screen.dart';
import 'package:iskolarhub/services/app_state.dart';

void main() {
  testWidgets('resources screen opens with its content and navigation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResourcesScreen(state: AppState()),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Student Resources'), findsOneWidget);
    expect(find.text('AI-Assisted Scholarship Guidance'), findsOneWidget);
    expect(find.text('Document Assistance Guide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
