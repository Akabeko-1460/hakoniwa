// アプリ全体のデータストア（子ども・思い出・設定）+ 一時状態（スキャン下書き等）
//
// ローカルDBが正で、変更のたびに端末へ保存する。バックアップがオンなら
// そのあとバックグラウンドで FastAPI サーバーへ同期する。
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/local_store.dart';
import '../data/seed.dart';
import '../models/models.dart';

/// スキャン→「思い出をのこす」へ渡す新規モノの入力
class NewItemInput {
  const NewItemInput({
    required this.childId,
    required this.name,
    required this.year,
    required this.season,
    required this.memo,
    required this.frames,
    required this.photos,
    required this.voice,
    required this.tone,
  });

  final String childId;
  final String name;
  final int year;
  final Season season;
  final String memo;

  /// スキャンで撮ったキャッシュURI（永続領域へコピーされる）
  final List<String> frames;
  final List<String> photos;
  final VoiceMemo? voice;
  final String tone;
}

enum SyncState { idle, syncing, ok, failed }

class AppStore extends ChangeNotifier {
  AppStore({LocalStore? store, ApiClient Function(String baseUrl, String? token)? apiFactory})
    : _store = store ?? LocalStore(),
      _apiFactory =
          apiFactory ?? ((baseUrl, token) => ApiClient(baseUrl: baseUrl, token: token));

  final LocalStore _store;

  /// 通信の作り口。テストでは偽のサーバーに差し替える。
  final ApiClient Function(String baseUrl, String? token) _apiFactory;

  Database? _db;
  bool get ready => _db != null;

  List<Child> get children => _db?.children ?? const [];
  List<MemoryItem> get items => _db?.items ?? const [];
  AppSettings get settings => _db?.settings ?? const AppSettings();
  bool get onboarded => _db?.onboarded ?? false;
  FamilyCredentials? get credentials => _db?.credentials;

  /// スキャン→思い出をのこす 間で受け渡す撮影フレーム
  List<String> _draftFrames = const [];
  List<String> get draftFrames => _draftFrames;

  /// 追加直後の演出用（3.2秒で自動クリア）
  String? _lastAddedId;
  String? get lastAddedId => _lastAddedId;
  Timer? _addedTimer;

  SyncState _syncState = SyncState.idle;

  /// いま走っている同期と、その後ろに1つだけ積める予約
  Future<void>? _active;
  Future<void>? _queued;
  SyncState get syncState => _syncState;
  String? _syncError;
  String? get syncError => _syncError;

  Future<void> init() async {
    _db = await _store.load() ?? seedDatabase();
    notifyListeners();
    if (_db!.credentials != null && _db!.settings.backup) {
      unawaited(syncNow());
    }
  }

  Child? childById(String id) {
    for (final c in children) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<MemoryItem> itemsOf(String childId) =>
      items.where((it) => it.childId == childId).toList();

  MemoryItem? itemById(String id) {
    for (final it in items) {
      if (it.id == id) return it;
    }
    return null;
  }

  /// 新しい順（年 → 季節 → 登録順）。検索語と子どもで絞り込む。
  List<MemoryItem> timeline({String childFilter = 'all', String query = ''}) {
    final q = query.trim();
    final list = items
        .where((it) => childFilter == 'all' || it.childId == childFilter)
        .where((it) => q.isEmpty || it.name.contains(q) || it.memo.contains(q))
        .toList();
    list.sort((a, b) {
      final byYear = b.year.compareTo(a.year);
      if (byYear != 0) return byYear;
      final bySeason = b.season.order.compareTo(a.season.order);
      if (bySeason != 0) return bySeason;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  void setDraftFrames(List<String> frames) {
    _draftFrames = frames;
    notifyListeners();
  }

  Future<void> _commit(Database next, {bool sync = true}) async {
    _db = next;
    notifyListeners();
    await _store.save(next);
    if (sync) unawaited(syncNow(silent: true));
  }

  Child addChild(String name, int? age, String tone) {
    final ts = nowMs();
    final child = Child(
      id: newId(),
      name: name,
      age: age,
      tone: tone,
      createdAt: ts,
      updatedAt: ts,
    );
    unawaited(_commit(_db!.copyWith(children: [..._db!.children, child])));
    return child;
  }

  Future<MemoryItem> addItem(NewItemInput input) async {
    // メディアを永続領域へコピー
    final frames = [for (final uri in input.frames) await _store.importMedia(uri, 'jpg')];
    final photos = [for (final uri in input.photos) await _store.importMedia(uri, 'jpg')];
    final voice = input.voice == null
        ? null
        : VoiceMemo(
            uri: await _store.importMedia(input.voice!.uri, 'm4a'),
            durationSec: input.voice!.durationSec,
          );

    final ts = nowMs();
    final item = MemoryItem(
      id: newId(),
      childId: input.childId,
      name: input.name.isEmpty ? 'なまえのないモノ' : input.name,
      year: input.year,
      season: input.season,
      memo: input.memo,
      frames: frames,
      photos: photos,
      voice: voice,
      pos: null,
      tone: input.tone,
      createdAt: ts,
      updatedAt: ts,
    );
    await _commit(_db!.copyWith(items: [..._db!.items, item]));
    return item;
  }

  /// ハコニワの床にモノを置く（配置機能）
  void placeItem(String id, RoomPos pos) {
    final next = _db!.items
        .map((it) => it.id == id ? it.copyWith(pos: pos, updatedAt: nowMs()) : it)
        .toList();
    unawaited(_commit(_db!.copyWith(items: next)));
    _markAdded(id);
  }

  Future<void> deleteItem(String id) async {
    final item = itemById(id);
    if (item == null) return;
    await _commit(
      _db!.copyWith(
        items: _db!.items.where((it) => it.id != id).toList(),
        deletedItemIds: [..._db!.deletedItemIds, id],
      ),
    );
    await _store.deleteMedia([
      ...item.frames,
      ...item.photos,
      if (item.voice != null) item.voice!.uri,
    ]);
  }

  void _markAdded(String id) {
    _lastAddedId = id;
    _addedTimer?.cancel();
    _addedTimer = Timer(const Duration(milliseconds: 3200), () {
      _lastAddedId = null;
      notifyListeners();
    });
  }

  void setOnboarded(bool v) => unawaited(_commit(_db!.copyWith(onboarded: v)));

  void updateSettings({int? scanTarget, bool? backup, bool? notify}) {
    final next = _db!.settings.copyWith(
      scanTarget: scanTarget,
      backup: backup,
      notify: notify,
    );
    unawaited(_commit(_db!.copyWith(settings: next)));
  }

  // --- サーバー同期 -----------------------------------------------------

  /// バックアップを有効にする。まだ家族が無ければ作り、トークンを保存する。
  /// 既存のトークンを渡せば別端末のハコニワに参加できる（機種変更・共有）。
  Future<void> connectBackup({
    required String baseUrl,
    String? token,
    String familyName = 'わが家',
  }) async {
    _setSync(SyncState.syncing);
    try {
      final creds = await _obtainCredentials(baseUrl, token, familyName);
      await _commit(
        _db!.copyWith(credentials: creds, settings: _db!.settings.copyWith(backup: true)),
        sync: false,
      );
      await syncNow();
    } on Object catch (e) {
      // 通信エラーもトークンの書式エラーも、呼び出し側には同じ形で返す
      final failure = e is ApiException ? e : ApiException('サーバーにつながりませんでした');
      _syncError = failure.message;
      _setSync(SyncState.failed);
      throw failure;
    }
  }

  /// トークンがあれば既存の家族に参加し、無ければ新しい家族を作る
  Future<FamilyCredentials> _obtainCredentials(
    String baseUrl,
    String? token,
    String familyName,
  ) async {
    if (token == null || token.isEmpty) {
      final api = _apiFactory(baseUrl, null);
      try {
        return await api.createFamily(familyName);
      } finally {
        api.close();
      }
    }
    final api = _apiFactory(baseUrl, token);
    try {
      final familyId = await api.verify();
      return FamilyCredentials(baseUrl: baseUrl, familyId: familyId, token: token);
    } finally {
      api.close();
    }
  }

  Future<void> disconnectBackup() async {
    await _commit(
      _db!.copyWith(
        clearCredentials: true,
        settings: _db!.settings.copyWith(backup: false),
      ),
      sync: false,
    );
    _setSync(SyncState.idle);
  }

  /// ローカルDBを送り、マージ結果でローカルを置き換える。
  /// 失敗してもローカルのデータはそのまま（オフラインファースト）。
  ///
  /// 同期どうしは直列に流す。走っている最中に来た呼び出しは捨てずに、
  /// 終わったあと1回にまとめて追いかける（そうしないと、同期中に足した思い出が
  /// サーバーに届かないまま「同期した」ことになってしまう）。
  Future<void> syncNow({bool silent = false}) {
    final db = _db;
    final creds = db?.credentials;
    if (db == null || creds == null || !db.settings.backup) {
      return Future<void>.value();
    }

    final active = _active;
    if (active == null) return _startSync(silent);
    return _queued ??= active.then((_) => _startSync(silent));
  }

  Future<void> _startSync(bool silent) {
    _queued = null;
    final run = _runSync(silent: silent);
    // 失敗しても後続の予約は流したいので、ここでは例外を握りつぶす
    _active = run
        .then<void>((_) {}, onError: (Object _) {})
        .whenComplete(() => _active = null);
    return run;
  }

  Future<void> _runSync({required bool silent}) async {
    final db = _db!;
    final creds = db.credentials!;
    _setSync(SyncState.syncing);
    final api = _apiFactory(creds.baseUrl, creds.token);
    try {
      // メディアの実体をサーバーへ預けてから、URL に差し替えて送る
      final uploaded = await _uploadPendingMedia(db, api);
      final snapshot = await api.sync(uploaded);

      // 送っているあいだに手元で変えたぶんを、サーバーの返事で消さない。
      // （保存直後にモノを配置すると、ちょうどこの隙間に入る）
      final current = _db!;
      await _commit(
        current.copyWith(
          children: _merge(
            pushed: uploaded.children,
            remote: snapshot.children,
            local: current.children,
            idOf: (c) => c.id,
            updatedAtOf: (c) => c.updatedAt,
          ),
          items: _merge(
            pushed: uploaded.items,
            remote: snapshot.items,
            local: current.items,
            idOf: (i) => i.id,
            updatedAtOf: (i) => i.updatedAt,
          ),
          settings: snapshot.settings.copyWith(backup: true),
          onboarded: current.onboarded || snapshot.onboarded,
          // 送りそこねた削除は次の同期へ持ちこす
          deletedChildIds: current.deletedChildIds
              .where((id) => !uploaded.deletedChildIds.contains(id))
              .toList(),
          deletedItemIds: current.deletedItemIds
              .where((id) => !uploaded.deletedItemIds.contains(id))
              .toList(),
        ),
        sync: false,
      );
      _syncError = null;
      _setSync(SyncState.ok);
    } on Object catch (e) {
      _syncError = e is ApiException ? e.message : 'サーバーにつながりませんでした';
      _setSync(SyncState.failed);
      if (!silent) rethrow;
    } finally {
      api.close();
    }
  }

  /// サーバーの返事とローカルを突き合わせる。
  ///
  /// - 両方にある → updatedAt の新しいほうを採る
  /// - サーバーにだけある → 他の端末が足したもの。もらう
  /// - ローカルにだけあり、まだ送っていない → 送信中に増えたもの。残す
  /// - ローカルにだけあり、送ったのに返ってこない → サーバーで消された。落とす
  static List<T> _merge<T>({
    required List<T> pushed,
    required List<T> remote,
    required List<T> local,
    required String Function(T) idOf,
    required int Function(T) updatedAtOf,
  }) {
    final pushedIds = {for (final row in pushed) idOf(row)};
    final remoteById = {for (final row in remote) idOf(row): row};
    final kept = <String>{};
    final out = <T>[];

    for (final row in local) {
      final id = idOf(row);
      kept.add(id);
      final fromServer = remoteById[id];
      if (fromServer == null) {
        if (!pushedIds.contains(id)) out.add(row);
        continue;
      }
      out.add(updatedAtOf(row) > updatedAtOf(fromServer) ? row : fromServer);
    }
    for (final row in remote) {
      if (!kept.contains(idOf(row))) out.add(row);
    }
    return out;
  }

  /// まだサーバーに無いローカルファイルをアップロードし、URLに置き換えたDBを返す
  Future<Database> _uploadPendingMedia(Database db, ApiClient api) async {
    final cache = <String, String>{};

    Future<List<String>> up(List<String> uris) async => [
      for (final uri in uris) cache[uri] ??= await api.uploadMedia(uri),
    ];

    final items = <MemoryItem>[];
    var changed = false;
    for (final item in db.items) {
      final frames = await up(item.frames);
      final photos = await up(item.photos);
      final voiceUri = item.voice == null
          ? null
          : (cache[item.voice!.uri] ??= await api.uploadMedia(item.voice!.uri));
      final same =
          listEquals(frames, item.frames) &&
          listEquals(photos, item.photos) &&
          voiceUri == item.voice?.uri;
      if (same) {
        items.add(item);
        continue;
      }
      changed = true;
      items.add(
        MemoryItem(
          id: item.id,
          childId: item.childId,
          name: item.name,
          year: item.year,
          season: item.season,
          memo: item.memo,
          frames: frames,
          photos: photos,
          voice: voiceUri == null
              ? null
              : VoiceMemo(uri: voiceUri, durationSec: item.voice!.durationSec),
          pos: item.pos,
          tone: item.tone,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        ),
      );
    }
    return changed ? db.copyWith(items: items) : db;
  }

  void _setSync(SyncState state) {
    _syncState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }
}
