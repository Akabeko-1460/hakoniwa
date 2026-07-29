// 永続化されるデータモデル（FastAPI 側 schemas.py と 1:1 で対応する）
import 'dart:math';

enum Season {
  haru('春'),
  natsu('夏'),
  aki('秋'),
  fuyu('冬');

  const Season(this.label);
  final String label;

  static Season fromLabel(String label) =>
      Season.values.firstWhere((s) => s.label == label, orElse: () => Season.fuyu);

  /// 新しい順に並べるときの重み（同じ年のなかで冬がいちばん新しい）
  int get order => index;
}

/// テーマカラーの選択肢（部屋の生成にも使う）
const kTones = <String>['#E08A63', '#8BA36F', '#C6A05E', '#7FA6C4'];

/// 新しいモノに付くピンの色（ブルー）
const kNewItemTone = '#7FA6C4';

final _rand = Random();

String newId() =>
    DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
    _rand.nextInt(1 << 30).toRadixString(36).padLeft(6, '0');

int nowMs() => DateTime.now().millisecondsSinceEpoch;

class Child {
  const Child({
    required this.id,
    required this.name,
    required this.age,
    required this.tone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int? age;
  final String tone; // テーマカラー（部屋の生成にも使う）
  final int createdAt;
  final int updatedAt;

  Child copyWith({String? name, int? age, String? tone, int? updatedAt}) => Child(
    id: id,
    name: name ?? this.name,
    age: age ?? this.age,
    tone: tone ?? this.tone,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'tone': tone,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Child.fromJson(Map<String, dynamic> json) => Child(
    id: json['id'] as String,
    name: json['name'] as String,
    age: (json['age'] as num?)?.toInt(),
    tone: json['tone'] as String? ?? kTones.first,
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    updatedAt:
        (json['updatedAt'] as num?)?.toInt() ?? (json['createdAt'] as num?)?.toInt() ?? 0,
  );
}

class VoiceMemo {
  const VoiceMemo({required this.uri, required this.durationSec});

  final String uri;
  final int durationSec;

  Map<String, dynamic> toJson() => {'uri': uri, 'durationSec': durationSec};

  factory VoiceMemo.fromJson(Map<String, dynamic> json) => VoiceMemo(
    uri: json['uri'] as String,
    durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
  );
}

/// 部屋の床上の正規化座標（x, z とも -1..1）
class RoomPos {
  const RoomPos(this.x, this.z);

  final double x;
  final double z;

  Map<String, dynamic> toJson() => {'x': x, 'z': z};

  factory RoomPos.fromJson(Map<String, dynamic> json) =>
      RoomPos((json['x'] as num).toDouble(), (json['z'] as num).toDouble());
}

class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.childId,
    required this.name,
    required this.year,
    required this.season,
    required this.memo,
    required this.frames,
    required this.photos,
    required this.voice,
    required this.pos,
    required this.tone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String childId;
  final String name;
  final int year;
  final Season season;
  final String memo;

  /// スキャンで撮った多方向フレーム（ターンテーブル3D表示に使う）
  final List<String> frames;

  /// そえた写真
  final List<String> photos;
  final VoiceMemo? voice;

  /// null = 未配置
  final RoomPos? pos;
  final String tone;
  final int createdAt;
  final int updatedAt;

  MemoryItem copyWith({
    String? name,
    String? memo,
    RoomPos? pos,
    List<String>? photos,
    VoiceMemo? voice,
    bool clearVoice = false,
    int? updatedAt,
  }) => MemoryItem(
    id: id,
    childId: childId,
    name: name ?? this.name,
    year: year,
    season: season,
    memo: memo ?? this.memo,
    frames: frames,
    photos: photos ?? this.photos,
    voice: clearVoice ? null : (voice ?? this.voice),
    pos: pos ?? this.pos,
    tone: tone,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'name': name,
    'year': year,
    'season': season.label,
    'memo': memo,
    'frames': frames,
    'photos': photos,
    'voice': voice?.toJson(),
    'pos': pos?.toJson(),
    'tone': tone,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory MemoryItem.fromJson(Map<String, dynamic> json) => MemoryItem(
    id: json['id'] as String,
    childId: json['childId'] as String,
    name: json['name'] as String,
    year: (json['year'] as num).toInt(),
    season: Season.fromLabel(json['season'] as String),
    memo: json['memo'] as String? ?? '',
    frames: (json['frames'] as List?)?.cast<String>() ?? const [],
    photos: (json['photos'] as List?)?.cast<String>() ?? const [],
    voice: json['voice'] == null
        ? null
        : VoiceMemo.fromJson((json['voice'] as Map).cast<String, dynamic>()),
    pos: json['pos'] == null
        ? null
        : RoomPos.fromJson((json['pos'] as Map).cast<String, dynamic>()),
    tone: json['tone'] as String? ?? kNewItemTone,
    createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    updatedAt:
        (json['updatedAt'] as num?)?.toInt() ?? (json['createdAt'] as num?)?.toInt() ?? 0,
  );

  /// 一覧のサムネイル（スキャンフレーム優先、なければ写真）
  String? get thumbnail =>
      frames.isNotEmpty ? frames.first : (photos.isNotEmpty ? photos.first : null);
}

class AppSettings {
  const AppSettings({this.scanTarget = 20, this.backup = true, this.notify = false});

  /// スキャンの撮影方向数（ふつう=12 / たかい=20）
  final int scanTarget;
  final bool backup;
  final bool notify;

  AppSettings copyWith({int? scanTarget, bool? backup, bool? notify}) => AppSettings(
    scanTarget: scanTarget ?? this.scanTarget,
    backup: backup ?? this.backup,
    notify: notify ?? this.notify,
  );

  Map<String, dynamic> toJson() => {
    'scanTarget': scanTarget,
    'backup': backup,
    'notify': notify,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    scanTarget: (json['scanTarget'] as num?)?.toInt() == 12 ? 12 : 20,
    backup: json['backup'] as bool? ?? true,
    notify: json['notify'] as bool? ?? false,
  );
}

/// サーバーと同期するための資格情報。バックアップをオンにしたときだけ持つ。
class FamilyCredentials {
  const FamilyCredentials({
    required this.baseUrl,
    required this.familyId,
    required this.token,
  });

  final String baseUrl;
  final String familyId;
  final String token;

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'familyId': familyId,
    'token': token,
  };

  factory FamilyCredentials.fromJson(Map<String, dynamic> json) => FamilyCredentials(
    baseUrl: json['baseUrl'] as String,
    familyId: json['familyId'] as String,
    token: json['token'] as String,
  );
}

/// 端末に保存される全データ
class Database {
  const Database({
    required this.children,
    required this.items,
    required this.settings,
    required this.onboarded,
    this.credentials,
    this.deletedChildIds = const [],
    this.deletedItemIds = const [],
  });

  static const version = 1;

  final List<Child> children;
  final List<MemoryItem> items;
  final AppSettings settings;
  final bool onboarded;
  final FamilyCredentials? credentials;

  /// 同期でサーバーへ伝える論理削除の記録
  final List<String> deletedChildIds;
  final List<String> deletedItemIds;

  Database copyWith({
    List<Child>? children,
    List<MemoryItem>? items,
    AppSettings? settings,
    bool? onboarded,
    FamilyCredentials? credentials,
    bool clearCredentials = false,
    List<String>? deletedChildIds,
    List<String>? deletedItemIds,
  }) => Database(
    children: children ?? this.children,
    items: items ?? this.items,
    settings: settings ?? this.settings,
    onboarded: onboarded ?? this.onboarded,
    credentials: clearCredentials ? null : (credentials ?? this.credentials),
    deletedChildIds: deletedChildIds ?? this.deletedChildIds,
    deletedItemIds: deletedItemIds ?? this.deletedItemIds,
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'children': children.map((c) => c.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
    'settings': settings.toJson(),
    'onboarded': onboarded,
    'credentials': credentials?.toJson(),
    'deletedChildIds': deletedChildIds,
    'deletedItemIds': deletedItemIds,
  };

  factory Database.fromJson(Map<String, dynamic> json) => Database(
    children: (json['children'] as List? ?? [])
        .map((c) => Child.fromJson((c as Map).cast<String, dynamic>()))
        .toList(),
    items: (json['items'] as List? ?? [])
        .map((i) => MemoryItem.fromJson((i as Map).cast<String, dynamic>()))
        .toList(),
    settings: AppSettings.fromJson(
      (json['settings'] as Map? ?? {}).cast<String, dynamic>(),
    ),
    onboarded: json['onboarded'] as bool? ?? false,
    credentials: json['credentials'] == null
        ? null
        : FamilyCredentials.fromJson((json['credentials'] as Map).cast<String, dynamic>()),
    deletedChildIds: (json['deletedChildIds'] as List?)?.cast<String>() ?? const [],
    deletedItemIds: (json['deletedItemIds'] as List?)?.cast<String>() ?? const [],
  );
}
