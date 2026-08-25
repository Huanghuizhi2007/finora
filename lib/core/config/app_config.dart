class AppConfig {
  AppConfig._();

  static const String appName = 'Finora';
  static const String appVersion = '0.1.1';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  static const bool useDemoData = bool.fromEnvironment(
    'USE_DEMO_DATA',
    defaultValue: true,
  );

  static bool get isSupabaseConfigured =>
      !useDemoData &&
      !supabaseUrl.contains('YOUR_PROJECT') &&
      !supabaseAnonKey.contains('YOUR_ANON_KEY');
}
