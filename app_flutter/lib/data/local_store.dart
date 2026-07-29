// 永続化: ネイティブ = アプリのドキュメント領域（JSON + media ディレクトリ）
//         Web     = shared_preferences（メディアは元の blob URL のまま保持）
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'file_io.dart' as io;

const _dbFilename = 'hakoniwa.json';
const _mediaDirName = 'media';
const _webKey = 'hakoniwa-db';

class LocalStore {
  String? _docs;

  Future<String> _documents() async => _docs ??= await io.documentsPath();

  Future<Database?> load() async {
    try {
      final raw = io.hasFileSystem
          ? await io.readTextFile(io.joinPath(await _documents(), _dbFilename))
          : (await SharedPreferences.getInstance()).getString(_webKey);
      if (raw == null) return null;
      return Database.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('DB load failed: $e');
      return null;
    }
  }

  Future<void> save(Database db) async {
    try {
      final json = jsonEncode(db.toJson());
      if (io.hasFileSystem) {
        await io.writeTextFile(io.joinPath(await _documents(), _dbFilename), json);
      } else {
        await (await SharedPreferences.getInstance()).setString(_webKey, json);
      }
    } catch (e) {
      debugPrint('DB save failed: $e');
    }
  }

  /// カメラ・レコーダーの一時ファイルをアプリの永続領域へコピーして
  /// 永続パスを返す。Web ではそのまま返す（blob URL）。
  Future<String> importMedia(String uri, String ext) async {
    if (!io.hasFileSystem) return uri;
    try {
      final dir = io.joinPath(await _documents(), _mediaDirName);
      return await io.copyInto(uri, dir, '${newId()}.$ext');
    } catch (e) {
      debugPrint('media import failed, keeping original uri: $e');
      return uri;
    }
  }

  /// 使われなくなったメディアの実体を消す（思い出や子どもを削除したとき）
  Future<void> deleteMedia(Iterable<String> uris) async {
    if (!io.hasFileSystem) return;
    for (final uri in uris) {
      try {
        await io.deleteFile(uri);
      } catch (e) {
        debugPrint('media delete failed: $e');
      }
    }
  }
}
