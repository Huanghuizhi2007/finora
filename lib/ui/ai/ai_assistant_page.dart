import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/analytics_engine.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/entities/enums.dart';
import '../../state/finance_controller.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = <_Message>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMessage(
        _Message(
          '你好，我是 Finora 财务助手。我可以帮你分析本月消费、找出超支项并给出节省建议。',
          isUser: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(_Message message) {
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    final content = text.trim();
    if (content.isEmpty) return;
    _inputController.clear();
    _addMessage(_Message(content, isUser: true));
    final reply = _buildReply(content, context.read<FinanceController>());
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _addMessage(_Message(reply, isUser: false));
    });
  }

  String _buildReply(String input, FinanceController finance) {
    final now = DateTime.now();
    final current = AnalyticsEngine.monthly(finance.transactions, now);
    final previous = AnalyticsEngine.monthly(
      finance.transactions,
      DateTime(now.year, now.month - 1, 1),
    );
    final slices = AnalyticsEngine.categoryBreakdown(
      finance.transactions,
      now,
      TransactionType.expense,
      finance.categories,
    );
    final change = AnalyticsEngine.changePercent(current, previous);
    final top = slices.isEmpty ? null : slices.first;

    if (input.contains('总结')) {
      return '本月收入 ${MoneyFormat.format(current.income)}，支出 ${MoneyFormat.format(current.expense)}，结余 ${MoneyFormat.format(current.savings)}。'
          '${top != null ? '支出最多的是${top.label}，占 ${top.percent.toStringAsFixed(1)}%。' : ''}'
          '${change >= 0 ? '总支出较上月增加 ${change.toStringAsFixed(1)}%。' : '总支出较上月下降 ${change.abs().toStringAsFixed(1)}%。'}';
    }
    if (input.contains('建议') || input.contains('节省')) {
      if (top == null) return '这个月还没有支出记录，先记几笔再来分析吧。';
      final parts = <String>[
        '你的最大支出分类是${top.label}（${MoneyFormat.format(top.amount)}）。',
        '建议为${top.label}设置月度预算，并控制在 ${(top.amount * 0.9).toStringAsFixed(0)} 元以内。',
        '也可以尝试每周复盘一次账单，减少重复性小额消费。',
      ];
      return parts.join('\n');
    }
    if (input.contains('餐饮') || input.contains('交通') || input.contains('购物')) {
      final matched = slices.where((s) => input.contains(s.label)).toList();
      if (matched.isNotEmpty) {
        final slice = matched.first;
        return '本月${slice.label}支出 ${MoneyFormat.format(slice.amount)}，占总支出 ${slice.percent.toStringAsFixed(1)}%。'
            '${slice.percent > 30 ? '这个占比偏高，可以考虑设置预算来控制。' : '目前占比处于合理范围。'}';
      }
    }
    return '我基于你的账本看到：本月共支出 ${MoneyFormat.format(current.expense)}，收入 ${MoneyFormat.format(current.income)}。'
        '${top != null ? '最大的支出分类是${top.label}。' : ''}'
        '试试问我“总结本月消费”或“给出节省建议”。';
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI 财务助手')),
      body: Column(
        children: <Widget>[
          _InsightHeader(finance: finance),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <String>[
                  '总结本月消费',
                  '餐饮支出怎么样',
                  '给出节省建议',
                ].map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _send(suggestion),
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.divider),
                    labelStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
            ),
          _InputBar(
            controller: _inputController,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _InsightHeader extends StatelessWidget {
  const _InsightHeader({required this.finance});

  final FinanceController finance;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary = AnalyticsEngine.monthly(finance.transactions, now);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBlue,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '本月概览',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '支出 ${MoneyFormat.compact(summary.expense)} · 结余 ${MoneyFormat.compact(summary.savings)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  const _Message(this.text, {required this.isUser});

  final String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : AppColors.textPrimary,
            fontSize: 14,
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: const InputDecoration(
                  hintText: '问点什么...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSend(controller.text),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
