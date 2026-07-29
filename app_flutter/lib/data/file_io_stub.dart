// Web 向けのスタブ。ファイルシステムを持たないので、すべて何もしない。
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

const bool hasFileSystem = false;

Future<String> documentsPath() async => '';

/// Web には一時ファイルの置き場が無い（録音は blob URL で返る）
Future<String> temporaryPath() async => '';

Future<String?> readTextFile(String path) async => null;

Future<void> writeTextFile(String path, String contents) async {}

Future<Uint8List?> readBytes(String path) async => null;

/// Web ではコピーせず、元の blob URL をそのまま使う
Future<String> copyInto(String srcPath, String dirPath, String filename) async => srcPath;

Future<void> deleteFile(String path) async {}

bool fileExists(String path) => false;

String joinPath(String a, String b) => '$a/$b';

/// Web ではメディアは blob: か http: の URL なので、どちらもネットワーク扱い
ImageProvider imageProviderFor(String uri) => NetworkImage(uri);
