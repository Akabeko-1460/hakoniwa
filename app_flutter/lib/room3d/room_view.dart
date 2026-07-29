// リアルタイム3Dハコニワルーム
// - ドラッグで回転（オービット）
// - ピンをタップで選択 / 配置モードでは床タップで配置
// - 思い出の数に応じて部屋が拡張される
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/models.dart';
import '../theme.dart';
import 'room_builder.dart';
import 'scene3d.dart';

/// 部屋のコーナー（奥・左の壁）が背景になる向き
const double _defaultTheta = math.pi / 4;
const double _defaultPhi = 0.62;
const double _cameraRadius = 5.4;
const Vec3 _cameraTarget = Vec3(0, 0.55, 0);

class RoomItem {
  const RoomItem({required this.id, required this.tone, required this.pos});

  final String id;
  final String tone;
  final RoomPos pos;
}

/// 外から「カメラを戻す」を叩くためのハンドル
class RoomController extends ChangeNotifier {
  void resetCamera() => notifyListeners();
}

class RoomView extends StatefulWidget {
  const RoomView({
    super.key,
    required this.items,
    required this.childTone,
    this.selectedId,
    this.placeMode = false,
    this.popItemId,
    this.controller,
    required this.onSelect,
    required this.onPlace,
  });

  final List<RoomItem> items;
  final String childTone;
  final String? selectedId;

  /// true のあいだは、ピンではなく床のタップを拾う
  final bool placeMode;

  /// 追加直後にポップさせるモノ
  final String? popItemId;
  final RoomController? controller;
  final ValueChanged<String> onSelect;
  final ValueChanged<RoomPos> onPlace;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _theta = _defaultTheta;
  double _phi = _defaultPhi;
  double _elapsed = 0;

  Mesh? _room;
  int _builtPropLevel = -1;
  String _builtTone = '';
  final Map<String, Mesh> _pinMeshes = {};
  final Map<String, double> _pinPhases = {};

  String? _poppingId;
  double _popStart = 0;

  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      setState(() => _elapsed = d.inMicroseconds / 1e6);
    })..start();
    widget.controller?.addListener(_resetCamera);
    _poppingId = widget.popItemId;
  }

  @override
  void didUpdateWidget(RoomView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_resetCamera);
      widget.controller?.addListener(_resetCamera);
    }
    if (widget.popItemId != null && widget.popItemId != old.popItemId) {
      _poppingId = widget.popItemId;
      _popStart = _elapsed;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_resetCamera);
    _ticker.dispose();
    super.dispose();
  }

  void _resetCamera() {
    setState(() {
      _theta = _defaultTheta;
      _phi = _defaultPhi;
    });
  }

  RoomTheme get _theme => RoomTheme.fromTone(widget.childTone);

  Mesh _roomMesh() {
    final level = propLevelFor(widget.items.length);
    if (_room == null || level != _builtPropLevel || widget.childTone != _builtTone) {
      _room = buildRoom(_theme, level);
      _builtPropLevel = level;
      _builtTone = widget.childTone;
    }
    return _room!;
  }

  Mesh _pinMesh(RoomItem item) => _pinMeshes[item.tone] ??= buildPin(hexColor(item.tone));

  /// ピンの現在の中心（ふわふわ上下）と大きさ
  ({Vec3 offset, double scale}) _pinTransform(RoomItem item) {
    final phase = _pinPhases[item.id] ??=
        math.Random(item.id.hashCode).nextDouble() * math.pi * 2;
    final y = 0.03 + math.sin(_elapsed * 2 + phase) * 0.03;

    var scale = widget.selectedId == item.id ? 1.35 : 1.0;
    if (_poppingId == item.id) {
      final e = (_elapsed - _popStart) / 0.5;
      if (e < 1) {
        scale *= e < 0.6 ? (e / 0.6) * 1.15 : 1.15 - 0.15 * ((e - 0.6) / 0.4);
      } else {
        _poppingId = null;
      }
    }
    return (offset: Vec3(item.pos.x * kPinReach, y, item.pos.z * kPinReach), scale: scale);
  }

  OrbitCamera _camera() =>
      OrbitCamera(target: _cameraTarget, radius: _cameraRadius, theta: _theta, phi: _phi);

  List<Face> _faces() {
    final faces = <Face>[..._roomMesh().faces];
    for (final item in widget.items) {
      final t = _pinTransform(item);
      for (final f in _pinMesh(item).faces) {
        faces.add(f.transformed(t.offset, t.scale));
      }
    }
    return faces;
  }

  void _handleTap(Offset local) {
    if (_size.isEmpty) return;
    final renderer = SceneRenderer(_camera(), _size);
    final ray = renderer.rayThrough(local);

    if (widget.placeMode) {
      final hit = intersectHorizontalPlane(ray, 0);
      if (hit == null) return;
      final x = (hit.x / kPinReach).clamp(-0.95, 0.95);
      final z = (hit.z / kPinReach).clamp(-0.95, 0.95);
      // 床の外をタップしたときは置かない
      if (hit.x.abs() > kFloorHalf || hit.z.abs() > kFloorHalf) return;
      widget.onPlace(RoomPos(x.toDouble(), z.toDouble()));
      return;
    }

    String? nearestId;
    var nearest = double.infinity;
    for (final item in widget.items) {
      final t = _pinTransform(item);
      final center = Vec3(t.offset.x, t.offset.y + kPinHeadY * t.scale, t.offset.z);
      // 指でつまみやすいよう、当たり判定は見た目より少し大きめ
      final hit = intersectSphere(ray, center, kPinHeadRadius * t.scale * 1.6);
      if (hit != null && hit < nearest) {
        nearest = hit;
        nearestId = item.id;
      }
    }
    if (nearestId != null) widget.onSelect(nearestId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d.localPosition),
          onPanUpdate: (d) {
            setState(() {
              _theta -= d.delta.dx * 0.009;
              _phi = (_phi + d.delta.dy * 0.006).clamp(0.28, 1.15);
            });
          },
          child: CustomPaint(
            size: _size,
            painter: _RoomPainter(
              faces: _faces(),
              camera: _camera(),
              background: _theme.background,
            ),
          ),
        );
      },
    );
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({required this.faces, required this.camera, required this.background});

  final List<Face> faces;
  final OrbitCamera camera;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    SceneRenderer(camera, size).paint(canvas, faces);
  }

  @override
  bool shouldRepaint(_RoomPainter old) => true;
}
