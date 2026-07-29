// 目視確認用: 3Dルームを PNG に書き出す。
//   flutter test test/render_preview.dart
// 出力先は build/preview/*.png（テストスイートではなく開発用のツール）。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/room3d/room_view.dart';

Future<void> _shoot(WidgetTester tester, String name, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(child: SizedBox(width: 380, height: 340, child: child)),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).last,
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });

  final dir = Directory('build/preview')..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!);
}

void main() {
  testWidgets('そうたのハコニワ（思い出3コ・基本の部屋）', (tester) async {
    await _shoot(
      tester,
      'room-sota',
      const RoomView(
        items: [
          RoomItem(id: 'bear', tone: '#E08A63', pos: RoomPos(-0.32, 0.1)),
          RoomItem(id: 'clay', tone: '#8BA36F', pos: RoomPos(0.4, 0.25)),
          RoomItem(id: 'draw', tone: '#C6A05E', pos: RoomPos(0.56, -0.45)),
        ],
        childTone: '#E08A63',
        selectedId: 'clay',
        onSelect: _ignore,
        onPlace: _ignore,
      ),
    );
  });

  testWidgets('みおのハコニワ（グリーン・思い出12コで拡張ずみ）', (tester) async {
    await _shoot(
      tester,
      'room-mio-expanded',
      RoomView(
        items: [
          for (var i = 0; i < 12; i++)
            RoomItem(
              id: 'i$i',
              tone: kTones[i % kTones.length],
              pos: RoomPos(-0.8 + (i % 4) * 0.5, -0.6 + (i ~/ 4) * 0.55),
            ),
        ],
        childTone: '#8BA36F',
        onSelect: _ignore,
        onPlace: _ignore,
      ),
    );
  });
}

void _ignore(Object? _) {}
