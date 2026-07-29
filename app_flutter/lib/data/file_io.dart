// ファイル操作のプラットフォーム切り替え。
//
// Web には dart:io が無いので、Web 向けビルドでは何もしないスタブに差し替わる
// （Web ではメディアを blob URL のまま扱い、DBは shared_preferences に置く）。
export 'file_io_stub.dart' if (dart.library.io) 'file_io_native.dart';
