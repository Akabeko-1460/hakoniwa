// プロトタイプのインラインSVGを忠実に移植したアイコン群
import 'package:flutter/material.dart';

import '../theme.dart';

/// 24x24 のパスを描くアイコンの土台
class _IconPaint extends StatelessWidget {
  const _IconPaint({required this.size, required this.painter});

  final double size;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: painter),
  );
}

abstract class _Base extends CustomPainter {
  const _Base(this.color);

  final Color color;

  /// もとの SVG の viewBox の一辺。実サイズへ拡大するのに使う。
  double get viewBox => 24;

  Paint stroke(double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get fill => Paint()..color = color;

  void scaleTo(Canvas canvas, Size size) =>
      canvas.scale(size.width / viewBox, size.height / viewBox);

  @override
  bool shouldRepaint(_Base old) => old.color != color;
}

class HomeIcon extends StatelessWidget {
  const HomeIcon({
    super.key,
    this.size = 23,
    this.color = AppColors.textFaint3,
    this.filled = false,
  });
  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _HomePainter(color, filled));
}

class _HomePainter extends _Base {
  const _HomePainter(super.color, this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    final path = Path()
      ..moveTo(4, 11)
      ..lineTo(12, 5)
      ..lineTo(20, 11)
      ..lineTo(20, 19)
      ..arcToPoint(const Offset(19, 20), radius: const Radius.circular(1))
      ..lineTo(15, 20)
      ..lineTo(15, 14)
      ..lineTo(9, 14)
      ..lineTo(9, 20)
      ..lineTo(5, 20)
      ..arcToPoint(const Offset(4, 19), radius: const Radius.circular(1))
      ..close();
    canvas.drawPath(path, filled ? fill : stroke(2));
  }
}

class SearchIcon extends StatelessWidget {
  const SearchIcon({super.key, this.size = 23, this.color = AppColors.textFaint3});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _SearchPainter(color));
}

class _SearchPainter extends _Base {
  const _SearchPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawCircle(const Offset(11, 11), 6, stroke(2));
    canvas.drawLine(const Offset(15.5, 15.5), const Offset(20, 20), stroke(2));
  }
}

class PlusIcon extends StatelessWidget {
  const PlusIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
    this.strokeWidth = 2.4,
  });
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _PlusPainter(color, strokeWidth));
}

class _PlusPainter extends _Base {
  const _PlusPainter(super.color, this.width);

  @override
  double get viewBox => 20;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawLine(const Offset(10, 3), const Offset(10, 17), stroke(width));
    canvas.drawLine(const Offset(3, 10), const Offset(17, 10), stroke(width));
  }
}

class HeartIcon extends StatelessWidget {
  const HeartIcon({
    super.key,
    this.size = 23,
    this.color = AppColors.textFaint3,
    this.filled = false,
  });
  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _HeartPainter(color, filled));
}

class _HeartPainter extends _Base {
  const _HeartPainter(super.color, this.filled);
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    final path = Path()
      ..moveTo(12, 20)
      ..cubicTo(12, 20, 5, 15.5, 5, 10.5)
      ..arcToPoint(const Offset(12, 7), radius: const Radius.circular(3.5))
      ..arcToPoint(const Offset(19, 10.5), radius: const Radius.circular(3.5))
      ..cubicTo(19, 15.5, 12, 20, 12, 20)
      ..close();
    if (filled) canvas.drawPath(path, Paint()..color = AppColors.accentPale);
    canvas.drawPath(path, stroke(2));
  }
}

class GearIcon extends StatelessWidget {
  const GearIcon({super.key, this.size = 23, this.color = AppColors.textFaint3});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _GearPainter(color));
}

class _GearPainter extends _Base {
  const _GearPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawCircle(const Offset(12, 12), 3.2, stroke(2));
    const spokes = [
      [12.0, 4.0, 12.0, 6.0],
      [12.0, 18.0, 12.0, 20.0],
      [4.0, 12.0, 6.0, 12.0],
      [18.0, 12.0, 20.0, 12.0],
      [6.0, 6.0, 7.5, 7.5],
      [16.5, 16.5, 18.0, 18.0],
      [18.0, 6.0, 16.5, 7.5],
      [7.5, 16.5, 6.0, 18.0],
    ];
    for (final s in spokes) {
      canvas.drawLine(Offset(s[0], s[1]), Offset(s[2], s[3]), stroke(2));
    }
  }
}

class BackIcon extends StatelessWidget {
  const BackIcon({super.key, this.size = 17, this.color = AppColors.textMid2});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _ChevronPainter(color, back: true));
}

class ChevronRightIcon extends StatelessWidget {
  const ChevronRightIcon({super.key, this.size = 16, this.color = AppColors.textFaint4});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _ChevronPainter(color, back: false));
}

class _ChevronPainter extends _Base {
  const _ChevronPainter(super.color, {required this.back});

  @override
  double get viewBox => 20;
  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    final path = back
        ? (Path()
            ..moveTo(13, 4)
            ..lineTo(7, 10)
            ..lineTo(13, 16))
        : (Path()
            ..moveTo(7, 4)
            ..lineTo(13, 10)
            ..lineTo(7, 16));
    canvas.drawPath(path, stroke(2.2));
  }
}

class CheckIcon extends StatelessWidget {
  const CheckIcon({
    super.key,
    this.size = 21,
    this.color = AppColors.green,
    this.strokeWidth = 2.6,
  });
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _CheckPainter(color, strokeWidth));
}

class _CheckPainter extends _Base {
  const _CheckPainter(super.color, this.width);
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(10, 17)
        ..lineTo(20, 6),
      stroke(width),
    );
  }
}

class ReloadIcon extends StatelessWidget {
  const ReloadIcon({
    super.key,
    this.size = 20,
    this.color = AppColors.textMid2,
    this.strokeWidth = 2.2,
  });
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _ReloadPainter(color, strokeWidth));
}

class _ReloadPainter extends _Base {
  const _ReloadPainter(super.color, this.width);
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(12, 12), radius: 8),
      0.6,
      5.1,
      false,
      stroke(width),
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, 5)
        ..lineTo(4, 9)
        ..lineTo(8, 9),
      stroke(width),
    );
  }
}

class ShareIcon extends StatelessWidget {
  const ShareIcon({super.key, this.size = 17, this.color = AppColors.textMid2});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _SharePainter(color));
}

class _SharePainter extends _Base {
  const _SharePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawLine(const Offset(8, 11), const Offset(16, 7), stroke(1.6));
    canvas.drawLine(const Offset(8, 13), const Offset(16, 17), stroke(1.6));
    canvas.drawCircle(const Offset(6, 12), 2.2, fill);
    canvas.drawCircle(const Offset(18, 6), 2.2, fill);
    canvas.drawCircle(const Offset(18, 18), 2.2, fill);
  }
}

class MicIcon extends StatelessWidget {
  const MicIcon({super.key, this.size = 16, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _IconPaint(size: size, painter: _MicPainter(color));
}

class _MicPainter extends _Base {
  const _MicPainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(9, 3, 6, 12), const Radius.circular(3)),
      fill,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(12, 11), radius: 6),
      0,
      3.1416,
      false,
      stroke(2),
    );
    canvas.drawLine(const Offset(12, 17), const Offset(12, 20), stroke(2));
  }
}

class PlayIcon extends StatelessWidget {
  const PlayIcon({super.key, this.size = 9, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _PlayPainter(color));
}

class _PlayPainter extends _Base {
  const _PlayPainter(super.color);

  @override
  double get viewBox => 12;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 10, size.height / 12);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(10, 6)
        ..lineTo(0, 12)
        ..close(),
      fill,
    );
  }
}

class CloseIcon extends StatelessWidget {
  const CloseIcon({super.key, this.size = 12, this.color = const Color(0xFF9A8368)});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _IconPaint(size: size, painter: _ClosePainter(color));
}

class _ClosePainter extends _Base {
  const _ClosePainter(super.color);

  @override
  double get viewBox => 14;

  @override
  void paint(Canvas canvas, Size size) {
    scaleTo(canvas, size);
    canvas.drawLine(const Offset(2, 2), const Offset(12, 12), stroke(2));
    canvas.drawLine(const Offset(12, 2), const Offset(2, 12), stroke(2));
  }
}
