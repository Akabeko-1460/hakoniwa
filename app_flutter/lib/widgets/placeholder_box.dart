// .ph — 縞模様プレースホルダ
// repeating-linear-gradient(135deg,#E9DECC 0 9px,#F2EADA 9px 18px) 相当
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class PlaceholderBox extends StatelessWidget {
  const PlaceholderBox({
    super.key,
    this.label,
    this.fontSize = 10,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  final String? label;
  final double fontSize;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _StripePainter(),
        child: SizedBox(
          width: width,
          height: height,
          child: label == null
              ? null
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      label!,
                      textAlign: TextAlign.center,
                      style: AppFonts.kaku(
                        fontSize,
                        weight: FontWeight.w600,
                        color: AppColors.phText,
                      ).copyWith(letterSpacing: 0.3),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.phStripeB);

    final paint = Paint()
      ..color = AppColors.phStripeA
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // 135度の縞（左下がり）
    final span = size.width + size.height;
    for (var d = -size.height; d < span; d += 18) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}

/// こえメモの波形（memory 画面）
class WaveformBars extends StatelessWidget {
  const WaveformBars({super.key, this.height = 26});

  final double height;

  static const _groupA = [
    [0, 9, 8],
    [7, 5, 16],
    [14, 2, 22],
    [21, 7, 12],
    [28, 4, 18],
    [35, 10, 6],
    [42, 6, 14],
    [49, 3, 20],
    [56, 8, 10],
    [63, 5, 16],
  ];
  static const _groupB = [
    [70, 7, 12],
    [77, 4, 18],
    [84, 9, 8],
    [91, 6, 14],
    [98, 2, 22],
    [105, 8, 10],
    [112, 5, 16],
    [119, 10, 6],
    [126, 6, 14],
    [133, 4, 18],
    [140, 9, 8],
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _WavePainter()),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 150x26 を実サイズへ引きのばす
    final sx = size.width / 150, sy = size.height / 26;
    void bars(List<List<int>> group, Color color) {
      final paint = Paint()..color = color;
      for (final b in group) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(b[0] * sx, b[1] * sy, math.max(1.5, 3 * sx), b[2] * sy),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }

    bars(WaveformBars._groupA, AppColors.waveA);
    bars(WaveformBars._groupB, AppColors.waveB);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}
