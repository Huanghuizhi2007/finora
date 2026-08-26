import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/contracts/auth_repository.dart';
import 'data/repositories/contracts/finance_repository.dart';
import 'state/finance_controller.dart';
import 'state/session_controller.dart';
import 'state/theme_controller.dart';
import 'ui/auth/auth_gate.dart';

class FinoraApp extends StatelessWidget {
  const FinoraApp({
    super.key,
    required this.authRepository,
    required this.financeRepository,
  });

  final AuthRepository authRepository;
  final FinanceRepository financeRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>(
          create: (_) => SessionController(authRepository),
        ),
        ChangeNotifierProvider<FinanceController>(
          create: (_) => FinanceController(financeRepository)..load(),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController()..load(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Finora',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
