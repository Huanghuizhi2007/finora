import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/services/csv_import_service.dart';
import '../../data/services/ocr_import_service.dart';
import '../../data/services/pasted_bill_parser.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import '../../state/finance_controller.dart';
import '../transactions/transaction_edit_page.dart';
import '../widgets/gradient_button.dart';

class OcrImportPage extends StatefulWidget {
  const OcrImportPage({super.key});

  @override
  State<OcrImportPage> createState() => _OcrImportPageState();
}

class _OcrImportPageState extends State<OcrImportPage> {
  String? _imagePath;
  String? _recognizedText;
  PastedBillResult? _parsed;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
    setState(() {
      _imagePath = null;
      _recognizedText = null;
      _parsed = null;
      _error = null;
      _isLoading = true;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final text = await OcrImportService.recognize(file.path);
      if (!mounted) return;
      setState(() {
        _imagePath = file.path;
        _recognizedText = text;
        _parsed = PastedBillParser.parse(text);
        _error = _parsed == null ? '没有识别到金额或时间，可以手动补记' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '识别失败：${error.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generate({required bool manual}) async {
    final finance = context.read<FinanceController>();
    final userId = finance.userId;
    final imagePath = _imagePath;
    if (userId == null || imagePath == null) return;
    if (finance.categories.isEmpty || finance.accounts.isEmpty) {
      _showMessage('请先初始化账户和分类');
      return;
    }

    TransactionRecord record;
    if (manual) {
      final fallbackCategory = finance.categories
          .where((c) => c.type == TransactionType.expense)
          .first;
      record = TransactionRecord(
        id: '',
        userId: userId,
        type: TransactionType.expense,
        amount: 0,
        categoryId: fallbackCategory.id,
        accountId: finance.accounts.first.id,
        happenedAt: DateTime.now(),
        note: '',
        imageUrl: imagePath,
      );
    } else {
      final result = _parsed!;
      final category = CsvImportService.matchCategory(
        result.type,
        result.note,
        finance.categories,
      );
      final account = CsvImportService.matchAccount(
        result.source == ImportSource.alipay ? '支付宝' : '微信',
        finance.accounts,
      );
      record = TransactionRecord(
        id: '',
        userId: userId,
        type: result.type,
        amount: result.amount,
        categoryId: category.id,
        accountId: account.id,
        happenedAt: result.happenedAt,
        note: result.note,
        imageUrl: imagePath,
        importSource: result.source,
      );
    }

    HapticFeedback.selectionClick();
    _showMessage(manual ? '请补充金额后保存' : '识别成功，请确认账单信息');
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditPage(transaction: record),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('截图识别')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          if (_imagePath == null)
            _UploadArea(onTap: _isLoading ? null : _pickImage)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_imagePath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          if (_imagePath != null)
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('重新选择截图'),
            ),
          if (_isLoading) ...<Widget>[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '正在识别截图...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
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
          if (_parsed != null) ...<Widget>[
            const SizedBox(height: 16),
            _ResultCard(parsed: _parsed!),
          ],
          if (_recognizedText != null && _recognizedText!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              '识别文本',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _recognizedText!,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
          if (_imagePath != null && !_isLoading) ...<Widget>[
            const SizedBox(height: 20),
            GradientButton(
              label: _parsed == null ? '手动补记' : '生成账单',
              icon: _parsed == null
                  ? Icons.edit_note_rounded
                  : Icons.check_rounded,
              onPressed: () => _generate(manual: _parsed == null),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.textMuted,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              '选择微信/支付宝账单截图',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.parsed});

  final PastedBillResult parsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                parsed.type == TransactionType.income ? '收入' : '支出',
                style: TextStyle(
                  color: parsed.type == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MoneyFormat.format(parsed.amount),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                parsed.source.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            parsed.note.isEmpty ? parsed.merchant : parsed.note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppDateUtils.fullDate(parsed.happenedAt),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
