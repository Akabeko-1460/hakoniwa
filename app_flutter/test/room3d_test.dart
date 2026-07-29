// 3Dルームのレンダラの検証。
// ジオメトリの数学（レイキャスト）と、実際に絵が出ているかの両方を見る。
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/room3d/room_builder.dart';
import 'package:hakoniwa/room3d/room_view.dart';
import 'package:hakoniwa/room3d/scene3d.dart';

void main() {
  group('ジオメトリ', () {
    test('箱は6面できる', () {
      final mesh = Mesh()..box(1, 1, 1, Colors.white, 0, 0, 0);
      expect(mesh.faces.length, 6);
    });

    test('面は光の向きに応じて明るさが変わる', () {
      final mesh = Mesh()..box(1, 1, 1, const Color(0xFF808080), 0, 0, 0);
      final brightness = mesh.faces.map((f) => f.color.r).toSet();
      expect(brightness.length, greaterThan(1), reason: '全面が同じ色なら陰影がついていない');
    });

    test('平行移動しても面の数と色は変わらない', () {
      final mesh = Mesh()..box(1, 1, 1, Colors.white, 0, 0, 0);
      final moved = mesh.translated(const Vec3(1, 2, 3));
      expect(moved.faces.length, mesh.faces.length);
      expect(moved.faces.first.color, mesh.faces.first.color);
      expect(moved.faces.first.verts.first.y, mesh.faces.first.verts.first.y + 2);
    });
  });

  group('部屋の生成', () {
    test('思い出が増えると家具の段階が上がる', () {
      expect(propLevelFor(0), 0);
      expect(propLevelFor(4), 0);
      expect(propLevelFor(5), 1);
      expect(propLevelFor(8), 2);
      expect(propLevelFor(12), 3);
    });

    test('段階が上がるほど面が増える（空間の拡張）', () {
      final theme = RoomTheme.fromTone('#E08A63');
      final counts = [
        for (var level = 0; level <= 3; level++) buildRoom(theme, level).faces.length,
      ];
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThan(counts[i - 1]));
      }
    });

    test('テーマカラーが部屋の壁の色に反映される', () {
      final orange = RoomTheme.fromTone('#E08A63');
      final green = RoomTheme.fromTone('#8BA36F');
      expect(orange.wall, isNot(green.wall));
      expect(orange.accent, const Color(0xFFE08A63));
    });
  });

  group('レイキャスト', () {
    OrbitCamera camera() => OrbitCamera(
      target: const Vec3(0, 0.55, 0),
      radius: 5.4,
      theta: math.pi / 4,
      phi: 0.62,
    );

    test('画面の中心から出たレイは床を手前で貫く', () {
      const size = Size(360, 330);
      final renderer = SceneRenderer(camera(), size);
      final ray = renderer.rayThrough(const Offset(180, 165));
      final hit = intersectHorizontalPlane(ray, 0);

      expect(hit, isNotNull);
      expect(hit!.x.abs(), lessThan(kFloorHalf));
      expect(hit.z.abs(), lessThan(kFloorHalf));
    });

    test('床に置いたピンを投影した点へレイを飛ばすと、そのピンに当たる', () {
      const size = Size(360, 330);
      final renderer = SceneRenderer(camera(), size);

      const pos = RoomPos(0.4, 0.25);
      final center = Vec3(pos.x * kPinReach, kPinHeadY, pos.z * kPinReach);
      final screen = renderer.projectPoint(center);

      expect(screen, isNotNull, reason: 'ピンが画面に写っていない');
      expect(
        intersectSphere(renderer.rayThrough(screen!), center, kPinHeadRadius),
        isNotNull,
        reason: '投影とレイキャストが逆演算になっていない',
      );
    });

    test('床にタップした点は、投影しなおすと同じ画面座標に戻る', () {
      const size = Size(360, 330);
      final renderer = SceneRenderer(camera(), size);
      const tap = Offset(200, 220);

      final hit = intersectHorizontalPlane(renderer.rayThrough(tap), 0);
      final back = renderer.projectPoint(hit!);

      expect(back!.dx, closeTo(tap.dx, 0.01));
      expect(back.dy, closeTo(tap.dy, 0.01));
    });

    test('カメラの後ろ側の平面とは交わらない', () {
      final renderer = SceneRenderer(camera(), const Size(360, 330));
      final ray = renderer.rayThrough(const Offset(180, 165));
      // カメラより上の平面は、下を向いたレイとは手前で交わらない
      expect(intersectHorizontalPlane(ray, 99), isNull);
    });
  });

  group('描画', () {
    testWidgets('部屋が実際にキャンバスへ描かれる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: RepaintBoundary(
                child: RoomView(
                  items: const [
                    RoomItem(id: 'a', tone: '#E08A63', pos: RoomPos(-0.32, 0.1)),
                    RoomItem(id: 'b', tone: '#8BA36F', pos: RoomPos(0.4, 0.25)),
                  ],
                  childTone: '#E08A63',
                  onSelect: _ignore,
                  onPlace: _ignore,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).last,
      );
      // 画像化はエンジン側の本物の非同期処理なので runAsync で包む
      final data = await tester.runAsync(() async {
        final image = await boundary.toImage();
        return image.toByteData(format: ui.ImageByteFormat.rawRgba);
      });
      expect(data, isNotNull);

      // 何種類もの色が出ていること = 陰影のついた面が描けている
      final bytes = data!.buffer.asUint8List();
      final distinct = <int>{};
      for (var i = 0; i < bytes.length; i += 4) {
        distinct.add((bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2]);
      }
      expect(
        distinct.length,
        greaterThan(8),
        reason: '色が $distinct 種類しか出ていない。面が描かれていない可能性',
      );
    });

    testWidgets('床は明るい表面が見える（裏面が描かれていない）', (tester) async {
      const side = 300.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: RoomView(
                    items: [],
                    childTone: '#E08A63',
                    onSelect: _ignore,
                    onPlace: _ignore,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).last,
      );
      final data = await tester.runAsync(() async {
        final image = await boundary.toImage();
        return image.toByteData(format: ui.ImageByteFormat.rawRgba);
      });
      final bytes = data!.buffer.asUint8List();

      // ラグにも家具にもかからない床の一点をねらう
      final renderer = SceneRenderer(
        OrbitCamera(
          target: const Vec3(0, 0.55, 0),
          radius: 5.4,
          theta: math.pi / 4,
          phi: 0.62,
        ),
        const Size(side, side),
      );
      final at = renderer.projectPoint(const Vec3(0.9, 0, 0.9))!;
      final offset = ((at.dy.round() * side.toInt()) + at.dx.round()) * 4;

      // 上を向いた面は光を受けて明るい。裏面（下向き）なら環境光ぶんしか無い。
      // 取りちがえると床の裏側が見えてしまうので、明るさで見張る。
      final red = bytes[offset];
      expect(red, greaterThan(200), reason: '床が暗い（$red）。裏面が描かれている可能性がある');
    });

    testWidgets('配置モードで床をタップすると座標が返る', (tester) async {
      RoomPos? placed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: RoomView(
                items: const [],
                childTone: '#E08A63',
                placeMode: true,
                onSelect: _ignore,
                onPlace: (p) => placed = p,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tapAt(tester.getCenter(find.byType(RoomView)));
      await tester.pump();

      expect(placed, isNotNull);
      expect(placed!.x, inInclusiveRange(-0.95, 0.95));
      expect(placed!.z, inInclusiveRange(-0.95, 0.95));
    });

    testWidgets('ピンをタップすると、そのモノが選ばれる', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: RoomView(
                items: const [RoomItem(id: 'bear', tone: '#E08A63', pos: RoomPos(0, 0))],
                childTone: '#E08A63',
                onSelect: (id) => selected = id,
                onPlace: _ignore,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // 部屋の中央に立つピンが画面のどこに写るかを計算してから押す
      final box = tester.getRect(find.byType(RoomView));
      final renderer = SceneRenderer(
        OrbitCamera(
          target: const Vec3(0, 0.55, 0),
          radius: 5.4,
          theta: math.pi / 4,
          phi: 0.62,
        ),
        box.size,
      );
      final head = renderer.projectPoint(const Vec3(0, kPinHeadY, 0))!;

      await tester.tapAt(box.topLeft + head);
      await tester.pump();

      expect(selected, 'bear');
    });
  });
}

void _ignore(Object? _) {}
