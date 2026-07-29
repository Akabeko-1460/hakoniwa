// こえメモ: 録音と再生
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../data/file_io.dart' as io;
import '../models/models.dart';

String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// 録音の状態を持つコントローラ。画面から listen して表示を更新する。
class VoiceRecorder extends ChangeNotifier {
  // 実際に録音するまでマイクのプラグインには触らない
  AudioRecorder? _recorder;
  Timer? _tick;

  bool _recording = false;
  bool get recording => _recording;

  int _seconds = 0;

  /// 録音中の経過秒
  int get seconds => _seconds;

  bool _permissionDenied = false;
  bool get permissionDenied => _permissionDenied;

  Future<bool> start() async {
    final recorder = _recorder ??= AudioRecorder();
    if (!await recorder.hasPermission()) {
      _permissionDenied = true;
      notifyListeners();
      return false;
    }
    _permissionDenied = false;
    // Web は m4a を書き出せないので、そこだけ opus/webm にする
    final config = RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc);
    await recorder.start(config, path: await _outputPath());
    _recording = true;
    _seconds = 0;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      notifyListeners();
    });
    notifyListeners();
    return true;
  }

  Future<VoiceMemo?> stop() async {
    final recorder = _recorder;
    if (!_recording || recorder == null) return null;
    _tick?.cancel();
    final path = await recorder.stop();
    final duration = _seconds;
    _recording = false;
    _seconds = 0;
    notifyListeners();
    if (path == null) return null;
    return VoiceMemo(uri: path, durationSec: duration < 1 ? 1 : duration);
  }

  /// 一時ファイルとして書き出し、保存時に LocalStore が永続領域へ移す。
  /// Web では blob URL が返るのでパスは使われない。
  Future<String> _outputPath() async {
    if (kIsWeb) return '';
    return io.joinPath(await io.temporaryPath(), 'rec-${newId()}.m4a');
  }

  @override
  void dispose() {
    _tick?.cancel();
    _recorder?.dispose();
    super.dispose();
  }
}

/// こえメモの再生。いま鳴っている URI を持つ。
class VoicePlayer extends ChangeNotifier {
  // 実際に再生するまで音声プラグインには触らない
  // （こえメモを聞かないまま終わる人のほうが多い）
  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  String? _playingUri;

  String? get playingUri => _playingUri;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _completion = player.onPlayerComplete.listen((_) {
      _playingUri = null;
      notifyListeners();
    });
    return _player = player;
  }

  Future<void> toggle(String uri) async {
    final player = _ensurePlayer();
    final wasPlaying = _playingUri == uri;
    await player.stop();
    _playingUri = null;
    if (wasPlaying) {
      notifyListeners();
      return;
    }
    await player.play(
      uri.startsWith('http') || uri.startsWith('blob:')
          ? UrlSource(uri)
          : DeviceFileSource(uri),
    );
    _playingUri = uri;
    notifyListeners();
  }

  @override
  void dispose() {
    _completion?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
