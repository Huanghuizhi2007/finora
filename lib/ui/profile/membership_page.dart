import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会员中心')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFBBF24),
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Finora Pro',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '解锁高级统计、无限账户和 AI 财务分析',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Text(
                      '¥12',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/ 月',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '可随时取消',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CompareTable(),
          const SizedBox(height: 24),
          GradientButton(
            label: '升级到 Pro',
            icon: Icons.workspace_premium_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('订阅支付将在应用商店审核通过后启用'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      ('基础记账', '支持', '支持'),
      ('账户数量', '5 个', '无限'),
      ('高级统计', '基础', '完整图表'),
      ('云备份', '1 台设备', '多设备同步'),
      ('AI 财务分析', '基础洞察', '深度分析'),
      ('数据导出', '不支持', 'CSV 导出'),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(child: Text('功能')),
              SizedBox(
                width: 86,
                child: Text(
                  '基础版',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 86,
                child: Text(
                  'Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    child: Text(
                      row.$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.income,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
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
