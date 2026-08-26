import 'dart:io';

import 'package:excel/excel.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/finance_account.dart';
import 'csv_import_service.dart';

class ExcelImportService {
  ExcelImportService._();

  static Future<ParsedImport> parse({
    required String filePath,
    required String userId,
    required List<FinanceAccount> accounts,
    required List<Category> categories,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final workbook = Excel.decodeBytes(bytes);
    for (final sheetName in workbook.tables.keys) {
      final sheet = workbook.tables[sheetName]!;
      final rows = <List<dynamic>>[];
      for (final row in sheet.rows) {
        rows.add(
          row.map((cell) => cell?.value?.toString() ?? '').toList(),
        );
      }
      try {
        return CsvImportService.parseRows(
          rows: rows,
          userId: userId,
          accounts: accounts,
          categories: categories,
        );
      } catch (_) {
        // 跳过没有账单表头的空工作表，继续查找其他 sheet。
      }
    }
    throw Exception('未找到可识别的微信/支付宝账单工作表');
  }
}
