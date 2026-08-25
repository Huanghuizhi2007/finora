import 'package:finora/app.dart';
import 'package:finora/data/repositories/demo/demo_auth_repository.dart';
import 'package:finora/data/repositories/demo/demo_finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders login page in demo mode', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      FinoraApp(
        authRepository: DemoAuthRepository(),
        financeRepository: DemoFinanceRepository(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Finora'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
  });
}
