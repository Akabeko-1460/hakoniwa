// ハコニワ3Dルームの生成（手続き的に組み立てる）
// 子どものテーマカラーから部屋の配色を導出し、思い出の数に応じて家具が増える
// （サービス概要書の「ハコニワ空間の生成」「空間の拡張機能」に対応）
import 'package:flutter/material.dart';

import '../theme.dart';
import 'scene3d.dart';

/// 床の半径（正規化座標 -1..1 をこの範囲へ写像する）
const double kFloorHalf = 1.7;

/// ピンは壁ぎわを避けて置く
const double kPinReach = kFloorHalf - 0.25;

class RoomTheme {
  const RoomTheme({
    required this.wall,
    required this.wallShade,
    required this.floor,
    required this.rug,
    required this.accent,
    required this.background,
  });

  final Color wall;
  final Color wallShade;
  final Color floor;
  final Color rug;
  final Color accent;
  final Color background;

  factory RoomTheme.fromTone(String tone) {
    final accent = hexColor(tone);
    final wall = Color.lerp(accent, const Color(0xFFFFF6E8), 0.82)!;
    return RoomTheme(
      wall: wall,
      wallShade: _scale(wall, 0.92),
      floor: const Color(0xFFD8A96E),
      rug: Color.lerp(accent, Colors.white, 0.35)!,
      accent: accent,
      background: const Color(0xFFF6EDDD),
    );
  }

  static Color _scale(Color c, double f) =>
      Color.from(alpha: 1, red: c.r * f, green: c.g * f, blue: c.b * f);
}

/// 思い出の数に応じた家具の段階（空間の拡張機能）
int propLevelFor(int itemCount) {
  if (itemCount >= 12) return 3;
  if (itemCount >= 8) return 2;
  if (itemCount >= 5) return 1;
  return 0;
}

/// 部屋そのものを組み立てる。propLevel は 0=基本 / 1=たな / 2=植木 / 3=かざり棚。
Mesh buildRoom(RoomTheme theme, int propLevel) {
  const h = kFloorHalf;

  // --- 外殻（床・台座・壁）---
  // 一枚板が大きいので、中に置くものより必ず先に描く段に入れる。
  // 床の上面が y = 0 で、ここが配置レイキャストの平面になる。
  // 台座は床の真下にぴったり置き、隠れる上面は作らない。
  const wallH = 1.9;
  final shell = Mesh()
    ..box(h * 2, 0.22, h * 2, const Color(0xFFB0824E), 0, -0.23, 0, top: false)
    ..box(h * 2, 0.12, h * 2, theme.floor, 0, -0.06, 0)
    ..box(h * 2, wallH, 0.12, theme.wall, 0, wallH / 2, -h - 0.06)
    ..box(0.12, wallH, h * 2, theme.wallShade, -h - 0.06, wallH / 2, 0);

  // --- 部屋に置かれるもの ---
  final mesh = Mesh()..addFaces(shell.layered(kLayerShell).faces);

  // 幅木
  mesh.box(h * 2, 0.14, 0.05, Colors.white, 0, 0.07, -h + 0.03);
  mesh.box(0.05, 0.14, h * 2, Colors.white, -h + 0.03, 0.07, 0);

  // 窓（奥の壁・あかり）
  mesh.box(1.0, 0.85, 0.03, Colors.white, 0.45, 1.1, -h + 0.005);
  mesh.box(0.9, 0.75, 0.05, const Color(0xFFFFF6D9), 0.45, 1.1, -h + 0.02);
  mesh.box(0.04, 0.75, 0.06, Colors.white, 0.45, 1.1, -h + 0.03);
  mesh.box(0.9, 0.04, 0.06, Colors.white, 0.45, 1.1, -h + 0.03);

  // ラグ（まるい）
  mesh.cylinder(0.62, 0.62, 0.03, 28, theme.rug, const Vec3(0.35, 0.015, 0.45));

  // ベッド（左の壁ぎわ）
  final bed = Mesh()
    ..box(0.8, 0.22, 1.3, const Color(0xFFB0824E), 0, 0.11, 0)
    ..box(0.74, 0.14, 1.24, Color.lerp(theme.accent, Colors.white, 0.55)!, 0, 0.3, 0)
    ..box(0.6, 0.1, 0.3, Colors.white, 0, 0.4, -0.42)
    ..box(0.8, 0.34, 0.06, const Color(0xFF9A7040), 0, 0.28, -0.68);
  mesh.add(bed.translated(const Vec3(-h + 0.55, 0, -h + 0.8)));

  // サイドテーブル + ランプ
  final table = Mesh()
    ..box(0.34, 0.3, 0.34, const Color(0xFFB98B57), 0, 0.15, 0)
    ..cylinder(0.02, 0.02, 0.22, 8, const Color(0xFF8A6238), const Vec3(0, 0.41, 0))
    ..cone(0.11, 0.14, 12, const Color(0xFFFFE9B8), const Vec3(0, 0.55, 0));
  mesh.add(table.translated(const Vec3(-h + 0.35, 0, 0.55)));

  // --- 空間の拡張（思い出が増えると家具が増える） ---
  if (propLevel >= 1) {
    final shelf = Mesh()
      ..box(0.9, 1.0, 0.26, const Color(0xFFB98B57), 0, 0.5, 0)
      ..box(0.82, 0.05, 0.2, const Color(0xFF8A6238), 0, 0.35, 0.02)
      ..box(0.82, 0.05, 0.2, const Color(0xFF8A6238), 0, 0.68, 0.02)
      ..box(0.16, 0.2, 0.14, theme.accent, -0.22, 0.47, 0.03)
      ..box(0.14, 0.16, 0.12, AppColors.blue, 0.2, 0.79, 0.03);
    mesh.add(shelf.translated(const Vec3(0.95, 0, -h + 0.2)));
  }
  if (propLevel >= 2) {
    final plant = Mesh()
      ..cylinder(0.13, 0.1, 0.2, 10, const Color(0xFFC97B4A), const Vec3(0, 0.1, 0))
      ..sphere(0.2, 10, 6, const Color(0xFF7E9E62), const Vec3(0, 0.36, 0));
    mesh.add(plant.translated(const Vec3(h - 0.3, 0, -h + 0.35)));
  }
  if (propLevel >= 3) {
    // かべのかざり（絵）
    mesh.box(0.4, 0.32, 0.04, Colors.white, -0.7, 1.25, -h + 0.02);
    mesh.box(0.32, 0.24, 0.04, theme.rug, -0.7, 1.25, -h + 0.035);
    mesh.box(0.3, 0.4, 0.04, Colors.white, -h + 0.02, 1.2, -0.6);
    mesh.box(0.22, 0.32, 0.04, const Color(0xFFC9DAE8), -h + 0.035, 1.2, -0.6);
  }

  return mesh;
}

/// ピンの頭の高さ（レイキャストの当たり判定もここを使う）
const double kPinHeadY = 0.36;
const double kPinHeadRadius = 0.11;

/// モノのピン（白い棒＋色つきの頭、地面に立つ）。原点まわりで組み立てる。
Mesh buildPin(Color tone) {
  return Mesh()
    ..cylinder(0.018, 0.018, 0.3, 8, Colors.white, const Vec3(0, 0.15, 0), caps: false)
    ..sphere(kPinHeadRadius, 12, 8, tone, const Vec3(0, kPinHeadY, 0))
    ..sphere(0.045, 8, 5, Colors.white, const Vec3(0, kPinHeadY, 0.085));
}
