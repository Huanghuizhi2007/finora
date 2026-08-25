import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../widgets/glass_card.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理员后台')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          Row(
            children: <Widget>[
              _AdminStat(
                label: '注册用户',
                value: '1,284',
                color: AppColors.primaryBlue,
                icon: Icons.people_alt_rounded,
              ),
              const SizedBox(width: 12),
              _AdminStat(
                label: '本月新增',
                value: '89',
                color: AppColors.income,
                icon: Icons.person_add_alt_1_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _AdminStat(
                label: '活跃用户',
                value: '356',
                color: AppColors.primaryPurple,
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(width: 12),
              _AdminStat(
                label: '系统状态',
                value: '正常',
                color: AppColors.cyan,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('用户管理', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            radius: 20,
            child: Column(
              children: <Widget>[
                for (final user in _demoUsers)
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.bluePurpleGradient,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: user.active
                            ? AppColors.income.withOpacity(0.14)
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user.active ? '活跃' : '沉默',
                        style: TextStyle(
                          color: user.active
                              ? AppColors.income
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
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

class _AdminStat extends StatelessWidget {
  const _AdminStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoUser {
  const _DemoUser(this.name, this.email, this.active);

  final String name;
  final String email;
  final bool active;
}

const List<_DemoUser> _demoUsers = <_DemoUser>[
  _DemoUser('林夏', 'linxia@example.com', true),
  _DemoUser('陈一', 'chenyi@example.com', true),
  _DemoUser('周舟', 'zhouzhou@example.com', false),
  _DemoUser('吴桐', 'wutong@example.com', true),
  _DemoUser('赵珂', 'zhaoke@example.com', false),
];
