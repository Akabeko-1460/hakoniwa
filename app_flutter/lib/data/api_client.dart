// FastAPI バックエンド（../backend）とのやりとり。
//
// アプリはローカルDBが正のオフラインファースト。ここでの通信は
// 「ローカルDBを丸ごと送って、マージ結果を丸ごと受け取る」1往復に集約している。
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/models.dart';
import 'file_io.dart' as io;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// サーバーから返るマージ済みの全データ
class Snapshot {
  const Snapshot({
    required this.children,
    required this.items,
    required this.settings,
    required this.onboarded,
    required this.serverTime,
  });

  final List<Child> children;
  final List<MemoryItem> items;
  final AppSettings settings;
  final bool onboarded;
  final int serverTime;

  factory Snapshot.fromJson(Map<String, dynamic> json) {
    final settings = (json['settings'] as Map).cast<String, dynamic>();
    return Snapshot(
      children: (json['children'] as List)
          .map((c) => Child.fromJson((c as Map).cast<String, dynamic>()))
          .toList(),
      items: (json['items'] as List)
          .map((i) => MemoryItem.fromJson((i as Map).cast<String, dynamic>()))
          .toList(),
      settings: AppSettings.fromJson(settings),
      onboarded: settings['onboarded'] as bool? ?? false,
      serverTime: (json['serverTime'] as num?)?.toInt() ?? nowMs(),
    );
  }
}

class ApiClient {
  ApiClient({required String baseUrl, this.token, http.Client? httpClient})
    : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
      _http = httpClient ?? http.Client();

  final String baseUrl;
  final String? token;
  final http.Client _http;

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _authHeader => {
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    ..._authHeader,
  };

  Map<String, dynamic> _json(http.Response res) {
    if (res.statusCode >= 400) {
      String detail = res.reasonPhrase ?? 'エラー';
      try {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (body is Map && body['detail'] != null) detail = body['detail'].toString();
      } catch (_) {
        // JSON でないレスポンスは reasonPhrase をそのまま使う
      }
      throw ApiException(detail, statusCode: res.statusCode);
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<bool> health() async {
    try {
      final res = await _http.get(_uri('/api/health')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 新しい家族を作ってトークンを受け取る（バックアップを初めてオンにしたとき）
  Future<FamilyCredentials> createFamily(String name) async {
    final res = await _http
        .post(_uri('/api/families'), headers: _headers, body: jsonEncode({'name': name}))
        .timeout(_timeout);
    final body = _json(res);
    return FamilyCredentials(
      baseUrl: baseUrl,
      familyId: body['familyId'] as String,
      token: body['token'] as String,
    );
  }

  /// 既存トークンが有効か確かめる（機種変更のときの復元）
  Future<String> verify() async {
    final res = await _http
        .get(_uri('/api/families/me'), headers: _headers)
        .timeout(_timeout);
    return _json(res)['familyId'] as String;
  }

  Future<Snapshot> snapshot() async {
    final res = await _http.get(_uri('/api/snapshot'), headers: _headers).timeout(_timeout);
    return Snapshot.fromJson(_json(res));
  }

  /// ローカルDBを丸ごと push して、マージ結果を受け取る
  Future<Snapshot> sync(Database db) async {
    final res = await _http
        .post(
          _uri('/api/sync'),
          headers: _headers,
          body: jsonEncode({
            'children': db.children.map((c) => c.toJson()).toList(),
            'items': db.items.map((i) => i.toJson()).toList(),
            'settings': {...db.settings.toJson(), 'onboarded': db.onboarded},
            'deletedChildIds': db.deletedChildIds,
            'deletedItemIds': db.deletedItemIds,
          }),
        )
        .timeout(_timeout);
    return Snapshot.fromJson(_json(res));
  }

  /// 端末内のメディアをアップロードして、サーバー上の URL を返す。
  /// すでにサーバー上のもの（http〜）や Web の blob URL はそのまま返す。
  Future<String> uploadMedia(String path) async {
    if (path.startsWith('http') || path.startsWith('blob:')) return path;
    final bytes = await io.readBytes(path);
    if (bytes == null) return path;

    final type = contentTypeOf(path).split('/');
    final request = http.MultipartRequest('POST', _uri('/api/media'))
      ..headers.addAll(_authHeader)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: path.split(RegExp(r'[\\/]')).last,
          contentType: MediaType(type.first, type.last),
        ),
      );
    final res = await http.Response.fromStream(await request.send().timeout(_timeout));
    return '$baseUrl${_json(res)['url']}';
  }

  void close() => _http.close();
}

/// 拡張子から Content-Type を推測する（アップロード時に使う）
String contentTypeOf(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'm4a' || 'mp4' || 'aac' => 'audio/mp4',
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'webm' => 'audio/webm',
    _ => 'image/jpeg',
  };
}
