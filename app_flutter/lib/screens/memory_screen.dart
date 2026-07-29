// 4-4. 思い出をのこす — スキャン直後にモノへ情報を付ける（関連情報の付与）
// 名まえ・写真（image_picker）・こえメモ（実録音）・メモ・だれの/いつ
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../features/voice.dart';
import '../models/models.dart';
import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/icons.dart';
import '../widgets/media_image.dart';
import '../widgets/placeholder_box.dart';
import '../widgets/tap_scale.dart';
import '../widgets/turntable_viewer.dart';
import 'space_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
    pageBuilder: (_, _, _) => const MemoryScreen(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _name = TextEditingController();
  final _memo = TextEditingController();
  final _recorder = VoiceRecorder();

  final List<String> _photos = [];
  String? _childId;
  int _year = DateTime.now().year;
  Season _season = Season.fuyu;
  VoiceMemo? _voice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recorder.addListener(_onRecorderChanged);
  }

  void _onRecorderChanged() => setState(() {});

  @override
  void dispose() {
    _recorder.removeListener(_onRecorderChanged);
    _recorder.dispose();
    _name.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 70, limit: 4);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _photos.addAll(picked.map((x) => x.path));
      if (_photos.length > 4) _photos.removeRange(4, _photos.length);
    });
  }

  Future<void> _onMicTap() async {
    if (_recorder.recording) {
      final memo = await _recorder.stop();
      if (memo != null && mounted) setState(() => _voice = memo);
      return;
    }
    if (_voice != null) {
      await context.read<VoicePlayer>().toggle(_voice!.uri);
      return;
    }
    await _recorder.start();
  }

  Future<void> _save(Child child) async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    try {
      final item = await store.addItem(
        NewItemInput(
          childId: child.id,
          name: _name.text.trim().isEmpty ? 'たからもの' : _name.text.trim(),
          year: _year,
          season: _season,
          memo: _memo.text.trim(),
          frames: store.draftFrames,
          photos: _photos,
          voice: _voice,
          tone: kNewItemTone,
        ),
      );
      store.setDraftFrames(const []);
      if (!mounted) return;
      // 保存後は配置モードでハコニワへ
      Navigator.of(
        context,
      ).pushReplacement(SpaceScreen.route(childId: child.id, placeItemId: item.id));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip(Child? child) {
    final store = context.read<AppStore>();
    store.setDraftFrames(const []);
    if (child == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(SpaceScreen.route(childId: child.id));
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now().year;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.textStrong.withValues(alpha: 0.35),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('いつの おもいで？', style: AppFonts.maru(15)),
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 13,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final year = now - i;
                    return _Chip(
                      label: '$year',
                      active: _year == year,
                      horizontal: 15,
                      onTap: () {
                        setState(() => _year = year);
                        setSheetState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final season in Season.values) ...[
                    _Chip(
                      label: season.label,
                      active: _season == season,
                      horizontal: 20,
                      onTap: () {
                        setState(() => _season = season);
                        setSheetState(() {});
                      },
                    ),
                    if (season != Season.values.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              TapScale(
                onTap: () => Navigator.of(sheetContext).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadii.small,
                  ),
                  child: Center(
                    child: Text('これで きめる', style: AppFonts.maru(14, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final insets = screenInsets(context);
    final frames = store.draftFrames;
    final children = store.children;
    final child =
        children.where((c) => c.id == _childId).firstOrNull ??
        (children.isEmpty ? null : children.first);

    final micColor = _recorder.recording ? AppColors.accentRec : AppColors.accent;
    final recLabel = _recorder.recording
        ? '● ${formatDuration(_recorder.seconds)}'
        : _voice != null
        ? formatDuration(_voice!.durationSec)
        : 'タップで録音';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(kScreenPadding, insets.top, kScreenPadding, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TapScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: BackIcon()),
                  ),
                ),
                Text('思い出をのこす', style: AppFonts.maru(16)),
                TapScale(
                  onTap: () => _skip(child),
                  child: Text(
                    'スキップ',
                    style: AppFonts.maru(13, color: AppColors.textFaint4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 6, kScreenPadding, 18),
              children: [
                // プレビュー行: 3Dモデルのサムネ + 名前入力
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(color: AppColors.border(0.14), width: 1.5),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: frames.isEmpty
                            ? const PlaceholderBox(
                                label: '3Dモデル',
                                fontSize: 8,
                                borderRadius: BorderRadius.all(Radius.circular(15)),
                              )
                            : TurntableViewer(
                                frames: frames,
                                borderRadius: const BorderRadius.all(Radius.circular(15)),
                              ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              frames.isEmpty
                                  ? 'スキャンできました！'
                                  : 'スキャンできました！（${frames.length}方向）',
                              style: AppFonts.kaku(10.5, color: AppColors.textFaint2),
                            ),
                            const SizedBox(height: 3),
                            TextField(
                              controller: _name,
                              cursorColor: AppColors.accent,
                              style: AppFonts.maru(17),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'たとえば つみき',
                                hintStyle: AppFonts.maru(17, color: AppColors.textFaint4),
                                contentPadding: const EdgeInsets.only(top: 2, bottom: 5),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.underline,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '名まえを つけてね',
                              style: AppFonts.kaku(10, color: AppColors.textFaint4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (frames.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'うえのサムネイルを 横にドラッグすると まわせるよ',
                      style: AppFonts.kaku(10, color: AppColors.textFaint2),
                    ),
                  ),

                _SectionTitle('写真をそえる'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final photo in _photos)
                      MediaImage(
                        uri: photo,
                        width: 78,
                        height: 78,
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                      ),
                    if (_photos.length < 4)
                      TapScale(
                        onTap: _pickPhotos,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                            border: Border.all(color: AppColors.border(0.28), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const PlusIcon(
                                size: 20,
                                color: AppColors.addTint,
                                strokeWidth: 2.2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ついか',
                                style: AppFonts.kaku(
                                  9,
                                  weight: FontWeight.w600,
                                  color: AppColors.addTint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                _SectionTitle('こえメモ'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.mid,
                    border: Border.all(color: AppColors.border(0.14), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      TapScale(
                        onTap: _onMicTap,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: micColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _voice != null && !_recorder.recording
                                ? const PlayIcon(size: 13)
                                : const MicIcon(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: WaveformBars()),
                      const SizedBox(width: 12),
                      Text(recLabel, style: AppFonts.maru(11, color: AppColors.textFaint)),
                    ],
                  ),
                ),
                if (_voice != null && !_recorder.recording)
                  TapScale(
                    onTap: () => setState(() => _voice = null),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, left: 6),
                      child: Text(
                        'とり直す',
                        style: AppFonts.kaku(
                          11,
                          weight: FontWeight.w600,
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                  ),
                if (_recorder.permissionDenied)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 6),
                    child: Text(
                      'マイクの許可が必要です（端末の設定から変更できます）',
                      style: AppFonts.kaku(10.5, color: AppColors.accentRec),
                    ),
                  ),

                _SectionTitle('おもいで メモ'),
                TextField(
                  controller: _memo,
                  maxLines: null,
                  minLines: 3,
                  cursorColor: AppColors.accent,
                  style: AppFonts.kaku(13, height: 1.7),
                  decoration: InputDecoration(
                    hintText: 'このモノとの 思い出を のこそう',
                    hintStyle: AppFonts.kaku(13, color: AppColors.textFaint4),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.mid,
                      borderSide: BorderSide(color: AppColors.border(0.14), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.mid,
                      borderSide: BorderSide(color: AppColors.border(0.14), width: 1.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadii.mid,
                      borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('だれの？'),
                          for (final c in children)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: TapScale(
                                onTap: () => setState(() => _childId = c.id),
                                child: _FieldBox(
                                  active: child?.id == c.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: hexColor(c.tone),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.maru(13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('いつ？'),
                          TapScale(
                            onTap: _pickWhen,
                            child: _FieldBox(
                              child: Text(
                                '$_year年 ${_season.label}',
                                style: AppFonts.maru(13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // フッター固定ボタン
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0x1A785537), width: 1.5)),
            ),
            padding: EdgeInsets.fromLTRB(
              kScreenPadding,
              12,
              kScreenPadding,
              math.max(30, insets.bottom + 4),
            ),
            child: Opacity(
              opacity: _saving || child == null ? 0.6 : 1,
              child: TapScale(
                onTap: child == null ? null : () => _save(child),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadii.button,
                    boxShadow: AppShadows.button,
                  ),
                  child: Center(
                    child: Text(
                      _saving
                          ? 'しまっています…'
                          : child == null
                          ? 'さきに ハコニワを つくってね'
                          : 'ハコニワに しまう',
                      style: AppFonts.maru(16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 9),
    child: Text(text, style: AppFonts.maru(12.5)),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppFonts.kaku(11, weight: FontWeight.w600, color: AppColors.textFaint2),
    ),
  );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, this.active = false});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: active ? AppColors.accentPale : Colors.white,
      borderRadius: AppRadii.small,
      border: Border.all(
        color: active ? AppColors.accent : AppColors.border(0.14),
        width: 1.5,
      ),
    ),
    child: child,
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.horizontal = 14,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final double horizontal;

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.textStrong : AppColors.chipBg,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        style: AppFonts.maru(13, color: active ? Colors.white : AppColors.textMid2),
      ),
    ),
  );
}
