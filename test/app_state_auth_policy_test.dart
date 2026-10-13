import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarhub/services/app_state.dart';

void main() {
  test('email account password policy requires a long mixed password', () {
    expect(AppState.isStrongPassword('Short1!'), isFalse);
    expect(AppState.isStrongPassword('alllowercase123!'), isFalse);
    expect(AppState.isStrongPassword('UppercaseOnly!'), isFalse);
    expect(AppState.isStrongPassword('GoodPassphrase42!'), isTrue);
  });
}
