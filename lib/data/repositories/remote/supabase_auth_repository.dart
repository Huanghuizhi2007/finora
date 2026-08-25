import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/app_user.dart';
import '../../supabase_service.dart';
import '../contracts/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository();

  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<AppUser?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _profileForUser(user);
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return _profileForUser(response.user!);
  }

  @override
  Future<AppUser?> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{'nickname': nickname.trim()},
    );
    if (response.session == null || response.user == null) {
      return null;
    }
    return _profileForUser(response.user!);
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final auth = await googleUser.authentication;
    if (auth.idToken == null) {
      throw AuthException('无法获取 Google 登录凭证');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: auth.idToken!,
      accessToken: auth.accessToken,
    );
    return _profileForUser(_client.auth.currentUser!);
  }

  @override
  Future<AppUser?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: rawNonce,
    );
    if (credential.identityToken == null) {
      throw AuthException('无法获取 Apple 登录凭证');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: _sha256(rawNonce),
    );
    return _profileForUser(_client.auth.currentUser!);
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<AppUser> updateProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (nickname != null && nickname.trim().isNotEmpty) {
      payload['nickname'] = nickname.trim();
    }
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl.trim().isEmpty ? null : avatarUrl.trim();
    }
    if (payload.isNotEmpty) {
      await _client.from('profiles').update(payload).eq('id', userId);
    }
    final rows = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return AppUser.fromMap(<String, dynamic>{
      ...?rows,
      'id': userId,
      'email': _client.auth.currentUser?.email,
    });
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount(String userId) async {
    await _client.functions.invoke(
      'delete-account',
      body: <String, dynamic>{'userId': userId},
    );
    await _client.auth.signOut();
  }

  Future<AppUser> _profileForUser(User user) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (rows != null) {
      return AppUser.fromMap(<String, dynamic>{
        ...rows,
        'id': user.id,
        'email': user.email,
      });
    }
    final nickname =
        (user.userMetadata?['nickname'] as String?) ?? user.email?.split('@').first ?? '用户';
    return AppUser(
      id: user.id,
      nickname: nickname,
      email: user.email,
      createdAt: null,
    );
  }

  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _sha256(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
