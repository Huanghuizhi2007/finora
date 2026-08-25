import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/repositories/demo/demo_auth_repository.dart';
import 'data/repositories/demo/demo_finance_repository.dart';
import 'data/repositories/remote/supabase_auth_repository.dart';
import 'data/repositories/remote/supabase_finance_repository.dart';
import 'data/repositories/contracts/auth_repository.dart';
import 'data/repositories/contracts/finance_repository.dart';
import 'data/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isSupabaseConfigured) {
    try {
      await SupabaseService.initialize(
        AppConfig.supabaseUrl,
        AppConfig.supabaseAnonKey,
      );
    } catch (_) {
      // 配置异常时回退到本地演示模式，避免应用启动失败。
    }
  }

  final AuthRepository authRepository = AppConfig.isSupabaseConfigured
      ? SupabaseAuthRepository()
      : DemoAuthRepository();
  final FinanceRepository financeRepository = AppConfig.isSupabaseConfigured
      ? SupabaseFinanceRepository()
      : DemoFinanceRepository();

  runApp(
    FinoraApp(
      authRepository: authRepository,
      financeRepository: financeRepository,
    ),
  );
}
