// .tap:active { transform:scale(.96); filter:brightness(.97) } 相当の押下フィードバック
import 'package:flutter/material.dart';

class TapScale extends StatefulWidget {
  const TapScale({super.key, this.onTap, required this.child, this.enabled = true});

  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: active ? widget.onTap : null,
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: active ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}
