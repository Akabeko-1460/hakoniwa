// 4-7. せってい — プロフィール・家族・アプリ設定（実データ）
// バックアップのトグルは FastAPI バックエンドへの接続そのもの。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/add_child_dialog.dart';
import '../widgets/icons.dart';
import '../widgets/placeholder_box.dart';
import '../widgets/tap_scale.dart';
import 'backup_screen.dart';
import 'space_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addChild(BuildContext context) async {
    final input = await showAddChildDialog(context);
    if (input == null || !context.mounted) return;
    final child = context.read<AppStore>().addChild(input.name, input.age, input.tone);
    if (!context.mounted) return;
    Navigator.of(context).push(SpaceScreen.route(childId: child.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final top = screenInsets(context).top;
    final settings = store.settings;
    final connected = store.credentials != null;

    return ColoredBox(
      color: AppColors.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(kScreenPadding, top, kScreenPadding, 8),
            child: Text('せってい', style: AppFonts.maru(24, weight: FontWeight.w900)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 8, kScreenPadding, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(color: AppColors.border(0.14), width: 1.5),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: Row(
                    children: [
                      const PlaceholderBox(
                        label: '似顔',
                        fontSize: 8,
                        width: 54,
                        height: 54,
                        borderRadius: BorderRadius.all(Radius.circular(27)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ゆい', style: AppFonts.maru(16)),
                            const SizedBox(height: 2),
                            Text(
                              'yui@example.com',
                              style: AppFonts.kaku(11, color: AppColors.textFaint2),
                            ),
                          ],
                        ),
                      ),
                      const ChevronRightIcon(),
                    ],
                  ),
                ),

                const _SectionLabel('かぞく'),
                _Card(
                  children: [
                    for (final child in store.children)
                      _Row(
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: hexColor(child.tone),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              child.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.maru(14),
                            ),
                          ),
                          Text(
                            child.age != null
                                ? '${child.age}さい'
                                : '${store.itemsOf(child.id).length}コ',
                            style: AppFonts.kaku(11, color: AppColors.textFaint2),
                          ),
                        ],
                      ),
                    _Row(
                      onTap: () => _addChild(context),
                      divider: false,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPale,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: PlusIcon(
                              size: 13,
                              color: AppColors.accent,
                              strokeWidth: 2.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text('子どもを ついか', style: AppFonts.maru(13, color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),

                const _SectionLabel('アプリ'),
                _Card(
                  children: [
                    _Row(
                      onTap: () => store.updateSettings(
                        scanTarget: settings.scanTarget == 20 ? 12 : 20,
                      ),
                      children: [
                        Expanded(
                          child: Text(
                            'スキャンの画質',
                            style: AppFonts.kaku(13, weight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          settings.scanTarget == 20 ? 'たかい（20方向） ›' : 'ふつう（12方向） ›',
                          style: AppFonts.kaku(
                            12,
                            weight: FontWeight.w600,
                            color: AppColors.textFaint2,
                          ),
                        ),
                      ],
                    ),
                    _Row(
                      onTap: () => Navigator.of(context).push(BackupScreen.route()),
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'バックアップ',
                                style: AppFonts.kaku(13, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                connected && settings.backup
                                    ? _syncLabel(store)
                                    : 'サーバーに つないでいません',
                                style: AppFonts.kaku(10.5, color: AppColors.textFaint2),
                              ),
                            ],
                          ),
                        ),
                        _Toggle(on: connected && settings.backup),
                      ],
                    ),
                    _Row(
                      divider: false,
                      onTap: () => store.updateSettings(notify: !settings.notify),
                      children: [
                        Expanded(
                          child: Text(
                            'おもいで通知',
                            style: AppFonts.kaku(13, weight: FontWeight.w600),
                          ),
                        ),
                        _Toggle(on: settings.notify),
                      ],
                    ),
                  ],
                ),

                TapScale(
                  onTap: () => store.setOnboarded(false),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'オンボーディングを もう一度みる',
                        style: AppFonts.maru(13, color: AppColors.accentDark),
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

  static String _syncLabel(AppStore store) => switch (store.syncState) {
    SyncState.syncing => 'サーバーと 同期中…',
    SyncState.failed => store.syncError ?? '同期できませんでした',
    _ => 'サーバーに 保管しています',
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 22, 6, 9),
    child: Text(text, style: AppFonts.maru(12, color: AppColors.textFaint2)),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: AppRadii.mid,
      border: Border.all(color: AppColors.border(0.12), width: 1.5),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.children, this.onTap, this.divider = true});

  final List<Widget> children;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            )
          : null,
      child: Row(children: children),
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 42,
    height: 25,
    decoration: BoxDecoration(
      color: on ? AppColors.green : AppColors.toggleOff,
      borderRadius: AppRadii.pill,
    ),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 21,
            height: 21,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ],
    ),
  );
}
