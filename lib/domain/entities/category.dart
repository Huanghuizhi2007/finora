import 'enums.dart';

class Category {
  const Category({
    required this.id,
    required this.type,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.userId,
    this.isSystem = false,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final TransactionType type;
  final String name;
  final String iconKey;
  final int colorValue;
  final String? userId;
  final bool isSystem;
  final int sortOrder;
  final DateTime? createdAt;

  Category copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      type: type,
      userId: userId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isSystem: isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      type: TransactionType.fromKey(map['type'] as String),
      name: map['name'] as String,
      iconKey: map['icon'] as String? ?? 'more',
      colorValue: (map['color'] as num?)?.toInt() ?? 0xFF94A3B8,
      isSystem: map['is_system'] as bool? ?? false,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'type': type.key,
      'name': name,
      'icon': iconKey,
      'color': colorValue,
      'is_system': isSystem,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
