// 4-6. おもいで（タイムライン）— 実データを時系列で一覧・検索・絞り込み
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/icons.dart';
import '../widgets/tap_scale.dart';
import 'space_screen.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _query = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final top = screenInsets(context).top;
    final timeline = store.timeline(childFilter: _filter, query: _query.text);

    return ColoredBox(
      color: AppColors.cream,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(kScreenPadding, top, kScreenPadding, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('おもいで', style: AppFonts.maru(24, weight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  'ぜんぶで ${store.items.length}コ ・ 新しいものから むかしへ',
                  style: AppFonts.kaku(11, color: AppColors.textFaint2),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.small,
                    border: Border.all(color: AppColors.border(0.14), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const SearchIcon(size: 17, color: AppColors.textFaint4),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          controller: _query,
                          onChanged: (_) => setState(() {}),
                          cursorColor: AppColors.accent,
                          style: AppFonts.kaku(12.5, color: AppColors.textStrong),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '思い出をさがす',
                            hintStyle: AppFonts.kaku(12.5, color: AppColors.textFaint4),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'すべて',
                        active: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      for (final child in store.children) ...[
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: child.name,
                          active: _filter == child.id,
                          onTap: () => setState(() => _filter = child.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: timeline.isEmpty
                ? Center(
                    child: Text(
                      'みつかりませんでした',
                      style: AppFonts.kaku(12, color: AppColors.textFaint2),
                    ),
                  )
                : Stack(
                    children: [
                      // 左の縦線
                      if (timeline.length > 1)
                        const Positioned(
                          left: kScreenPadding + 13,
                          top: 16,
                          bottom: 20,
                          child: SizedBox(
                            width: 2,
                            child: ColoredBox(color: AppColors.underline),
                          ),
                        ),
                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          kScreenPadding,
                          16,
                          kScreenPadding,
                          20,
                        ),
                        itemCount: timeline.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final item = timeline[i];
                          return TapScale(
                            onTap: () => Navigator.of(context).push(
                              SpaceScreen.route(childId: item.childId, selectedId: item.id),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: hexColor(item.tone),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.cream,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.year}',
                                        style: AppFonts.maru(
                                          10,
                                          color: AppColors.textFaint2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: AppRadii.mid,
                                      border: Border.all(
                                        color: AppColors.border(0.12),
                                        width: 1.5,
                                      ),
                                      boxShadow: [AppShadows.of(0.07, 14, 6)],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppFonts.maru(14),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 1,
                                              ),
                                              decoration: const BoxDecoration(
                                                color: AppColors.chipBg,
                                                borderRadius: AppRadii.pill,
                                              ),
                                              child: Text(
                                                store.childById(item.childId)?.name ?? '？',
                                                style: AppFonts.kaku(
                                                  9.5,
                                                  weight: FontWeight.w600,
                                                  color: AppColors.textMid2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.memo.isEmpty
                                              ? '${item.year}年${item.season.label}の おもいで'
                                              : item.memo,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.kaku(
                                            11,
                                            color: AppColors.textFaint,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.textStrong : AppColors.chipBg,
        borderRadius: AppRadii.pill,
      ),
      child: Center(
        child: Text(
          label,
          style: AppFonts.maru(11.5, color: active ? Colors.white : AppColors.textMid2),
        ),
      ),
    ),
  );
}
