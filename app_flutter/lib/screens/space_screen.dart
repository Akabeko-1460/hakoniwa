// 4-5. ハコニワ空間（★中心画面）— リアルタイム3Dルーム
// ドラッグで回転 / ピンをタップで情報シート / 配置モードで床タップ配置
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/voice.dart';
import '../models/models.dart';
import '../room3d/room_view.dart';
import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/icons.dart';
import '../widgets/media_image.dart';
import '../widgets/tap_scale.dart';
import '../widgets/turntable_viewer.dart';
import 'scan_screen.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({
    super.key,
    required this.childId,
    this.initialSelectedId,
    this.placeItemId,
  });

  final String childId;
  final String? initialSelectedId;

  /// 保存直後: このモノの置き場所を選ぶ配置モードで開く
  final String? placeItemId;

  static Route<void> route({
    required String childId,
    String? selectedId,
    String? placeItemId,
  }) => PageRouteBuilder(
    pageBuilder: (_, _, _) => SpaceScreen(
      childId: childId,
      initialSelectedId: selectedId,
      placeItemId: placeItemId,
    ),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  final _room = RoomController();
  String? _selectedId;
  String? _placing;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    _placing = widget.placeItemId;
  }

  @override
  void dispose() {
    _room.dispose();
    super.dispose();
  }

  void _place(RoomPos pos) {
    final placing = _placing;
    if (placing == null) return;
    context.read<AppStore>().placeItem(placing, pos);
    setState(() {
      _selectedId = placing;
      _placing = null;
    });
  }

  /// おまかせ配置: ほかのピンから離れた場所をさがす
  void _autoPlace(List<MemoryItem> placed) {
    if (_placing == null) return;
    final random = math.Random();
    var best = const RoomPos(0.1, 0.3);
    var bestDistance = -1.0;
    for (var i = 0; i < 24; i++) {
      final candidate = RoomPos(
        random.nextDouble() * 1.6 - 0.8,
        random.nextDouble() * 1.4 - 0.6,
      );
      var nearest = 2.0;
      for (final item in placed) {
        final d = math.sqrt(
          math.pow(candidate.x - item.pos!.x, 2) + math.pow(candidate.z - item.pos!.z, 2),
        );
        if (d < nearest) nearest = d;
      }
      if (nearest > bestDistance) {
        bestDistance = nearest;
        best = candidate;
      }
    }
    _place(best);
  }

  void _openViewer(MemoryItem item) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xEB1E1610),
      builder: (dialogContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.name, style: AppFonts.maru(17, color: Colors.white)),
            const SizedBox(height: 14),
            Flexible(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: TurntableViewer(
                  frames: item.frames,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  showHint: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            TapScale(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadii.pill,
                ),
                child: Text('とじる', style: AppFonts.maru(13, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final insets = screenInsets(context);
    final child = store.childById(widget.childId);
    if (child == null) {
      return const Scaffold(backgroundColor: AppColors.spaceBg, body: SizedBox());
    }

    final items = store.itemsOf(widget.childId);
    final placed = items.where((it) => it.pos != null).toList();
    final selected = items.where((it) => it.id == _selectedId).firstOrNull;
    final placingItem = store.itemById(_placing ?? '');

    final justAdded =
        store.lastAddedId != null &&
        items.any((it) => it.id == store.lastAddedId) &&
        _placing == null;

    return Scaffold(
      backgroundColor: AppColors.spaceBg,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FractionallySizedBox(
              widthFactor: 1,
              child: SizedBox(
                height: 400,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.spaceGradTop, AppColors.spaceBg],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(kScreenPadding, insets.top, kScreenPadding, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TapScale(
                      onTap: () => Navigator.of(context).pop(),
                      child: const _GlassButton(child: BackIcon()),
                    ),
                    Column(
                      children: [
                        Text(
                          '${child.name}の ハコニワ',
                          style: AppFonts.maru(17, weight: FontWeight.w900),
                        ),
                        Text(
                          '${items.length}コの思い出',
                          style: AppFonts.kaku(10.5, color: AppColors.textFaint2),
                        ),
                      ],
                    ),
                    const _GlassButton(child: ShareIcon()),
                  ],
                ),
              ),

              if (_placing != null && placingItem != null)
                _Band(
                  background: AppColors.accentPale,
                  border: const Color(0xFFF2CDB6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '「${placingItem.name}」を おく場所を タップしてね',
                          style: AppFonts.maru(12, color: AppColors.accentDark),
                        ),
                      ),
                      TapScale(
                        onTap: () => _autoPlace(placed),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadii.pill,
                          ),
                          child: Text(
                            'おまかせ',
                            style: AppFonts.maru(11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (justAdded)
                _Band(
                  background: AppColors.greenPale,
                  border: AppColors.greenBorder,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CheckIcon(size: 12, color: Colors.white, strokeWidth: 3),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'ハコニワに「${store.itemById(store.lastAddedId!)?.name ?? ''}」をおきました',
                          style: AppFonts.maru(12, color: AppColors.greenDark),
                        ),
                      ),
                    ],
                  ),
                ),

              // 部屋（木枠フレームの中の3Dルーム）
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(24)),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment(0.1, 1),
                          colors: [AppColors.woodLight, AppColors.woodDark],
                        ),
                        boxShadow: AppShadows.frame,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                            child: SizedBox(
                              height: 330,
                              width: double.infinity,
                              child: RoomView(
                                key: ValueKey(widget.childId),
                                controller: _room,
                                items: [
                                  for (final item in placed)
                                    RoomItem(id: item.id, tone: item.tone, pos: item.pos!),
                                ],
                                childTone: child.tone,
                                selectedId: _selectedId,
                                placeMode: _placing != null,
                                popItemId: store.lastAddedId,
                                onSelect: (id) => setState(() => _selectedId = id),
                                onPlace: _place,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 9,
                            left: 11,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textStrong.withValues(alpha: 0.82),
                                  borderRadius: AppRadii.pill,
                                ),
                                child: Text(
                                  '${items.length}コの思い出',
                                  style: AppFonts.maru(11, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 9,
                            right: 11,
                            child: Column(
                              children: [
                                TapScale(
                                  onTap: _room.resetCamera,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: const Center(
                                      child: ReloadIcon(size: 19, strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TapScale(
                                  onTap: () =>
                                      Navigator.of(context).push(ScanScreen.route()),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      boxShadow: [
                                        AppShadows.of(0.4, 12, 5, AppColors.accent),
                                      ],
                                    ),
                                    child: const Center(child: PlusIcon(size: 19)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 12, kScreenPadding, 2),
                child: Text(
                  _placing != null ? 'お部屋の ゆかを タップしてね' : 'ドラッグでまわす ・ モノをタップすると 思い出がひらきます',
                  textAlign: TextAlign.center,
                  style: AppFonts.kaku(
                    11,
                    weight: FontWeight.w600,
                    color: AppColors.textFaint2,
                  ),
                ),
              ),

              if (selected != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 6, 14, math.max(24, insets.bottom)),
                  child: _InfoSheet(
                    item: selected,
                    onClose: () => setState(() => _selectedId = null),
                    onOpenViewer: () => _openViewer(selected),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    kScreenPadding,
                    6,
                    kScreenPadding,
                    math.max(30, insets.bottom + 4),
                  ),
                  child: TapScale(
                    onTap: () => Navigator.of(context).push(ScanScreen.route()),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.button,
                        border: Border.all(color: AppColors.border(0.16), width: 1.5),
                        boxShadow: AppShadows.cardSoft,
                      ),
                      child: Center(
                        child: Text(
                          '＋ スキャンして モノをふやす',
                          style: AppFonts.maru(14, color: AppColors.accentDark),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.75),
      shape: BoxShape.circle,
    ),
    child: Center(child: child),
  );
}

class _Band extends StatelessWidget {
  const _Band({required this.background, required this.border, required this.child});

  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppRadii.small,
      border: Border.all(color: border, width: 1.5),
    ),
    child: child,
  );
}

/// ピンをタップしたときに下から出る情報シート
class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.item, required this.onClose, required this.onOpenViewer});

  final MemoryItem item;
  final VoidCallback onClose;
  final VoidCallback onOpenViewer;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<VoicePlayer>();
    final photoCount = item.photos.length + item.frames.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: AppColors.border(0.10), width: 1.5),
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.knob,
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TapScale(
                        onTap: item.frames.length > 1 ? onOpenViewer : null,
                        child: SizedBox(
                          width: 82,
                          height: 82,
                          child: Stack(
                            children: [
                              MediaImage(
                                uri: item.thumbnail,
                                width: 82,
                                height: 82,
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                fallbackLabel: '${item.name}\nの写真',
                              ),
                              if (item.frames.length > 1)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.textStrong.withValues(alpha: 0.82),
                                      borderRadius: AppRadii.pill,
                                    ),
                                    child: Text(
                                      '3D',
                                      style: AppFonts.maru(9, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
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
                                    style: AppFonts.maru(16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentPale,
                                    borderRadius: AppRadii.pill,
                                  ),
                                  child: Text(
                                    '${item.year}年 ${item.season.label}',
                                    style: AppFonts.kaku(
                                      10,
                                      weight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.memo.isEmpty ? 'まだ メモがありません' : item.memo,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.kaku(
                                11.5,
                                color: AppColors.textMid2,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                if (item.voice != null) ...[
                                  TapScale(
                                    onTap: () => player.toggle(item.voice!.uri),
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        right: 12,
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentPale,
                                        borderRadius: AppRadii.pill,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: AppColors.accent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(child: PlayIcon()),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            player.playingUri == item.voice!.uri
                                                ? '再生中…'
                                                : 'こえメモ ${formatDuration(item.voice!.durationSec)}',
                                            style: AppFonts.maru(
                                              11,
                                              color: AppColors.accentDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  '写真 $photoCountまい',
                                  style: AppFonts.kaku(
                                    11,
                                    weight: FontWeight.w600,
                                    color: AppColors.textFaint3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: TapScale(
                  onTap: onClose,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.spaceBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: CloseIcon()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
