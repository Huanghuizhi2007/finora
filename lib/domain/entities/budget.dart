class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.scope,
    required this.amount,
    required this.period,
    this.categoryId,
    this.notifyAt80 = true,
    this.notifyAt100 = true,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String scope; // total | category
  final double amount;
  final String period; // YYYY-MM or monthly
  final String? categoryId;
  final bool notifyAt80;
  final bool notifyAt100;
  final DateTime? createdAt;

  Budget copyWith({
    double? amount,
    String? period,
    String? categoryId,
    bool? notifyAt80,
    bool? notifyAt100,
  }) {
    return Budget(
      id: id,
      userId: userId,
      scope: scope,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      categoryId: categoryId ?? this.categoryId,
      notifyAt80: notifyAt80 ?? this.notifyAt80,
      notifyAt100: notifyAt100 ?? this.notifyAt100,
      createdAt: createdAt,
    );
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      scope: map['scope'] as String? ?? 'category',
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String,
      categoryId: map['category_id'] as String?,
      notifyAt80: map['notify_80'] as bool? ?? true,
      notifyAt100: map['notify_100'] as bool? ?? true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'scope': scope,
      'amount': amount,
      'period': period,
      'category_id': categoryId,
      'notify_80': notifyAt80,
      'notify_100': notifyAt100,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
