import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController();

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('theme_mode') ?? 'light';
      _mode = stored == 'light' ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    } catch (_) {
      _mode = ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {
      // 持久化失败不影响当前主题。
    }
  }
}
