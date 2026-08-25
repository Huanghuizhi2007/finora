import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../state/finance_controller.dart';
import '../../state/session_controller.dart';
import '../shell/main_shell.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final finance = context.watch<FinanceController>();

    if (session.isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: AppColors.primaryBlue,
              ),
              SizedBox(height: 18),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = session.user;
    if (user == null) {
      return const LoginPage();
    }

    if (finance.userId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        finance.setUserId(user.id);
      });
    }

    return const MainShell();
  }
}
