// こえメモ: 録音と再生（expo-audio）
import { useCallback, useEffect, useState } from 'react';
import {
  AudioModule,
  RecordingPresets,
  setAudioModeAsync,
  useAudioPlayer,
  useAudioPlayerStatus,
  useAudioRecorder,
  useAudioRecorderState,
} from 'expo-audio';
import type { VoiceMemo } from '../../store/types';

export function useVoiceRecorder() {
  const recorder = useAudioRecorder(RecordingPresets.HIGH_QUALITY);
  const state = useAudioRecorderState(recorder);
  const [permissionDenied, setPermissionDenied] = useState(false);

  const start = useCallback(async () => {
    const { granted } = await AudioModule.requestRecordingPermissionsAsync();
    if (!granted) {
      setPermissionDenied(true);
      return false;
    }
    await setAudioModeAsync({ playsInSilentMode: true, allowsRecording: true });
    await recorder.prepareToRecordAsync();
    recorder.record();
    return true;
  }, [recorder]);

  const stop = useCallback(async (): Promise<VoiceMemo | null> => {
    const durationSec = Math.max(1, Math.round((state.durationMillis ?? 0) / 1000));
    await recorder.stop();
    await setAudioModeAsync({ playsInSilentMode: true, allowsRecording: false });
    if (!recorder.uri) return null;
    return { uri: recorder.uri, durationSec };
  }, [recorder, state.durationMillis]);

  return {
    recording: state.isRecording,
    /** 録音中の経過秒 */
    seconds: Math.round((state.durationMillis ?? 0) / 1000),
    permissionDenied,
    start,
    stop,
  };
}

export function useVoicePlayer() {
  const player = useAudioPlayer(null);
  const status = useAudioPlayerStatus(player);
  const [currentUri, setCurrentUri] = useState<string | null>(null);

  useEffect(() => {
    if (status.didJustFinish) setCurrentUri(null);
  }, [status.didJustFinish]);

  const toggle = useCallback(
    (uri: string) => {
      if (currentUri === uri && status.playing) {
        player.pause();
        setCurrentUri(null);
        return;
      }
      player.replace(uri);
      player.seekTo(0);
      player.play();
      setCurrentUri(uri);
    },
    [player, currentUri, status.playing],
  );

  return { playingUri: status.playing ? currentUri : null, toggle };
}

export function formatDuration(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}
