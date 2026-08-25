class AppUser {
  const AppUser({
    required this.id,
    required this.nickname,
    this.email,
    this.phone,
    this.avatarUrl,
    this.defaultCurrency = 'CNY',
    this.language = 'zh_CN',
    this.isAdmin = false,
    this.createdAt,
  });

  final String id;
  final String nickname;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String defaultCurrency;
  final String language;
  final bool isAdmin;
  final DateTime? createdAt;

  AppUser copyWith({
    String? nickname,
    String? email,
    String? phone,
    String? avatarUrl,
    String? defaultCurrency,
    String? language,
    bool? isAdmin,
  }) {
    return AppUser(
      id: id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      language: language ?? this.language,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      nickname: (map['nickname'] ?? map['username'] ?? '用户') as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      defaultCurrency: (map['default_currency'] ?? 'CNY') as String,
      language: (map['language'] ?? 'zh_CN') as String,
      isAdmin: (map['is_admin'] ?? false) as bool,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nickname': nickname,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'default_currency': defaultCurrency,
      'language': language,
      'is_admin': isAdmin,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
