import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/update_service.dart';
import '../accounts/accounts_page.dart';
import '../calendar/calendar_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../stats/stats_page.dart';
import '../transactions/transaction_edit_page.dart';
import '../widgets/update_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_updateChecked) return;
    _updateChecked = true;
    final update = await UpdateService.checkLatest();
    if (update == null ||
        !UpdateService.isNewer(update.version, AppConfig.appVersion)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final dismissed =
        prefs.getBool('update_dismissed_${update.version}') ?? false;
    if (dismissed || !mounted) return;
    final download = await showUpdateDialog(context, update);
    await prefs.setBool('update_dismissed_${update.version}', true);
    if (download == true) {
      await openUpdate(context, update);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const <Widget>[
            HomePage(),
            CalendarPage(),
            StatsPage(),
            AccountsPage(),
            ProfilePage(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TransactionEditPage(),
            ),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          HapticFeedback.selectionClick();
          setState(() => _index = value);
        },
        height: 68,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '日历',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            selectedIcon: Icon(Icons.insert_chart_rounded),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: '账户',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
