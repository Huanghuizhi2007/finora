import 'enums.dart';

class FinanceAccount {
  const FinanceAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.iconKey,
    required this.colorValue,
    this.sortOrder = 0,
    this.isArchived = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String iconKey;
  final int colorValue;
  final int sortOrder;
  final bool isArchived;
  final DateTime? createdAt;

  FinanceAccount copyWith({
    String? name,
    AccountType? type,
    double? balance,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    bool? isArchived,
  }) {
    return FinanceAccount(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }

  factory FinanceAccount.fromMap(Map<String, dynamic> map) {
    return FinanceAccount(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: AccountType.fromKey(map['type'] as String? ?? 'wallet'),
      balance: (map['balance'] as num).toDouble(),
      iconKey: map['icon'] as String? ?? 'wallet',
      colorValue: (map['color'] as num?)?.toInt() ?? 0xFF2563EB,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isArchived: map['archived'] as bool? ?? false,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.key,
      'balance': balance,
      'icon': iconKey,
      'color': colorValue,
      'sort_order': sortOrder,
      'archived': isArchived,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
