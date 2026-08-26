import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/finance_account.dart';
import '../../domain/entities/transaction_record.dart';

class ParsedImport {
  const ParsedImport({
    required this.source,
    required this.records,
    required this.skipped,
  });

  final ImportSource source;
  final List<TransactionRecord> records;
  final int skipped;
}

class CsvImportService {
  CsvImportService._();

  static ParsedImport parse({
    required String content,
    required String userId,
    required List<FinanceAccount> accounts,
    required List<Category> categories,
  }) {
    final normalized = content.replaceFirst('\ufeff', '');
    final rows = CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);
    if (rows.isEmpty) {
      throw Exception('文件内容为空');
    }

    var headerIndex = -1;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final joined = row.join('|');
      if (joined.contains('交易时间') && joined.contains('收/支')) {
        headerIndex = i;
        break;
      }
    }
    if (headerIndex < 0) {
      throw Exception('无法识别微信或支付宝账单格式');
    }

    final headers = rows[headerIndex]
        .map((cell) => cell.toString().trim())
        .toList();
    int column(String keyword) {
      for (var i = 0; i < headers.length; i++) {
        if (headers[i].contains(keyword)) return i;
      }
      return -1;
    }

    final timeIndex = column('交易时间');
    final directionIndex = column('收/支');
    final amountIndex = column('金额');
    final merchantIndex = column('交易对方');
    final productIndex = column('商品');
    final paymentIndex = column('支付方式');
    final orderIndex = column('交易单号') == -1
        ? column('交易订单号')
        : column('交易单号');
    final isWechat = content.contains('微信支付');
    final source = isWechat ? ImportSource.wechat : ImportSource.alipay;

    final records = <TransactionRecord>[];
    var skipped = 0;

    for (final row in rows.skip(headerIndex + 1)) {
      if (row.length <= amountIndex || row.length <= directionIndex) {
        continue;
      }
      String cell(int index) {
        if (index < 0 || index >= row.length) return '';
        return row[index].toString().trim();
      }

      final direction = cell(directionIndex);
      if (direction != '支出' && direction != '收入') {
        skipped++;
        continue;
      }
      final amount = _parseAmount(cell(amountIndex));
      if (amount == null || amount <= 0) {
        skipped++;
        continue;
      }
      final happenedAt = DateTime.tryParse(cell(timeIndex));
      if (happenedAt == null) {
        skipped++;
        continue;
      }

      final type = direction == '收入'
          ? TransactionType.income
          : TransactionType.expense;
      final category = matchCategory(type, cell(productIndex), categories);
      final account = matchAccount(cell(paymentIndex), accounts);
      final product = cell(productIndex);
      final merchant = cell(merchantIndex);
      final note = product.isNotEmpty
          ? product
          : merchant.isNotEmpty
              ? merchant
              : '账单导入';
      final order = cell(orderIndex);

      records.add(
        TransactionRecord(
          id: const Uuid().v4(),
          userId: userId,
          type: type,
          amount: amount,
          categoryId: category.id,
          accountId: account.id,
          happenedAt: happenedAt,
          note: note,
          importSource: source,
          externalId: order.isEmpty ? null : order,
          createdAt: DateTime.now(),
        ),
      );
    }

    return ParsedImport(
      source: source,
      records: records,
      skipped: skipped,
    );
  }

  static double? _parseAmount(String raw) {
    final cleaned = raw
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('+', '');
    return double.tryParse(cleaned);
  }

  static Category matchCategory(
    TransactionType type,
    String product,
    List<Category> categories,
  ) {
    final pool = categories.where((c) => c.type == type).toList();
    if (pool.isEmpty) {
      throw Exception('缺少默认分类，请先初始化分类数据');
    }
    const keywordMap = <String, String>{
      '餐饮': '餐|饭|早|午|晚|外卖|咖啡|奶茶|火锅|烧烤',
      '购物': '购|超市|淘宝|京东|商城|拼多多|商场|百货',
      '交通': '地铁|公交|打车|滴滴|加油|高铁|火车|机票|停车|单车',
      '娱乐': '电影|KTV|游戏|演出|乐园|会员|视频',
      '住房': '房租|租金|房贷|物业|装修|家具',
      '水电': '电费|水费|燃气|供暖|话费|流量|宽带',
      '学习': '课程|培训|图书|书店|学费|考试',
      '医疗': '医院|药|诊所|体检|挂号',
      '旅行': '酒店|旅行|景区|门票|民宿',
      '工资': '工资|薪水|薪资|发放',
      '奖金': '奖金|年终|绩效|分红',
      '投资': '理财|基金|股票|收益|利息|余额宝',
      '红包': '红包|转账|收款',
      '兼职': '兼职|副业|稿费|劳务',
    };

    for (final entry in keywordMap.entries) {
      if (RegExp(entry.value).hasMatch(product)) {
        for (final category in pool) {
          if (category.name == entry.key) return category;
        }
      }
    }
    final fallback =
        pool.where((c) => c.name == '其他').toList();
    return fallback.isNotEmpty ? fallback.first : pool.first;
  }

  static FinanceAccount matchAccount(
    String payment,
    List<FinanceAccount> accounts,
  ) {
    if (accounts.isEmpty) {
      throw Exception('请先创建至少一个账户');
    }
    if (payment.contains('微信')) {
      for (final account in accounts) {
        if (account.type == AccountType.wechat) return account;
      }
    }
    if (payment.contains('支付宝')) {
      for (final account in accounts) {
        if (account.type == AccountType.alipay) return account;
      }
    }
    return accounts.first;
  }
}
