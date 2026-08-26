import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/app_user.dart';
import '../contracts/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository();

  static const String _profileKey = 'finora_demo_profile_v1';

  AppUser? _currentUser;

  @override
  Future<AppUser?> restoreSession() async {
    if (_currentUser != null) return _currentUser;
    final saved = await _readProfile();
    if (saved != null) _currentUser = saved;
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('请输入邮箱和密码');
    }
    final saved = await _readProfile();
    if (saved != null && saved.email == email.trim()) {
      _currentUser = saved;
      return _currentUser;
    }
    _currentUser = _createUser(
      nickname: email.trim().split('@').first,
      email: email.trim(),
    );
    await _saveProfile(_currentUser!);
    return _currentUser;
  }

  @override
  Future<AppUser?> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    if (nickname.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
      throw Exception('请填写昵称、邮箱，并设置至少 6 位密码');
    }
    _currentUser = _createUser(
      nickname: nickname.trim(),
      email: email.trim(),
    );
    await _saveProfile(_currentUser!);
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    _currentUser = await _readProfile() ??
        _createUser(
          nickname: 'Google 用户',
          email: null,
        );
    await _saveProfile(_currentUser!);
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithApple() async {
    _currentUser = await _readProfile() ??
        _createUser(
          nickname: 'Apple 用户',
          email: null,
        );
    await _saveProfile(_currentUser!);
    return _currentUser;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('请输入邮箱');
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('新密码至少需要 6 位');
    }
  }

  @override
  Future<AppUser> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  }) async {
    final current = _currentUser ?? await _readProfile();
    if (current == null) {
      throw Exception('请先登录');
    }
    final updated = current.copyWith(
      nickname: nickname,
      avatarUrl: avatarUrl,
    );
    _currentUser = updated;
    await _saveProfile(updated);
    return updated;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (_) {
      // 本地存储不可用时保持内存状态。
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (_) {
      // 本地存储不可用时保持内存状态。
    }
  }

  AppUser _createUser({
    required String nickname,
    required String? email,
  }) {
    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    final id = normalizedEmail.isNotEmpty
        ? 'demo-$normalizedEmail'
        : nickname == 'Google 用户'
            ? 'demo-google'
            : nickname == 'Apple 用户'
                ? 'demo-apple'
                : 'demo-${DateTime.now().millisecondsSinceEpoch}';
    return AppUser(
      id: id,
      nickname: nickname,
      email: email,
      defaultCurrency: 'CNY',
      language: 'zh_CN',
      isAdmin: true,
      createdAt: DateTime.now(),
    );
  }

  Future<AppUser?> _readProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey);
      if (raw == null) return null;
      return AppUser.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveProfile(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(user.toMap()));
    } catch (_) {
      // 本地存储不可用时仅保留内存会话。
    }
  }
}
