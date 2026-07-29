// 4-2. ホーム — 家族のハコニワ一覧と最近の思い出、スキャン導線（実データ）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/add_child_dialog.dart';
import '../widgets/icons.dart';
import '../widgets/media_image.dart';
import '../widgets/placeholder_box.dart';
import '../widgets/tap_scale.dart';
import 'scan_screen.dart';
import 'space_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

    final recent = [...store.items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ColoredBox(
      color: AppColors.cream,
      child: ListView(
        padding: EdgeInsets.fromLTRB(kScreenPadding, top, kScreenPadding, 20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'こんにちは、ゆいさん',
                      style: AppFonts.kaku(12, color: AppColors.textFaint2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ハコニワ',
                      style: AppFonts.maru(27, weight: FontWeight.w900, height: 1.1),
                    ),
                  ],
                ),
              ),
              const PlaceholderBox(
                label: '似顔',
                fontSize: 8,
                width: 42,
                height: 42,
                borderRadius: BorderRadius.all(Radius.circular(21)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '大切なモノを、思い出と一緒に。',
            style: AppFonts.kaku(13, color: AppColors.textFaint, height: 1.5),
          ),
          const SizedBox(height: 20),

          // 家族カード（2列グリッド）
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final child in store.children)
                    SizedBox(
                      width: width,
                      child: _FamilyCard(
                        child: child,
                        count: store.itemsOf(child.id).length,
                        thumbnail: store
                            .itemsOf(child.id)
                            .where((i) => i.thumbnail != null)
                            .map((i) => i.thumbnail)
                            .firstOrNull,
                        onTap: () => Navigator.of(
                          context,
                        ).push(SpaceScreen.route(childId: child.id)),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // あたらしい ハコニワ
          TapScale(
            onTap: () => _addChild(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: AppRadii.card,
                border: Border.all(color: AppColors.border(0.28), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: PlusIcon(size: 20)),
                  ),
                  const SizedBox(width: 13),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('あたらしい ハコニワ', style: AppFonts.maru(14)),
                      const SizedBox(height: 2),
                      Text(
                        '家族のおへや（3D空間）を つくる',
                        style: AppFonts.kaku(11, color: AppColors.textFaint2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (recent.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('さいきん ふえた思い出', style: AppFonts.maru(13)),
            const SizedBox(height: 11),
            Row(
              children: [
                for (final item in recent.take(3)) ...[
                  Expanded(
                    child: _RecentCard(
                      item: item,
                      onTap: () => Navigator.of(
                        context,
                      ).push(SpaceScreen.route(childId: item.childId, selectedId: item.id)),
                    ),
                  ),
                  if (item != recent.take(3).last) const SizedBox(width: 11),
                ],
              ],
            ),
          ],

          if (store.children.isEmpty) ...[
            const SizedBox(height: 22),
            TapScale(
              onTap: () => Navigator.of(context).push(ScanScreen.route()),
              child: Center(
                child: Text(
                  '＋ スキャンして モノをのこす',
                  style: AppFonts.maru(14, color: AppColors.accentDark),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.child,
    required this.count,
    required this.thumbnail,
    required this.onTap,
  });

  final Child child;
  final int count;
  final String? thumbnail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = hexColor(child.tone);
    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.border(0.14), width: 1.5),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnail != null)
                    MediaImage(uri: thumbnail)
                  else
                    Image.asset('assets/room-sample.png', fit: BoxFit.cover),
                  // 子どもごとのテーマカラーで色味を変える
                  ColoredBox(color: tone.withValues(alpha: 0.16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.maru(15),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.14),
                          borderRadius: AppRadii.pill,
                        ),
                        child: Text(
                          '$countコ',
                          style: AppFonts.kaku(11, weight: FontWeight.w600, color: tone),
                        ),
                      ),
                      if (child.age != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${child.age}さい',
                          style: AppFonts.kaku(11, color: AppColors.textFaint2),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.item, required this.onTap});

  final MemoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.button,
          border: Border.all(color: AppColors.border(0.12), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 66,
              child: MediaImage(uri: item.thumbnail, fallbackLabel: item.name),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.kaku(11, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
