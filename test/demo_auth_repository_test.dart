import 'package:finora/data/repositories/demo/demo_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('demo session restores after app restart and clears on sign out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final first = DemoAuthRepository();
    final user = await first.signUp(
      nickname: '测试用户',
      email: 'test@example.com',
      password: '123456',
    );
    expect(user?.nickname, '测试用户');

    final restarted = DemoAuthRepository();
    final restored = await restarted.restoreSession();
    expect(restored?.email, 'test@example.com');
    expect(restored?.nickname, '测试用户');

    await restarted.signOut();
    final afterSignOut = DemoAuthRepository();
    expect(await afterSignOut.restoreSession(), isNull);
  });
}
