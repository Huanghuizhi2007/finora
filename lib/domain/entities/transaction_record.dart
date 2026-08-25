import 'enums.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.happenedAt,
    this.note = '',
    this.imageUrl,
    this.importSource = ImportSource.manual,
    this.externalId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final DateTime happenedAt;
  final String note;
  final String? imageUrl;
  final ImportSource importSource;
  final String? externalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionRecord copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    DateTime? happenedAt,
    String? note,
    String? imageUrl,
    ImportSource? importSource,
    String? externalId,
  }) {
    return TransactionRecord(
      id: id,
      userId: userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      happenedAt: happenedAt ?? this.happenedAt,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      importSource: importSource ?? this.importSource,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: TransactionType.fromKey(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      accountId: map['account_id'] as String,
      happenedAt: DateTime.tryParse(map['happened_at'] as String) ??
          DateTime.tryParse(map['happened_at'].toString()) ??
          DateTime.now(),
      note: map['note'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      importSource: ImportSource.fromKey(map['import_source'] as String? ?? 'manual'),
      externalId: map['external_id'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'type': type.key,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId,
      'happened_at': happenedAt.toIso8601String(),
      'note': note,
      'image_url': imageUrl,
      'import_source': importSource.key,
      'external_id': externalId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
