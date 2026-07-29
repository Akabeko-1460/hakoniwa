// 下部タブナビ（design_handoff_hakoniwa/README.md セクション5）
// 5項目: ホーム / さがす(→memories) / のこす(→scan・中央丸) / おもいで(→memories) / せってい
import 'package:flutter/material.dart';

import '../theme.dart';
import 'icons.dart';
import 'tap_scale.dart';

enum NavTab { home, memories, settings }

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.active,
    required this.onSelect,
    required this.onScan,
  });

  final NavTab active;
  final ValueChanged<NavTab> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final bottom = screenInsets(context).bottom;
    const on = AppColors.accent;
    const off = AppColors.textFaint3;

    Widget item(String label, Widget icon, bool isOn, VoidCallback onTap) => Expanded(
      child: TapScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(
              label,
              style: AppFonts.kaku(
                9.5,
                weight: isOn ? FontWeight.w700 : FontWeight.w600,
                color: isOn ? on : off,
              ),
            ),
          ],
        ),
      ),
    );

    final homeOn = active == NavTab.home;
    final memoriesOn = active == NavTab.memories;
    final settingsOn = active == NavTab.settings;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1A785537), width: 1.5)),
      ),
      padding: EdgeInsets.only(top: 9, bottom: bottom, left: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          item(
            'ホーム',
            HomeIcon(color: homeOn ? on : off, filled: homeOn),
            homeOn,
            () => onSelect(NavTab.home),
          ),
          item(
            'さがす',
            SearchIcon(color: memoriesOn ? on : off),
            memoriesOn,
            () => onSelect(NavTab.memories),
          ),
          // 中央「のこす」は径50pxのオレンジ円で -14px 上に飛び出す
          Expanded(
            child: TapScale(
              onTap: onScan,
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [AppShadows.of(0.40, 14, 6, AppColors.accent)],
                      ),
                      child: const Center(child: PlusIcon(size: 24, strokeWidth: 2.6)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'のこす',
                      style: AppFonts.kaku(
                        9.5,
                        weight: FontWeight.w700,
                        color: homeOn ? on : off,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          item(
            'おもいで',
            HeartIcon(color: memoriesOn ? on : off, filled: memoriesOn),
            memoriesOn,
            () => onSelect(NavTab.memories),
          ),
          item(
            'せってい',
            GearIcon(color: settingsOn ? on : off),
            settingsOn,
            () => onSelect(NavTab.settings),
          ),
        ],
      ),
    );
  }
}
