// Flutter 側の ApiClient / AppStore が、実際に動いている FastAPI サーバーと
// 話せるかを確かめる結合テスト。
//
// サーバーが立っていないときは丸ごとスキップする（ふだんの flutter test の邪魔をしない）。
//   cd ../backend && .venv/bin/uvicorn app.main:app --port 8000
//   flutter test test/integration_sync_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hakoniwa/data/api_client.dart';
import 'package:hakoniwa/data/local_store.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/state/app_store.dart';

const _baseUrl = String.fromEnvironment(
  'HAKONIWA_API',
  defaultValue: 'http://localhost:8000',
);

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

void main() {
  late bool serverUp;

  setUpAll(() async {
    serverUp = await ApiClient(baseUrl: _baseUrl).health();
    if (!serverUp) {
      // ignore: avoid_print
      print('FastAPI サーバー（$_baseUrl）が見つからないので、この結合テストはスキップします');
    }
  });

  test('家族を作って、ローカルDBを丸ごと同期できる', () async {
    if (!serverUp) return;

    final store = AppStore(store: _MemoryStore());
    await store.init();
    final localCount = store.items.length;

    await store.connectBackup(baseUrl: _baseUrl, familyName: '結合テスト家');

    expect(store.credentials, isNotNull);
    expect(store.syncState, SyncState.ok, reason: store.syncError ?? '');
    expect(store.items, hasLength(localCount), reason: '同期で思い出が減ってはいけない');
    expect(store.children.map((c) => c.name), containsAll(['そうた', 'みお']));
  });

  test('別の端末が同じトークンで参加すると、同じハコニワが見える', () async {
    if (!serverUp) return;

    final first = AppStore(store: _MemoryStore());
    await first.init();
    await first.connectBackup(baseUrl: _baseUrl, familyName: '共有テスト家');
    final added = await first.addItem(
      const NewItemInput(
        childId: 'sota',
        name: 'つみき',
        year: 2024,
        season: Season.fuyu,
        memo: 'たかく つみあげて',
        frames: [],
        photos: [],
        voice: null,
        tone: kNewItemTone,
      ),
    );
    first.placeItem(added.id, const RoomPos(0.2, -0.3));
    await first.syncNow();

    // まっさらな2台目が、1台目のトークンで参加する
    final second = AppStore(store: _MemoryStore());
    await second.init();
    await second.connectBackup(
      baseUrl: _baseUrl,
      token: first.credentials!.token,
    );

    final seen = second.itemById(added.id);
    expect(seen, isNotNull, reason: '1台目で足した思い出が2台目に届いていない');
    expect(seen!.name, 'つみき');
    expect(seen.memo, 'たかく つみあげて');
    expect(seen.pos!.x, closeTo(0.2, 1e-6));
    expect(second.credentials!.familyId, first.credentials!.familyId);
  });

  test('まちがったトークンでは参加できない', () async {
    if (!serverUp) return;

    final store = AppStore(store: _MemoryStore());
    await store.init();

    await expectLater(
      store.connectBackup(baseUrl: _baseUrl, token: 'not-a-real-token'),
      throwsA(isA<ApiException>()),
    );
    expect(store.credentials, isNull);
    expect(store.syncState, SyncState.failed);
  });

  test('トークンに使えない文字が混ざっていても、わかる形で失敗する', () async {
    if (!serverUp) return;

    final store = AppStore(store: _MemoryStore());
    await store.init();

    // HTTP ヘッダに入れられない文字（貼りまちがい）でも、生の例外を投げない
    await expectLater(
      store.connectBackup(baseUrl: _baseUrl, token: 'にせもの'),
      throwsA(isA<ApiException>()),
    );
    expect(store.syncError, isNotNull);
  });
}
