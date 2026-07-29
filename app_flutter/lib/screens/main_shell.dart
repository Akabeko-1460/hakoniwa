// 下部タブを持つ3画面（ホーム / おもいで / せってい）の入れもの。
// scan・memory・space はフルスクリーンなので、ここではなく push で開く。
import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'memories_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavTab _tab = NavTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: const [HomeScreen(), MemoriesScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: BottomNav(
        active: _tab,
        onSelect: (t) => setState(() => _tab = t),
        onScan: () => Navigator.of(context).push(ScanScreen.route()),
      ),
    );
  }
}
