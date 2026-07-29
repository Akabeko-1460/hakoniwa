// ハコニワ用の小さなソフトウェア3Dレンダラ。
//
// RN 版は expo-gl + three.js だったが、Flutter では Canvas に直接描く。
// 部屋は軸ぞろえの箱と円柱・球だけでできていて半透明も無いので、
// 面をカメラからの距離順に並べて描く（画家のアルゴリズム）だけで正しく見える。
// 外部プラグインに依存しないぶん、iOS/Android/Web/デスクトップで同じ絵になる。
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 get normalized {
    final l = length;
    return l == 0 ? zero : Vec3(x / l, y / l, z / l);
  }
}

/// 光源（three.js の AmbientLight + DirectionalLight 相当）はシーン内で固定なので、
/// 面の色は組み立て時に一度だけ陰影づけして持っておく。
final Vec3 _lightDir = const Vec3(3.5, 6, 2.5).normalized;
const double _ambient = 0.62;
const double _diffuse = 0.55;

Color _shade(Color base, Vec3 normal) {
  final f = _ambient + _diffuse * math.max(0.0, normal.dot(_lightDir));
  int ch(double v) => (v * 255 * f).clamp(0, 255).round();
  return Color.fromARGB(255, ch(base.r), ch(base.g), ch(base.b));
}

/// 部屋の外殻（床・壁・台座）。中に置くものより必ず先に描く。
const int kLayerShell = 0;

/// 床の上・壁の手前に置かれるもの（家具・ラグ・かざり・ピン）
const int kLayerProps = 1;

/// 陰影づけ済みの多角形（3頂点か4頂点）
class Face {
  Face(this.verts, this.color, {this.layer = kLayerProps});

  final List<Vec3> verts;
  final Color color;

  /// 描く順のおおまかな段。床や壁は一枚板で大きく、重心で並べると
  /// その上に載っているものを塗りつぶしてしまうので、段を分けて先に描く。
  final int layer;

  static Face shaded(List<Vec3> verts, Color base, {int layer = kLayerProps}) {
    final normal = (verts[1] - verts[0]).cross(verts[2] - verts[0]).normalized;
    return Face(verts, _shade(base, normal), layer: layer);
  }

  /// 平行移動と拡大を適用した新しい面（ピンのふわふわ演出に使う）
  Face transformed(Vec3 offset, double scale) => Face(
    [
      for (final v in verts)
        Vec3(v.x * scale + offset.x, v.y * scale + offset.y, v.z * scale + offset.z),
    ],
    color,
    layer: layer,
  );

  Face withLayer(int newLayer) => Face(verts, color, layer: newLayer);
}

/// 面をためていくメッシュ。box/cylinder/sphere/cone を生やせる。
class Mesh {
  final List<Face> faces = [];

  void add(Mesh other) => faces.addAll(other.faces);

  void addFaces(Iterable<Face> f) => faces.addAll(f);

  Mesh translated(Vec3 offset) {
    final out = Mesh();
    for (final f in faces) {
      out.faces.add(Face([for (final v in f.verts) v + offset], f.color, layer: f.layer));
    }
    return out;
  }

  /// すべての面を指定の段に移した新しいメッシュ
  Mesh layered(int layer) {
    final out = Mesh();
    for (final f in faces) {
      out.faces.add(f.withLayer(layer));
    }
    return out;
  }

  /// [top] を false にすると上面を作らない（真上に別のものが載って隠れるとき）。
  void box(
    double w,
    double h,
    double d,
    Color color,
    double x,
    double y,
    double z, {
    bool top = true,
  }) {
    final hx = w / 2, hy = h / 2, hz = d / 2;
    Vec3 v(double sx, double sy, double sz) => Vec3(x + sx * hx, y + sy * hy, z + sz * hz);

    // 反時計回り（外向き）で6面
    faces.addAll([
      Face.shaded([v(-1, -1, 1), v(1, -1, 1), v(1, 1, 1), v(-1, 1, 1)], color), // 前
      Face.shaded([v(1, -1, -1), v(-1, -1, -1), v(-1, 1, -1), v(1, 1, -1)], color), // 後
      Face.shaded([v(1, -1, 1), v(1, -1, -1), v(1, 1, -1), v(1, 1, 1)], color), // 右
      Face.shaded([v(-1, -1, -1), v(-1, -1, 1), v(-1, 1, 1), v(-1, 1, -1)], color), // 左
      if (top)
        Face.shaded([v(-1, 1, 1), v(1, 1, 1), v(1, 1, -1), v(-1, 1, -1)], color), // 上
      Face.shaded([v(-1, -1, -1), v(1, -1, -1), v(1, -1, 1), v(-1, -1, 1)], color), // 下
    ]);
  }

  void cylinder(
    double rTop,
    double rBottom,
    double h,
    int segments,
    Color color,
    Vec3 center, {
    bool caps = true,
  }) {
    final top = center.y + h / 2, bottom = center.y - h / 2;
    Vec3 ring(double r, double y, int i) {
      final a = i / segments * 2 * math.pi;
      return Vec3(center.x + math.cos(a) * r, y, center.z + math.sin(a) * r);
    }

    for (var i = 0; i < segments; i++) {
      final b0 = ring(rBottom, bottom, i), b1 = ring(rBottom, bottom, i + 1);
      final t0 = ring(rTop, top, i), t1 = ring(rTop, top, i + 1);
      faces.add(Face.shaded([b0, b1, t1, t0], color));
    }
    if (!caps) return;
    for (var i = 0; i < segments; i++) {
      faces.add(
        Face.shaded([
          Vec3(center.x, top, center.z),
          ring(rTop, top, i),
          ring(rTop, top, i + 1),
        ], color),
      );
      faces.add(
        Face.shaded([
          Vec3(center.x, bottom, center.z),
          ring(rBottom, bottom, i + 1),
          ring(rBottom, bottom, i),
        ], color),
      );
    }
  }

  void cone(double r, double h, int segments, Color color, Vec3 center) {
    final apex = Vec3(center.x, center.y + h / 2, center.z);
    final bottom = center.y - h / 2;
    Vec3 ring(int i) {
      final a = i / segments * 2 * math.pi;
      return Vec3(center.x + math.cos(a) * r, bottom, center.z + math.sin(a) * r);
    }

    for (var i = 0; i < segments; i++) {
      faces.add(Face.shaded([ring(i), ring(i + 1), apex], color));
      faces.add(
        Face.shaded([Vec3(center.x, bottom, center.z), ring(i + 1), ring(i)], color),
      );
    }
  }

  void sphere(double r, int segments, int rings, Color color, Vec3 center) {
    Vec3 at(int s, int t) {
      final phi = t / rings * math.pi;
      final theta = s / segments * 2 * math.pi;
      return Vec3(
        center.x + r * math.sin(phi) * math.cos(theta),
        center.y + r * math.cos(phi),
        center.z + r * math.sin(phi) * math.sin(theta),
      );
    }

    for (var t = 0; t < rings; t++) {
      for (var s = 0; s < segments; s++) {
        final a = at(s, t), b = at(s + 1, t), c = at(s + 1, t + 1), d = at(s, t + 1);
        if (t == 0) {
          faces.add(Face.shaded([a, c, d], color));
        } else if (t == rings - 1) {
          faces.add(Face.shaded([a, b, c], color));
        } else {
          faces.add(Face.shaded([a, b, c, d], color));
        }
      }
    }
  }
}

/// 注視点まわりを回るカメラ（オービット）
class OrbitCamera {
  OrbitCamera({
    required this.target,
    required this.radius,
    required this.theta,
    required this.phi,
    this.fovDegrees = 42,
  });

  final Vec3 target;
  final double radius;
  double theta; // 水平角
  double phi; // 仰角
  final double fovDegrees;

  Vec3 get position => Vec3(
    target.x + radius * math.cos(phi) * math.sin(theta),
    target.y + radius * math.sin(phi),
    target.z + radius * math.cos(phi) * math.cos(theta),
  );

  /// ワールド → ビューの基底（右手系・-Z が前）
  ({Vec3 right, Vec3 up, Vec3 back, Vec3 eye}) basis() {
    final eye = position;
    final back = (eye - target).normalized; // カメラの後ろ向き = +Z
    final right = const Vec3(0, 1, 0).cross(back).normalized;
    final up = back.cross(right);
    return (right: right, up: up, back: back, eye: eye);
  }
}

/// 1フレーム分の描画。面を奥から手前に並べて三角形として一括で流す。
class SceneRenderer {
  SceneRenderer(this.camera, this.size);

  final OrbitCamera camera;
  final Size size;

  late final _b = camera.basis();
  late final double _tanHalfFov = math.tan(camera.fovDegrees * math.pi / 180 / 2);
  late final double _aspect = size.width / math.max(1, size.height);

  Vec3 _toView(Vec3 w) {
    final d = w - _b.eye;
    return Vec3(d.dot(_b.right), d.dot(_b.up), d.dot(_b.back));
  }

  /// ビュー空間の点を画面座標へ。カメラの前方は viewZ が負。
  Offset _project(Vec3 v) {
    final invZ = 1 / -v.z;
    final ndcX = v.x * invZ / (_tanHalfFov * _aspect);
    final ndcY = v.y * invZ / _tanHalfFov;
    return Offset((ndcX * 0.5 + 0.5) * size.width, (0.5 - ndcY * 0.5) * size.height);
  }

  void paint(Canvas canvas, List<Face> faces) {
    // 視野内かつ手前を向いている面だけを、段と重心の奥行きとともに集める
    final visible = <_Drawable>[];
    for (final face in faces) {
      final view = [for (final v in face.verts) _toView(v)];
      var depth = 0.0;
      var behind = false;
      for (final v in view) {
        if (v.z > -0.05) {
          behind = true;
          break;
        }
        depth += v.z;
      }
      if (behind) continue; // カメラの後ろ（この部屋では起きない）

      final screen = [for (final v in view) _project(v)];
      // 外向きの面（ワールドで反時計回り）は、y が下向きの画面座標に写すと
      // 符号つき面積が負になる。正なら裏を向いているので描かない。
      if (_signedArea(screen) >= 0) continue;

      visible.add(_Drawable(face.layer, depth / view.length, screen, face.color));
    }

    // まず段の順、そのなかは奥（z が小さい＝遠い）から手前へ
    visible.sort((a, b) {
      final byLayer = a.layer.compareTo(b.layer);
      return byLayer != 0 ? byLayer : a.depth.compareTo(b.depth);
    });

    var triangles = 0;
    for (final d in visible) {
      triangles += d.points.length - 2;
    }
    final positions = Float32List(triangles * 6);
    final colors = Int32List(triangles * 3);
    var pi = 0, ci = 0;

    void emit(Offset p, Color c) {
      positions[pi++] = p.dx;
      positions[pi++] = p.dy;
      colors[ci++] = c.toARGB32();
    }

    for (final d in visible) {
      for (var i = 1; i + 1 < d.points.length; i++) {
        emit(d.points[0], d.color);
        emit(d.points[i], d.color);
        emit(d.points[i + 1], d.color);
      }
    }

    if (ci == 0) return;
    final vertices = ui.Vertices.raw(ui.VertexMode.triangles, positions, colors: colors);
    // 頂点色をそのまま出す（paint 側の色は捨てる）
    canvas.drawVertices(vertices, BlendMode.dst, Paint());
    vertices.dispose();
  }

  static double _signedArea(List<Offset> pts) {
    var sum = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum / 2;
  }

  /// ワールド空間の点が画面のどこに写るか。カメラの後ろなら null。
  Offset? projectPoint(Vec3 world) {
    final view = _toView(world);
    return view.z > -0.05 ? null : _project(view);
  }

  /// 画面上の点から伸びるワールド空間のレイ（タップ判定に使う）
  ({Vec3 origin, Vec3 dir}) rayThrough(Offset point) {
    final ndcX = (point.dx / size.width) * 2 - 1;
    final ndcY = 1 - (point.dy / size.height) * 2;
    final dir =
        (_b.right * (ndcX * _tanHalfFov * _aspect) + _b.up * (ndcY * _tanHalfFov) - _b.back)
            .normalized;
    return (origin: _b.eye, dir: dir);
  }
}

/// 並べ替えて描くための、投影ずみの1面
class _Drawable {
  _Drawable(this.layer, this.depth, this.points, this.color);

  final int layer;
  final double depth;
  final List<Offset> points;
  final Color color;
}

/// レイと水平面 y = planeY の交点。手前で交わらなければ null。
Vec3? intersectHorizontalPlane(({Vec3 origin, Vec3 dir}) ray, double planeY) {
  if (ray.dir.y.abs() < 1e-6) return null;
  final t = (planeY - ray.origin.y) / ray.dir.y;
  if (t <= 0) return null;
  return ray.origin + ray.dir * t;
}

/// レイと球の交点までの距離。当たらなければ null。
double? intersectSphere(({Vec3 origin, Vec3 dir}) ray, Vec3 center, double radius) {
  final oc = ray.origin - center;
  final b = oc.dot(ray.dir);
  final c = oc.dot(oc) - radius * radius;
  final disc = b * b - c;
  if (disc < 0) return null;
  final t = -b - math.sqrt(disc);
  return t > 0 ? t : null;
}
