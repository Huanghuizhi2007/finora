import '../../../domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> restoreSession();

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser?> signUp({
    required String nickname,
    required String email,
    required String password,
  });

  Future<AppUser?> signInWithGoogle();

  Future<AppUser?> signInWithApple();

  Future<void> sendPasswordReset(String email);

  Future<void> changePassword(String newPassword);

  Future<AppUser> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  });

  Future<void> signOut();

  Future<void> deleteAccount(String userId);
}
