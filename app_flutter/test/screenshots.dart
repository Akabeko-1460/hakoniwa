// 目視確認用: 実際の画面を iPhone サイズ（402×874）で PNG に書き出す。
//   flutter test test/screenshots.dart
// 出力先は build/preview/screen-*.png（テストスイートではなく開発用のツール）。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hakoniwa/data/local_store.dart';
import 'package:hakoniwa/features/voice.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/screens/main_shell.dart';
import 'package:hakoniwa/screens/memory_screen.dart';
import 'package:hakoniwa/screens/onboard_screen.dart';
import 'package:hakoniwa/screens/space_screen.dart';
import 'package:hakoniwa/state/app_store.dart';
import 'package:hakoniwa/theme.dart';
import 'package:provider/provider.dart';

// デザイン基準の画面内寸
const _size = Size(402, 874);

/// 書体は本番では google_fonts が取ってくるが、テストでは通信させない。
/// build/fonts/*.ttf を置いておくと、日本語のまま見た目を確認できる。
/// （置き場所の用意: tool/fetch_fonts.sh）
Future<void> _loadFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final dir = Directory('build/fonts');
  if (!dir.existsSync()) return;

  final families = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.ttf')) continue;
    final family = file.uri.pathSegments.last.split('-').first;
    families.add(family);
    final loader = FontLoader(family)
      ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
  if (families.isEmpty) return;

  fontResolver = ({required bool maru, required TextStyle base}) =>
      base.copyWith(fontFamily: maru ? 'ZenMaruGothic' : 'ZenKakuGothicNew');
}

class _MemoryStore extends LocalStore {
  Database? saved;

  @override
  Future<Database?> load() async => saved;

  @override
  Future<void> save(Database db) async => saved = db;

  @override
  Future<String> importMedia(String uri, String ext) async => uri;

  @override
  Future<void> deleteMedia(Iterable<String> uris) async {}
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget home, {
  void Function(AppStore store)? setup,
}) async {
  await _loadFonts();
  tester.view
    ..physicalSize = _size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final store = AppStore(store: _MemoryStore());
  await store.init();
  setup?.call(store);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider(create: (_) => VoicePlayer()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: RepaintBoundary(key: const ValueKey('shot'), child: home),
      ),
    ),
  );
  // 画像のデコードは本物の非同期処理なので、待ってから撮る
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(milliseconds: 400));

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });

  final dir = Directory('build/preview')..createSync(recursive: true);
  File('${dir.path}/screen-$name.png').writeAsBytesSync(bytes!);
}

void main() {
  testWidgets('onboard', (t) => _shoot(t, 'onboard', const OnboardScreen()));

  testWidgets('home', (t) => _shoot(t, 'home', const MainShell()));

  testWidgets('space', (t) async {
    await _shoot(t, 'space', const SpaceScreen(childId: 'sota', initialSelectedId: 'bear'));
  });

  testWidgets('memory', (t) async {
    await _shoot(
      t,
      'memory',
      const MemoryScreen(),
      setup: (store) => store.setDraftFrames(const []),
    );
  });
}
