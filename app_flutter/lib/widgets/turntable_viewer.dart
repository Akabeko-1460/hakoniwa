// スキャンした多方向フレームを「回して見る」ターンテーブル3Dビュー
// 横ドラッグで撮影方向を切り替える（フォトグラメトリ導入後は glTF ビューアに差し替え）
import 'package:flutter/material.dart';

import '../theme.dart';
import 'media_image.dart';

class TurntableViewer extends StatefulWidget {
  const TurntableViewer({
    super.key,
    required this.frames,
    this.borderRadius = BorderRadius.zero,
    this.showHint = false,
  });

  final List<String> frames;
  final BorderRadius borderRadius;
  final bool showHint;

  @override
  State<TurntableViewer> createState() => _TurntableViewerState();
}

class _TurntableViewerState extends State<TurntableViewer> {
  int _index = 0;
  int _startIndex = 0;
  double _startX = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEFE7D9),
          borderRadius: widget.borderRadius,
        ),
        child: const SizedBox.expand(),
      );
    }

    final count = widget.frames.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) {
        _startIndex = _index;
        _startX = d.localPosition.dx;
      },
      onHorizontalDragUpdate: (d) {
        if (count < 2) return;
        final step = ((_startX - d.localPosition.dx) / 18).round();
        setState(() => _index = ((_startIndex + step) % count + count) % count);
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaImage(uri: widget.frames[_index]),
            if (widget.showHint && count > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textStrong.withValues(alpha: 0.78),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      '⟲ ドラッグで まわせるよ（${_index + 1}/$count）',
                      style: AppFonts.kaku(
                        10,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
