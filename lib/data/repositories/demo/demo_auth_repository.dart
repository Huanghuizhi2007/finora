import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_user.dart';
import '../contracts/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository();

  AppUser? _currentUser;

  AppUser get _demoUser => AppUser(
        id: 'demo-user',
        nickname: AppConstants.demoUserName,
        email: AppConstants.demoUserEmail,
        defaultCurrency: 'CNY',
        language: 'zh_CN',
        isAdmin: true,
        createdAt: DateTime(2026, 3, 1),
      );

  @override
  Future<AppUser?> restoreSession() async => _currentUser;

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('请输入邮箱和密码');
    }
    _currentUser = _demoUser;
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
    _currentUser = _demoUser;
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    _currentUser = _demoUser;
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithApple() async {
    _currentUser = _demoUser;
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
    final updated = _demoUser.copyWith(
      nickname: nickname,
      avatarUrl: avatarUrl,
    );
    _currentUser = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount(String userId) async {
    _currentUser = null;
  }
}
