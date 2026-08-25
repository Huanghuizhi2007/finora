import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../widgets/glass_card.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _dailyReminder = true;
  bool _budgetAlert = true;
  bool _monthlySummary = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('notify_daily') ?? true;
      _budgetAlert = prefs.getBool('notify_budget') ?? true;
      _monthlySummary = prefs.getBool('notify_monthly') ?? false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          GlassCard(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('每日记账提醒'),
                  subtitle: const Text('提醒你记录当天的收支'),
                  value: _dailyReminder,
                  onChanged: (value) {
                    setState(() => _dailyReminder = value);
                    _save('notify_daily', value);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.track_changes_rounded,
                    color: AppColors.primaryPurple,
                  ),
                  title: const Text('预算超支提醒'),
                  subtitle: const Text('预算使用达 80% 和 100% 时提醒'),
                  value: _budgetAlert,
                  onChanged: (value) {
                    setState(() => _budgetAlert = value);
                    _save('notify_budget', value);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.summarize_rounded,
                    color: AppColors.cyan,
                  ),
                  title: const Text('月度财务总结'),
                  subtitle: const Text('每月 1 日发送上月消费总结'),
                  value: _monthlySummary,
                  onChanged: (value) {
                    setState(() => _monthlySummary = value);
                    _save('notify_monthly', value);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.income,
                  ),
                  title: const Text('每日提醒时间'),
                  trailing: Text(
                    '${_reminderTime.hour.toString().padLeft(2, '0')}:'
                    '${_reminderTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '正式环境将使用系统推送通知发送提醒，应用商店审核通过后自动启用。',
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
