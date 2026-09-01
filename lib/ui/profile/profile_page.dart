import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/update_service.dart';
import '../../state/finance_controller.dart';
import '../../state/session_controller.dart';
import '../admin/admin_page.dart';
import '../ai/ai_assistant_page.dart';
import '../budget/budget_page.dart';
import '../import/import_page.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_avatar.dart';
import '../widgets/update_dialog.dart';
import 'edit_profile_page.dart';
import 'membership_page.dart';
import 'notification_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _checkUpdate(BuildContext context) async {
    final update = await UpdateService.checkLatest();
    if (!context.mounted) return;
    if (update == null ||
        !UpdateService.isNewer(update.version, AppConfig.appVersion)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前已是最新版本')),
      );
      return;
    }
    final download = await showUpdateDialog(context, update);
    if (download == true) {
      await openUpdate(context, update);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final session = context.read<SessionController>();
    final error = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '确认新密码'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (passwordController.text != confirmController.text) {
                Navigator.of(context).pop('两次输入的密码不一致');
              } else {
                Navigator.of(context).pop(passwordController.text);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (error is String && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    if (error != null) {
      final result = await session.changePassword(error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? '密码已更新')),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账户？'),
        content: const Text(
          '删除后你的账单、账户和预算数据都会被永久清除，且无法恢复。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final session = context.read<SessionController>();
      final finance = context.read<FinanceController>();
      final error = await session.deleteAccount();
      await finance.setUserId(null);
      if (context.mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final finance = context.read<FinanceController>();
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/finora_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final buffer = StringBuffer('date,type,amount,category,account,note\n');
    for (final transaction in finance.transactions) {
      final category = finance.categoryName(transaction.categoryId);
      final account = finance.accountById(transaction.accountId)?.name ?? '';
      buffer.writeln(
        '${transaction.happenedAt.toIso8601String()},'
        '${transaction.type.label},'
        '${transaction.amount.toStringAsFixed(2)},'
        '"$category","$account","${transaction.note}"',
      );
    }
    await file.writeAsString(buffer.toString());
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出完成'),
        content: Text(
          '账单已导出到：\n${file.path}',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final session = context.read<SessionController>();
      final finance = context.read<FinanceController>();
      await session.signOut();
      await finance.setUserId(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final finance = context.watch<FinanceController>();
    final user = session.user;
    final nickname = user?.nickname ?? '用户';
    final email = user?.email ?? '未绑定邮箱';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: finance.refresh,
        color: AppColors.primaryBlue,
        backgroundColor: AppColors.card,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('我的', style: Theme.of(context).textTheme.titleLarge),
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
                    '基础版',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              nickname: nickname,
              email: email,
              avatarUrl: user?.avatarUrl,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _MenuGroup(
              items: <_MenuItem>[
                _MenuItem(
                  icon: Icons.edit_note_rounded,
                  label: '编辑资料',
                  color: AppColors.primaryBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfilePage(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.track_changes_rounded,
                  label: '预算管理',
                  color: AppColors.primaryPurple,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BudgetPage(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.file_upload_outlined,
                  label: '账单导入',
                  color: AppColors.cyan,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ImportPage(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI 财务助手',
                  color: const Color(0xFFA78BFA),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AiAssistantPage(),
                    ),
                  ),
                ),
              ],
            ),
            _MenuGroup(
              items: <_MenuItem>[
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: '通知设置',
                  color: AppColors.income,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationSettingsPage(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.workspace_premium_rounded,
                  label: '会员中心',
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MembershipPage(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.admin_panel_settings_rounded,
                  label: '管理员后台',
                  color: AppColors.primaryBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminPage(),
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: '修改密码',
                  color: AppColors.textMuted,
                  onTap: () => _changePassword(context),
                ),
                _MenuItem(
                  icon: Icons.file_download_outlined,
                  label: '数据导出',
                  color: AppColors.textMuted,
                  onTap: () => _exportData(context),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: '关于 Finora',
                  color: AppColors.textMuted,
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Finora',
                    applicationVersion: '0.1.0',
                    applicationIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryBlue,
                      size: 40,
                    ),
                    children: const <Widget>[
                      SizedBox(height: 12),
                      Text('简洁易用的个人财务管理应用。'),
                    ],
                  ),
                ),
                _MenuItem(
                  icon: Icons.system_update_alt_rounded,
                  label: '检查更新',
                  color: AppColors.primaryBlue,
                  onTap: () => _checkUpdate(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('退出登录'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _deleteAccount(context),
                child: const Text(
                  '删除账户',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nickname,
    required this.email,
    required this.avatarUrl,
    required this.onTap,
  });

  final String nickname;
  final String email;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          UserAvatar(
            nickname: nickname,
            avatarUrl: avatarUrl,
            size: 56,
            fontSize: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nickname,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const Divider(indent: 56),
            ListTile(
              leading: Icon(items[i].icon, color: items[i].color, size: 22),
              title: Text(
                items[i].label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}
