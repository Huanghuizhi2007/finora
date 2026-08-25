import 'package:flutter/foundation.dart';

import '../data/repositories/contracts/auth_repository.dart';
import '../domain/entities/app_user.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._authRepository) {
    restore();
  }

  final AuthRepository _authRepository;

  AppUser? _user;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _message;
  String? _notice;

  AppUser? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get message => _message;
  String? get notice => _notice;

  Future<void> restore() async {
    _isInitializing = true;
    notifyListeners();
    try {
      _user = await _authRepository.restoreSession();
      _message = null;
    } catch (error) {
      _message = _friendly(error);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _run(
      () async {
        final user = await _authRepository.signInWithEmail(
          email: email,
          password: password,
        );
        if (user != null) _user = user;
      },
    );
  }

  Future<String?> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    return _run(
      () async {
        final user = await _authRepository.signUp(
          nickname: nickname,
          email: email,
          password: password,
        );
        if (user != null) {
          _user = user;
        } else {
          _notice = '注册成功，请前往邮箱完成验证后登录。';
        }
      },
    );
  }

  Future<String?> signInWithGoogle() async {
    return _run(
      () async {
        final user = await _authRepository.signInWithGoogle();
        if (user != null) _user = user;
      },
    );
  }

  Future<String?> signInWithApple() async {
    return _run(
      () async {
        final user = await _authRepository.signInWithApple();
        if (user != null) _user = user;
      },
    );
  }

  Future<String?> sendPasswordReset(String email) async {
    return _run(
      () async {
        await _authRepository.sendPasswordReset(email);
        _notice = '重置密码链接已发送到你的邮箱。';
      },
    );
  }

  Future<String?> changePassword(String newPassword) async {
    return _run(() => _authRepository.changePassword(newPassword));
  }

  Future<String?> updateProfile({
    String? nickname,
    String? avatarUrl,
  }) async {
    final current = _user;
    if (current == null) return '请先登录';
    return _run(
      () async {
        _user = await _authRepository.updateProfile(
          userId: current.id,
          nickname: nickname,
          avatarUrl: avatarUrl,
        );
      },
    );
  }

  Future<String?> signOut() async {
    return _run(
      () async {
        await _authRepository.signOut();
        _user = null;
      },
    );
  }

  Future<String?> deleteAccount() async {
    final current = _user;
    if (current == null) return '请先登录';
    return _run(
      () async {
        await _authRepository.deleteAccount(current.id);
        _user = null;
      },
    );
  }

  Future<String?> _run(Future<void> Function() action) async {
    _isLoading = true;
    _message = null;
    _notice = null;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (error) {
      _message = _friendly(error);
      return _message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendly(Object error) {
    final text = error.toString();
    if (text.contains('already registered')) return '该邮箱已经注册，请直接登录。';
    if (text.contains('Invalid login credentials')) return '邮箱或密码不正确。';
    if (text.contains('Email not confirmed')) return '邮箱尚未验证，请先查收验证邮件。';
    if (text.contains('network') || text.contains('Network')) {
      return '网络连接失败，请稍后重试。';
    }
    if (text.startsWith('Exception: ')) return text.substring(11);
    return text;
  }
}
