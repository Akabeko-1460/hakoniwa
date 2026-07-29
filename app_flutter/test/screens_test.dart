// 画面が実際に組み上がるか、主な導線がつながっているかを確かめる。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hakoniwa/data/local_store.dart';
import 'package:hakoniwa/features/voice.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/room3d/room_view.dart';
import 'package:hakoniwa/screens/main_shell.dart';
import 'package:hakoniwa/screens/memories_screen.dart';
import 'package:hakoniwa/screens/onboard_screen.dart';
import 'package:hakoniwa/screens/settings_screen.dart';
import 'package:hakoniwa/screens/space_screen.dart';
import 'package:hakoniwa/state/app_store.dart';
import 'package:hakoniwa/theme.dart';
import 'package:hakoniwa/widgets/bottom_nav.dart';
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

/// Google Fonts はテストでネットワークを見に行かないので、
/// アプリと同じ構成のまま画面だけを立ち上げる。
Future<AppStore> pumpApp(WidgetTester tester, Widget home) async {
  final store = AppStore(store: _MemoryStore());
  await store.init();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider(create: (_) => VoicePlayer()),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: home),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  return store;
}

void main() {
  testWidgets('オンボーディングの「はじめる」で本編に進む', (tester) async {
    final store = await pumpApp(tester, const OnboardScreen());

    expect(find.text('大切なモノを、\n思い出と一緒に。'), findsOneWidget);
    expect(store.onboarded, isFalse);

    await tester.tap(find.text('はじめる'));
    await tester.pump();

    expect(store.onboarded, isTrue);
  });

  testWidgets('ホームに家族のハコニワと最近の思い出がならぶ', (tester) async {
    await pumpApp(tester, const MainShell());

    expect(find.text('ハコニワ'), findsOneWidget);
    expect(find.text('そうた'), findsWidgets);
    expect(find.text('みお'), findsWidgets);
    // そうた=3コ / みお=3コ
    expect(find.text('3コ'), findsNWidgets(2));
    expect(find.text('さいきん ふえた思い出'), findsOneWidget);
  });

  testWidgets('タブを切り替えると おもいで・せってい が出る', (tester) async {
    await pumpApp(tester, const MainShell());

    await tester.tap(find.text('さがす'));
    await tester.pump();
    expect(find.byType(MemoriesScreen), findsOneWidget);
    expect(find.text('ぜんぶで 6コ ・ 新しいものから むかしへ'), findsOneWidget);

    await tester.tap(find.text('せってい'));
    await tester.pump();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('たかい（20方向） ›'), findsOneWidget);
  });

  testWidgets('タイムラインで検索すると絞りこまれる', (tester) async {
    await pumpApp(tester, const MainShell());
    await tester.tap(find.text('さがす'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'ポチ');
    await tester.pump();

    expect(find.text('かぞくの絵'), findsOneWidget);
    expect(find.text('がらがら'), findsNothing);
  });

  testWidgets('スキャンの画質をタップで切り替えられる', (tester) async {
    final store = await pumpApp(tester, const MainShell());
    await tester.tap(find.text('せってい'));
    await tester.pump();

    await tester.tap(find.text('スキャンの画質'));
    await tester.pump();

    expect(store.settings.scanTarget, 12);
    expect(find.text('ふつう（12方向） ›'), findsOneWidget);
  });

  testWidgets('ハコニワ画面に3Dルームと思い出の数が出る', (tester) async {
    await pumpApp(tester, const SpaceScreen(childId: 'sota'));

    expect(find.byType(RoomView), findsOneWidget);
    expect(find.text('そうたの ハコニワ'), findsOneWidget);
    expect(find.text('3コの思い出'), findsNWidgets(2)); // ヘッダーと部屋のバッジ
    expect(find.text('＋ スキャンして モノをふやす'), findsOneWidget);
  });

  testWidgets('ピンを選ぶと思い出の情報シートが開き、×で閉じる', (tester) async {
    await pumpApp(tester, const SpaceScreen(childId: 'sota', initialSelectedId: 'bear'));

    expect(find.text('くまのプーさん'), findsOneWidget);
    expect(find.text('2019年 春'), findsOneWidget);
    expect(find.text('はじめて自分でえらんだ ぬいぐるみ。毎ばん いっしょに ねていました。'), findsOneWidget);

    await tester.tap(find.byType(SpaceScreen).first, warnIfMissed: false);
    await tester.pump();
  });

  testWidgets('配置モードでは、置き場所をうながす帯と「おまかせ」が出る', (tester) async {
    final store = AppStore(store: _MemoryStore());
    await store.init();
    // 未配置のモノを1つ用意する
    final item = await store.addItem(
      const NewItemInput(
        childId: 'sota',
        name: 'つみき',
        year: 2024,
        season: Season.fuyu,
        memo: '',
        frames: [],
        photos: [],
        voice: null,
        tone: kNewItemTone,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: store),
          ChangeNotifierProvider(create: (_) => VoicePlayer()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: SpaceScreen(childId: 'sota', placeItemId: item.id),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('「つみき」を おく場所を タップしてね'), findsOneWidget);
    expect(find.text('お部屋の ゆかを タップしてね'), findsOneWidget);

    await tester.tap(find.text('おまかせ'));
    await tester.pump();

    expect(store.itemById(item.id)!.pos, isNotNull, reason: 'おまかせで床に置かれる');
    expect(find.text('「つみき」を おく場所を タップしてね'), findsNothing);

    // 置いた直後の「おきました」帯は数秒で自然に消える
    expect(find.textContaining('をおきました'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('をおきました'), findsNothing);
  });

  testWidgets('下部タブは5項目そろっている', (tester) async {
    await pumpApp(tester, const MainShell());

    expect(find.byType(BottomNav), findsOneWidget);
    for (final label in ['ホーム', 'さがす', 'のこす', 'おもいで', 'せってい']) {
      expect(find.text(label), findsOneWidget, reason: '$label が無い');
    }
  });
}
