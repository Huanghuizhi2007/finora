enum TransactionType {
  expense,
  income;

  String get key => name;
  String get label => this == expense ? '支出' : '收入';

  static TransactionType fromKey(String key) {
    return key == 'income' ? TransactionType.income : TransactionType.expense;
  }
}

enum AccountType {
  wechat('微信支付', 'wechat', 'chat'),
  alipay('支付宝', 'alipay', 'wallet'),
  cash('现金', 'cash', 'payments'),
  bankCard('银行卡', 'bankCard', 'account_balance'),
  creditCard('信用卡', 'creditCard', 'credit_card'),
  savings('储蓄卡', 'savings', 'savings'),
  investment('投资账户', 'investment', 'show_chart'),
  wallet('电子钱包', 'wallet', 'wallet'),
  other('其他账户', 'other', 'category');

  const AccountType(this.label, this.key, this.iconKey);

  final String label;
  final String key;
  final String iconKey;

  static AccountType fromKey(String key) {
    return AccountType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => AccountType.other,
    );
  }
}

enum ImportSource {
  manual('手动', 'manual'),
  wechat('微信账单', 'wechat'),
  alipay('支付宝账单', 'alipay'),
  csv('CSV 导入', 'csv');

  const ImportSource(this.label, this.key);

  final String label;
  final String key;

  static ImportSource fromKey(String key) {
    return ImportSource.values.firstWhere(
      (source) => source.key == key,
      orElse: () => ImportSource.manual,
    );
  }
}
