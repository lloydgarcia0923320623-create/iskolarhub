import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarhub/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;

  testWidgets('IskolarHub app loads the login screen', (tester) async {
    await tester.pumpWidget(const IskolarHubApp());
    await tester.pumpAndSettle();

    expect(find.text('IskolarHub'), findsAtLeastNWidgets(1));
    expect(find.text('Sign in to continue to IskolarHub.'), findsOneWidget);
  });
}
