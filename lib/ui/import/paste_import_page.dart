import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/csv_import_service.dart';
import '../../data/services/pasted_bill_parser.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction_record.dart';
import '../../state/finance_controller.dart';
import '../transactions/transaction_edit_page.dart';
import '../widgets/gradient_button.dart';

class PasteImportPage extends StatefulWidget {
  const PasteImportPage({super.key});

  @override
  State<PasteImportPage> createState() => _PasteImportPageState();
}

class _PasteImportPageState extends State<PasteImportPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.trim().isEmpty) return;
    setState(() => _textController.text = data.text!.trim());
  }

  Future<void> _recognize() async {
    final finance = context.read<FinanceController>();
    final userId = finance.userId;
    if (userId == null) return;

    final result = PastedBillParser.parse(_textController.text);
    if (result == null) {
      _showMessage('没有识别到金额和时间，请确认复制的是微信/支付宝账单文本');
      return;
    }
    if (finance.categories.isEmpty || finance.accounts.isEmpty) {
      _showMessage('请先初始化账户和分类');
      return;
    }

    final category = CsvImportService.matchCategory(
      result.type,
      result.note,
      finance.categories,
    );
    final account = CsvImportService.matchAccount(
      result.source == ImportSource.alipay ? '支付宝' : '微信',
      finance.accounts,
    );

    final record = TransactionRecord(
      id: '',
      userId: userId,
      type: result.type,
      amount: result.amount,
      categoryId: category.id,
      accountId: account.id,
      happenedAt: result.happenedAt,
      note: result.note,
      importSource: result.source,
    );

    _showMessage('识别成功，请确认账单信息');
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
      appBar: AppBar(title: const Text('粘贴识别')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: '账单文本',
              hintText: '在微信/支付宝账单详情页复制文本后粘贴到这里',
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                onPressed: _pasteFromClipboard,
                tooltip: '粘贴剪贴板',
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _isLoading ? '识别中...' : '识别并生成账单',
            icon: Icons.auto_awesome_rounded,
            onPressed: _isLoading ? null : _recognize,
          ),
          const SizedBox(height: 16),
          const Text(
            '支持微信支付和支付宝的账单复制文本，自动提取金额、商户、时间和收支方向。',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
