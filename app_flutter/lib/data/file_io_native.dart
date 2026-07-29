// iOS / Android / デスクトップ向けの実ファイル操作。
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const bool hasFileSystem = true;

Future<String> documentsPath() async => (await getApplicationDocumentsDirectory()).path;

/// 録音などの一時ファイル置き場
Future<String> temporaryPath() async => (await getTemporaryDirectory()).path;

Future<String?> readTextFile(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsString();
}

Future<void> writeTextFile(String path, String contents) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(contents, flush: true);
}

Future<Uint8List?> readBytes(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsBytes();
}

/// srcPath のファイルを dirPath/filename へコピーして、コピー先のパスを返す
Future<String> copyInto(String srcPath, String dirPath, String filename) async {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final dest = p.join(dirPath, filename);
  await File(srcPath).copy(dest);
  return dest;
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  if (file.existsSync()) await file.delete();
}

bool fileExists(String path) => File(path).existsSync();

String joinPath(String a, String b) => p.join(a, b);

/// メディアURIから画像プロバイダを作る（ローカルパス or サーバーURL）
ImageProvider imageProviderFor(String uri) =>
    uri.startsWith('http') ? NetworkImage(uri) : FileImage(File(uri)) as ImageProvider;
