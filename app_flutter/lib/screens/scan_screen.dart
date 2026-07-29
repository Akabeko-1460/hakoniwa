// 4-3. 3Dスキャン — 実カメラでモノを回り込みながら多方向キャプチャ
// 撮影したフレーム列はターンテーブル3D表示に使う（フォトグラメトリは後段差し替え）
import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../theme.dart';
import '../widgets/icons.dart';
import '../widgets/tap_scale.dart';
import 'memory_screen.dart';

/// これだけ撮れば完了できる
const int kMinFrames = 8;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
    pageBuilder: (_, _, _) => const ScanScreen(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _camera;
  bool _initializing = true;
  String? _cameraError;

  final List<String> _frames = [];
  bool _auto = false;
  bool _busy = false;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'カメラが見つかりませんでした';
          _initializing = false;
        });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _initializing = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'カメラを つかえませんでした（${e.runtimeType}）';
        _initializing = false;
      });
    }
  }

  int get _max => context.read<AppStore>().settings.scanTarget;

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy || camera == null || !camera.value.isInitialized) return;
    if (_frames.length >= _max) return;
    _busy = true;
    try {
      final shot = await camera.takePicture();
      if (!mounted) return;
      setState(() {
        if (_frames.length < _max) _frames.add(shot.path);
      });
    } on Object catch (e) {
      debugPrint('capture failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// じどう撮影: まわりを歩きながら一定間隔でキャプチャ
  void _toggleAuto() {
    if (_camera == null) return;
    setState(() => _auto = !_auto);
    _autoTimer?.cancel();
    if (!_auto) return;
    _autoTimer = Timer.periodic(const Duration(milliseconds: 800), (_) async {
      if (_frames.length >= _max) {
        _autoTimer?.cancel();
        if (mounted) setState(() => _auto = false);
        return;
      }
      await _capture();
    });
  }

  void _retake() {
    _autoTimer?.cancel();
    setState(() {
      _auto = false;
      _frames.clear();
    });
  }

  void _finish() {
    if (_frames.length < kMinFrames) return;
    _autoTimer?.cancel();
    setState(() => _auto = false);
    context.read<AppStore>().setDraftFrames(List.of(_frames));
    Navigator.of(context).pushReplacement(MemoryScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    final insets = screenInsets(context);
    final max = context.watch<AppStore>().settings.scanTarget;
    final progress = _frames.length;
    final fraction = math.min(1.0, progress / max);
    final canFinish = progress >= kMinFrames;

    final hint = progress >= max
        ? 'キャプチャ 完了！ 右下の完了へ'
        : fraction > 0.5
        ? 'あと ちょっと！ 反対がわを写して'
        : 'ぐるっと 一周してね';

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
                  child: const _RoundButton(child: BackIcon()),
                ),
                Text('3Dスキャン', style: AppFonts.maru(16)),
                _RoundButton(
                  child: Text('?', style: AppFonts.maru(15, color: AppColors.textMid2)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 6, kScreenPadding, 6),
              children: [
                Text('あたらしい たからもの', textAlign: TextAlign.center, style: AppFonts.maru(15)),
                const SizedBox(height: 3),
                Text(
                  'まわりを ぐるっと写してね',
                  textAlign: TextAlign.center,
                  style: AppFonts.kaku(12, color: AppColors.textFaint2),
                ),
                const SizedBox(height: 16),
                _CameraBox(
                  camera: _camera,
                  initializing: _initializing,
                  error: _cameraError,
                  fraction: fraction,
                  hint: hint,
                  auto: _auto,
                  onToggleAuto: _toggleAuto,
                  onRetryPermission: () {
                    setState(() {
                      _initializing = true;
                      _cameraError = null;
                    });
                    _setupCamera();
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('キャプチャ 進行ど', style: AppFonts.kaku(12, weight: FontWeight.w600)),
                    Text(
                      '$progress / $max 方向',
                      style: AppFonts.maru(13, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: AppRadii.pill,
                  child: SizedBox(
                    height: 9,
                    child: Stack(
                      children: [
                        const ColoredBox(
                          color: AppColors.trackBg,
                          child: SizedBox.expand(),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 300),
                          widthFactor: fraction,
                          alignment: Alignment.centerLeft,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEFA981), AppColors.accent],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (progress > 0 && progress < kMinFrames) ...[
                  const SizedBox(height: 8),
                  Text(
                    'あと ${kMinFrames - progress}枚で 完了できるよ',
                    textAlign: TextAlign.center,
                    style: AppFonts.kaku(11, color: AppColors.textFaint2),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              kScreenPadding,
              16,
              kScreenPadding,
              math.max(30, insets.bottom + 4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SideButton(
                  label: 'やり直す',
                  color: AppColors.textFaint2,
                  background: AppColors.chipBg,
                  onTap: _retake,
                  child: const ReloadIcon(),
                ),
                const SizedBox(width: 26),
                TapScale(
                  onTap: _capture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 4),
                      boxShadow: [AppShadows.of(0.35, 20, 8, AppColors.accent)],
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 26),
                Opacity(
                  opacity: fraction >= 1 ? 1 : (canFinish ? 0.75 : 0.4),
                  child: _SideButton(
                    label: '完了',
                    color: AppColors.green,
                    background: AppColors.greenPale,
                    onTap: _finish,
                    child: const CheckIcon(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: const BoxDecoration(color: AppColors.chipBg, shape: BoxShape.circle),
    child: Center(child: child),
  );
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Center(child: child),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.kaku(10, weight: FontWeight.w600, color: color),
        ),
      ],
    ),
  );
}

/// カメラ映像・四隅ガイド・円形プログレスリング・ヒント
class _CameraBox extends StatelessWidget {
  const _CameraBox({
    required this.camera,
    required this.initializing,
    required this.error,
    required this.fraction,
    required this.hint,
    required this.auto,
    required this.onToggleAuto,
    required this.onRetryPermission,
  });

  final CameraController? camera;
  final bool initializing;
  final String? error;
  final double fraction;
  final String hint;
  final bool auto;
  final VoidCallback onToggleAuto;
  final VoidCallback onRetryPermission;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3129),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        border: Border.all(color: AppColors.border(0.14), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null && camera!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: camera!.value.previewSize?.height ?? 1,
                height: camera!.value.previewSize?.width ?? 1,
                child: CameraPreview(camera!),
              ),
            )
          else
            ColoredBox(
              color: const Color(0xFFEFE7D9),
              child: Center(
                child: initializing
                    ? const CircularProgressIndicator(color: AppColors.accent)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error ?? '3Dスキャンには\nカメラを つかいます',
                            textAlign: TextAlign.center,
                            style: AppFonts.kaku(
                              13,
                              weight: FontWeight.w600,
                              color: AppColors.textFaint,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TapScale(
                            onTap: onRetryPermission,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: AppRadii.small,
                              ),
                              child: Text(
                                'カメラを ゆるす',
                                style: AppFonts.maru(13, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          // 四隅の白いL字ガイド
          const Positioned(top: 14, left: 14, child: _Corner(top: true, left: true)),
          const Positioned(top: 14, right: 14, child: _Corner(top: true, left: false)),
          const Positioned(bottom: 14, left: 14, child: _Corner(top: false, left: true)),
          const Positioned(bottom: 14, right: 14, child: _Corner(top: false, left: false)),

          // 円形プログレスリング
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(painter: _ProgressRingPainter(fraction)),
              ),
            ),
          ),

          // じどう撮影トグル
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Center(
              child: TapScale(
                onTap: onToggleAuto,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  decoration: BoxDecoration(
                    color: auto
                        ? AppColors.accentRec
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: AppRadii.pill,
                  ),
                  child: Text(
                    auto ? '● じどう撮影中' : 'じどう撮影',
                    style: AppFonts.maru(
                      11,
                      color: auto ? Colors.white : AppColors.textMid2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.textStrong.withValues(alpha: 0.82),
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  hint,
                  style: AppFonts.kaku(11, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.white, width: 3);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(8) : Radius.zero,
          topRight: top && !left ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.fraction);

  final double fraction;
  static const _radius = 66.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: _radius);

    // 破線のガイド（6 on / 8 off 相当）
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const circumference = 2 * math.pi * _radius;
    const dash = 6 / circumference * 2 * math.pi;
    const gap = 8 / circumference * 2 * math.pi;
    for (var a = 0.0; a < 2 * math.pi; a += dash + gap) {
      canvas.drawArc(rect, a, dash, false, guide);
    }

    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.fraction != fraction;
}
