// ストア（子ども・思い出・並べ替え・サーバー同期）の検証。
// 端末のファイルシステムやサーバーには触らず、差し替えた偽物で確かめる。
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hakoniwa/data/api_client.dart';
import 'package:hakoniwa/data/local_store.dart';
import 'package:hakoniwa/models/models.dart';
import 'package:hakoniwa/state/app_store.dart';
import 'package:http/http.dart' as http;

/// 保存先をメモリに置きかえたストア
class _MemoryStore extends LocalStore {
  Database? saved;

  @override
  Future<Database?> load() async => saved;

  @override
  Future<void> save(Database db) async => saved = db;

  @override
  Future<String> importMedia(String uri, String ext) async => 'imported:$uri';

  @override
  Future<void> deleteMedia(Iterable<String> uris) async {}
}

/// 送られてきたものをそのまま返す偽サーバー。
/// [hold] を渡すと、2回目以降の同期をその Future が終わるまで待たせる。
class _StubApi extends ApiClient {
  _StubApi({required super.baseUrl, super.token, this.hold, this.drop = const {}});

  final Future<void>? hold;

  /// サーバー側に無いことにする思い出のID（他端末で消された想定）
  final Set<String> drop;

  int _calls = 0;

  @override
  Future<FamilyCredentials> createFamily(String name) async =>
      FamilyCredentials(baseUrl: baseUrl, familyId: 'family', token: 'token');

  @override
  Future<String> verify() async => 'family';

  @override
  Future<String> uploadMedia(String path) async => path;

  @override
  Future<Snapshot> sync(Database db) async {
    _calls++;
    // つなぎ始めの1回は待たせない（テストの準備を止めないため）
    if (hold != null && _calls > 1) await hold;
    return Snapshot(
      children: db.children,
      items: db.items.where((i) => !drop.contains(i.id)).toList(),
      settings: db.settings,
      onboarded: db.onboarded,
      serverTime: nowMs(),
    );
  }

  @override
  void close() {}
}

Future<AppStore> newStore({LocalStore? local}) async {
  final store = AppStore(store: local ?? _MemoryStore());
  await store.init();
  return store;
}

void main() {
  group('ストアの基本', () {
    test('初回は見本のデータで始まる', () async {
      final store = await newStore();
      expect(store.ready, isTrue);
      expect(store.children.map((c) => c.name), containsAll(['そうた', 'みお']));
      expect(store.items, hasLength(6));
      expect(store.onboarded, isFalse);
    });

    test('子どもを足すとハコニワが増える', () async {
      final store = await newStore();
      final before = store.children.length;
      final child = store.addChild('はると', 4, '#7FA6C4');

      expect(store.children, hasLength(before + 1));
      expect(store.childById(child.id)?.name, 'はると');
      expect(store.itemsOf(child.id), isEmpty);
    });

    test('保存した思い出はメディアが永続領域へ移り、まだ未配置', () async {
      final store = await newStore();
      final item = await store.addItem(
        NewItemInput(
          childId: 'sota',
          name: 'つみき',
          year: 2024,
          season: Season.fuyu,
          memo: 'たかく つみあげて',
          frames: const ['/tmp/a.jpg', '/tmp/b.jpg'],
          photos: const ['/tmp/p.jpg'],
          voice: const VoiceMemo(uri: '/tmp/v.m4a', durationSec: 12),
          tone: kNewItemTone,
        ),
      );

      expect(item.frames, ['imported:/tmp/a.jpg', 'imported:/tmp/b.jpg']);
      expect(item.photos, ['imported:/tmp/p.jpg']);
      expect(item.voice!.uri, 'imported:/tmp/v.m4a');
      expect(item.voice!.durationSec, 12);
      expect(item.pos, isNull, reason: '保存した直後はまだ床に置かれていない');
      expect(store.itemsOf('sota'), contains(item));
    });

    test('名まえを空で保存しても、名なしにはならない', () async {
      final store = await newStore();
      final item = await store.addItem(
        const NewItemInput(
          childId: 'sota',
          name: '',
          year: 2024,
          season: Season.fuyu,
          memo: '',
          frames: [],
          photos: [],
          voice: null,
          tone: kNewItemTone,
        ),
      );
      expect(item.name, 'なまえのないモノ');
    });

    test('配置すると座標がつき、追加の演出フラグが立つ', () async {
      final store = await newStore();
      store.placeItem('bear', const RoomPos(0.5, -0.2));

      final bear = store.itemById('bear')!;
      expect(bear.pos!.x, 0.5);
      expect(bear.pos!.z, -0.2);
      expect(store.lastAddedId, 'bear');
    });

    test('思い出を消すとメディアの記録も消え、削除が同期対象になる', () async {
      final local = _MemoryStore();
      final store = await newStore(local: local);
      await store.deleteItem('bear');

      expect(store.itemById('bear'), isNull);
      expect(local.saved!.deletedItemIds, contains('bear'));
    });

    test('設定の変更が保存される', () async {
      final local = _MemoryStore();
      final store = await newStore(local: local);
      store.updateSettings(scanTarget: 12, notify: true);

      expect(store.settings.scanTarget, 12);
      expect(store.settings.notify, isTrue);
      expect(store.settings.backup, isTrue, reason: '触っていない設定は変わらない');
      expect(local.saved!.settings.scanTarget, 12);
    });
  });

  group('タイムライン', () {
    test('新しい順（年 → 季節）にならぶ', () async {
      final store = await newStore();
      expect(store.timeline().map((i) => i.name), [
        'かぞくの絵', // 2024 秋
        'ねんど工作', // 2023 夏
        'たんじょう日', // 2023 春
        'がらがら', // 2021 冬
        'はじめての靴', // 2021 秋
        'くまのプーさん', // 2019 春
      ]);
    });

    test('同じ年なら 冬 → 秋 → 夏 → 春 の順', () async {
      final store = await newStore();
      final of2023 = store.timeline().where((i) => i.year == 2023).toList();
      expect(of2023.map((i) => i.season.label), ['夏', '春']);
    });

    test('子どもで絞り込める', () async {
      final store = await newStore();
      final mio = store.timeline(childFilter: 'mio');
      expect(mio, hasLength(3));
      expect(mio.every((i) => i.childId == 'mio'), isTrue);
    });

    test('名まえとメモの両方から検索できる', () async {
      final store = await newStore();
      expect(store.timeline(query: 'くま').map((i) => i.name), ['くまのプーさん']);
      expect(store.timeline(query: 'ポチ').map((i) => i.name), ['かぞくの絵']);
      expect(store.timeline(query: 'みつからない語'), isEmpty);
    });
  });

  group('保存と読み直し', () {
    test('JSON に落として読み直しても中身が変わらない', () async {
      final local = _MemoryStore();
      final store = await newStore(local: local);
      await store.addItem(
        const NewItemInput(
          childId: 'sota',
          name: 'つみき',
          year: 2024,
          season: Season.fuyu,
          memo: 'まいにち あそんだ',
          frames: [],
          photos: [],
          voice: VoiceMemo(uri: '/tmp/v.m4a', durationSec: 8),
          tone: kNewItemTone,
        ),
      );

      final reloaded = await newStore(local: local);
      final item = reloaded.items.firstWhere((i) => i.name == 'つみき');
      expect(item.season, Season.fuyu);
      expect(item.memo, 'まいにち あそんだ');
      expect(item.voice!.durationSec, 8);
      expect(reloaded.children.length, store.children.length);
    });
  });

  group('サーバー同期', () {
    test('バックアップが無いときは通信しない', () async {
      var called = false;
      final store = AppStore(
        store: _MemoryStore(),
        apiFactory: (baseUrl, token) {
          called = true;
          return ApiClient(baseUrl: baseUrl, token: token);
        },
      );
      await store.init();
      await store.syncNow();

      expect(called, isFalse);
      expect(store.syncState, SyncState.idle);
    });

    test('同期している最中に配置しても、その配置が消えない', () async {
      // サーバーの返事が遅れているあいだにモノを置く。返事が届いたときに
      // 手元の配置を上書きしてしまうと、置いた場所が黙って元に戻る。
      final gate = Completer<void>();
      final local = _MemoryStore();
      final store = AppStore(
        store: local,
        apiFactory: (baseUrl, token) =>
            _StubApi(baseUrl: baseUrl, token: token, hold: gate.future),
      );
      await store.init();
      await store.connectBackup(baseUrl: 'http://stub');

      final target = store.items.first;
      final syncing = store.syncNow(silent: true);

      // 返事を待たせているあいだに配置する
      store.placeItem(target.id, const RoomPos(0.42, -0.25));
      expect(store.itemById(target.id)!.pos, isNotNull);

      gate.complete();
      await syncing;

      final after = store.itemById(target.id)!;
      expect(after.pos, isNotNull, reason: '同期の返事が配置を消してしまっている');
      expect(after.pos!.x, 0.42);
    });

    test('同期している最中に足した思い出が、返事で消えない', () async {
      final gate = Completer<void>();
      final store = AppStore(
        store: _MemoryStore(),
        apiFactory: (baseUrl, token) =>
            _StubApi(baseUrl: baseUrl, token: token, hold: gate.future),
      );
      await store.init();
      await store.connectBackup(baseUrl: 'http://stub');

      final syncing = store.syncNow(silent: true);
      final added = await store.addItem(
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

      gate.complete();
      await syncing;

      expect(store.itemById(added.id), isNotNull, reason: '送信中に足したモノが消えている');
    });

    test('サーバーで消されたモノは手元からも消える', () async {
      final store = AppStore(
        store: _MemoryStore(),
        apiFactory: (baseUrl, token) => _StubApi(
          baseUrl: baseUrl,
          token: token,
          // サーバーは「bear が無い」状態を返す
          drop: {'bear'},
        ),
      );
      await store.init();
      await store.connectBackup(baseUrl: 'http://stub');
      await store.syncNow(silent: true);

      expect(store.itemById('bear'), isNull);
      expect(store.items, isNotEmpty, reason: 'ほかのモノまで消えてはいけない');
    });

    test('同期に失敗してもローカルの思い出は消えない', () async {
      final local = _MemoryStore();
      final store = AppStore(
        store: local,
        // つながらないサーバーを向ける
        apiFactory: (baseUrl, token) =>
            ApiClient(baseUrl: baseUrl, token: token, httpClient: _FailingClient()),
      );
      await store.init();
      await store
          .connectBackup(baseUrl: 'http://unreachable.invalid', token: 'tok')
          .catchError((_) {});

      expect(store.items, isNotEmpty, reason: 'オフラインでも手元のデータは残る');
      expect(store.syncState, SyncState.failed);
    });
  });
}

/// どのリクエストも失敗させる HTTP クライアント
class _FailingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(const _Unreachable());
}

class _Unreachable implements Exception {
  const _Unreachable();
  @override
  String toString() => 'unreachable';
}
