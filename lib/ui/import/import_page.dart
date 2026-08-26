import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/services/csv_import_service.dart';
import '../../domain/entities/enums.dart';
import '../../state/finance_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'ocr_import_page.dart';
import 'paste_import_page.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  ParsedImport? _result;
  String _fileName = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      if (file.path == null) {
        throw Exception('无法读取该文件');
      }
      final content = await File(file.path!).readAsString();
      final finance = context.read<FinanceController>();
      final result = CsvImportService.parse(
        content: content,
        userId: finance.userId ?? '',
        accounts: finance.accounts,
        categories: finance.categories,
      );
      setState(() {
        _result = result;
        _fileName = file.name;
      });
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _import() async {
    final result = _result;
    if (result == null || result.records.isEmpty) return;
    final finance = context.read<FinanceController>();
    final count = await finance.importTransactions(result.records);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功导入 $count 笔账单')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('账单导入')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.file_upload_outlined,
                        color: AppColors.primaryBlue, size: 24),
                    SizedBox(width: 10),
                    Text(
                      '微信 / 支付宝 CSV 账单',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '支持微信支付和支付宝导出的 CSV 文件，自动识别交易时间、金额、收支方向和支付方式。',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else
                  GradientButton(
                    label: result == null ? '选择 CSV 文件' : '重新选择文件',
                    icon: Icons.folder_open_rounded,
                    onPressed: _pickFile,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.content_paste_rounded,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '复制粘贴识别',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '在微信/支付宝账单详情页复制文本，粘贴后自动识别金额、商户和时间。',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: '去粘贴识别',
                  icon: Icons.auto_awesome_rounded,
                  colors: const <Color>[Color(0xFF0891B2), Color(0xFF7C3AED)],
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PasteImportPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.image_search_rounded,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      '截图导入',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '选择微信/支付宝支付截图，自动带入账单并附上图片，补充金额后保存。',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: '选择截图',
                  icon: Icons.image_outlined,
                  colors: const <Color>[Color(0xFF111827), Color(0xFF111827)],
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OcrImportPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 13,
              ),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.income,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '识别为 ${result.source.label}，共 ${result.records.length} 笔可导入，跳过 ${result.skipped} 行',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (result.records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '没有可导入的收支记录',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    for (final record in result.records.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                record.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            Text(
                              '${record.type == TransactionType.income ? '+' : '-'}${MoneyFormat.format(record.amount)}',
                              style: TextStyle(
                                color: record.type == TransactionType.income
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  if (result.records.length > 8)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: '导入 ${result.records.length} 笔账单',
              icon: Icons.import_export_rounded,
              onPressed: result.records.isEmpty ? null : _import,
            ),
          ],
        ],
      ),
    );
  }
}
