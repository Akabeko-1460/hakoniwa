// 広い画面（PCブラウザ）で、電話サイズの枠に収まっているかの検証。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hakoniwa/data/local_store.dart';
import 'package:hakoniwa/features/voice.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/screens/main_shell.dart';
import 'package:hakoniwa/state/app_store.dart';
import 'package:hakoniwa/theme.dart';
import 'package:hakoniwa/widgets/device_frame.dart';
import 'package:provider/provider.dart';

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

Future<void> pumpAt(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = AppStore(store: _MemoryStore());
  await store.init();
  store.setOnboarded(true);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider(create: (_) => VoicePlayer()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => DeviceFrame(child: child!),
        home: const MainShell(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  testWidgets('広い画面では電話幅の中央カラムに収まる', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));

    final frame = tester.getRect(find.byType(MainShell));
    expect(frame.width, kDeviceWidth, reason: '横に間のびしている');
    expect(frame.height, kDeviceHeight);
    // 中央にあること
    expect(frame.center.dx, closeTo(720, 0.5));
  });

  testWidgets('背の低い広い画面では上下いっぱいを使う', (tester) async {
    await pumpAt(tester, const Size(1440, 800));

    final frame = tester.getRect(find.byType(MainShell));
    expect(frame.width, kDeviceWidth);
    expect(frame.height, 800);
  });

  testWidgets('スマホ幅では枠を出さず全画面のまま', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    final frame = tester.getRect(find.byType(MainShell));
    expect(frame.width, 390, reason: 'スマホで幅が削られている');
    expect(frame.height, 844);
  });

  testWidgets('枠の中では画面サイズが枠のサイズとして見える', (tester) async {
    await pumpAt(tester, const Size(1440, 1000));

    final size = tester
        .element(find.byType(MainShell))
        .findAncestorWidgetOfExactType<MediaQuery>()!
        .data
        .size;
    expect(size.width, kDeviceWidth);
  });
}
