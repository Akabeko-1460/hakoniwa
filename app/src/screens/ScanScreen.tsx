// 4-3. 3Dスキャン — 実カメラでモノを回り込みながら多方向キャプチャ
// 撮影したフレーム列はターンテーブル3D表示に使う（フォトグラメトリは後段差し替え）
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Animated, ScrollView, StyleSheet, Text, View } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { LinearGradient } from 'expo-linear-gradient';
import { CameraView, useCameraPermissions } from 'expo-camera';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../navigation/types';
import { absoluteFill, colors, fonts, shadow } from '../theme';
import { useStore } from '../store/Store';
import { useScreenInsets } from '../hooks/useScreenInsets';
import TapScale from '../components/TapScale';
import { BackIcon, CheckIcon, ReloadIcon } from '../components/Icons';

type Props = NativeStackScreenProps<RootStackParamList, 'Scan'>;

const R = 66;
const C = 2 * Math.PI * R;
const MIN_FRAMES = 8; // これだけ撮れば完了できる

export default function ScanScreen({ navigation }: Props) {
  const { top } = useScreenInsets();
  const { settings, setDraftFrames } = useStore();
  const MAX = settings.scanTarget;

  const [permission, requestPermission] = useCameraPermissions();
  const cameraRef = useRef<CameraView>(null);
  const [frames, setFrames] = useState<string[]>([]);
  const [auto, setAuto] = useState(false);
  const busy = useRef(false);
  const barAnim = useRef(new Animated.Value(0)).current;

  const progress = frames.length;
  const frac = Math.min(1, progress / MAX);
  const canFinish = progress >= MIN_FRAMES;

  useEffect(() => {
    Animated.timing(barAnim, { toValue: frac, duration: 300, useNativeDriver: false }).start();
  }, [frac, barAnim]);

  const capture = useCallback(async () => {
    if (busy.current || !cameraRef.current) return;
    if (frames.length >= MAX) return;
    busy.current = true;
    try {
      const photo = await cameraRef.current.takePictureAsync({
        quality: 0.5,
        skipProcessing: true,
      });
      if (photo?.uri) setFrames((f) => (f.length >= MAX ? f : [...f, photo.uri]));
    } catch (e) {
      console.warn('capture failed:', e);
    } finally {
      busy.current = false;
    }
  }, [frames.length, MAX]);

  // じどう撮影: まわりを歩きながら一定間隔でキャプチャ
  useEffect(() => {
    if (!auto) return;
    if (frames.length >= MAX) {
      setAuto(false);
      return;
    }
    const id = setInterval(capture, 800);
    return () => clearInterval(id);
  }, [auto, capture, frames.length, MAX]);

  const retake = () => {
    setAuto(false);
    setFrames([]);
  };

  const finish = () => {
    if (!canFinish) return;
    setAuto(false);
    setDraftFrames(frames);
    navigation.navigate('Memory');
  };

  const hint =
    progress >= MAX
      ? 'キャプチャ 完了！ 右下の完了へ'
      : frac > 0.5
        ? 'あと ちょっと！ 反対がわを写して'
        : 'ぐるっと 一周してね';

  return (
    <View style={styles.root}>
      <View style={[styles.header, { paddingTop: top }]}>
        <TapScale style={styles.headerBtn} onPress={() => navigation.popTo('Main')}>
          <BackIcon />
        </TapScale>
        <Text style={styles.headerTitle}>3Dスキャン</Text>
        <TapScale style={styles.headerBtn}>
          <Text style={styles.helpText}>?</Text>
        </TapScale>
      </View>

      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 6 }}>
        <Text style={styles.targetName}>あたらしい たからもの</Text>
        <Text style={styles.targetHint}>まわりを ぐるっと写してね</Text>

        <View style={styles.cameraBox}>
          {permission?.granted ? (
            <CameraView ref={cameraRef} style={styles.camera} facing="back" animateShutter={false} />
          ) : (
            <View style={[styles.camera, styles.permissionBox]}>
              <Text style={styles.permissionText}>
                3Dスキャンには{'\n'}カメラを つかいます
              </Text>
              <TapScale style={styles.permissionBtn} onPress={() => requestPermission()}>
                <Text style={styles.permissionBtnText}>カメラを ゆるす</Text>
              </TapScale>
            </View>
          )}
          <View style={[styles.corner, styles.cornerTL]} pointerEvents="none" />
          <View style={[styles.corner, styles.cornerTR]} pointerEvents="none" />
          <View style={[styles.corner, styles.cornerBL]} pointerEvents="none" />
          <View style={[styles.corner, styles.cornerBR]} pointerEvents="none" />
          <View style={styles.ringWrap} pointerEvents="none">
            <Svg width={150} height={150} viewBox="0 0 150 150">
              <Circle
                cx={75} cy={75} r={R}
                fill="none" stroke="rgba(255,255,255,0.55)" strokeWidth={6}
                strokeDasharray="6 8" strokeLinecap="round"
              />
              <Circle
                cx={75} cy={75} r={R}
                fill="none" stroke={colors.accent} strokeWidth={6} strokeLinecap="round"
                strokeDasharray={`${(frac * C).toFixed(1)} ${C.toFixed(1)}`}
                transform="rotate(-90 75 75)"
              />
            </Svg>
          </View>
          {/* じどう撮影トグル */}
          <TapScale
            style={[styles.autoChip, auto && styles.autoChipOn]}
            onPress={() => {
              if (!permission?.granted) return;
              setAuto((a) => !a);
            }}
          >
            <Text style={[styles.autoChipText, auto && styles.autoChipTextOn]}>
              {auto ? '● じどう撮影中' : 'じどう撮影'}
            </Text>
          </TapScale>
          <View style={styles.hintBubble} pointerEvents="none">
            <Text style={styles.hintText}>{hint}</Text>
          </View>
        </View>

        <View style={styles.progressRow}>
          <Text style={styles.progressLabel}>キャプチャ 進行ど</Text>
          <Text style={styles.progressCount}>{progress} / {MAX} 方向</Text>
        </View>
        <View style={styles.track}>
          <Animated.View
            style={[
              styles.fill,
              { width: barAnim.interpolate({ inputRange: [0, 1], outputRange: ['0%', '100%'] }) },
            ]}
          >
            <LinearGradient
              colors={['#EFA981', colors.accent]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={StyleSheet.absoluteFill}
            />
          </Animated.View>
        </View>
        {progress > 0 && progress < MIN_FRAMES && (
          <Text style={styles.minNote}>あと {MIN_FRAMES - progress}枚で 完了できるよ</Text>
        )}
      </ScrollView>

      <View style={styles.controls}>
        <TapScale style={styles.sideBtn} onPress={retake}>
          <View style={styles.sideCircle}>
            <ReloadIcon />
          </View>
          <Text style={styles.sideLabel}>やり直す</Text>
        </TapScale>
        <TapScale testID="shutter" style={styles.shutter} onPress={capture}>
          <View style={styles.shutterInner} />
        </TapScale>
        <TapScale
          style={[styles.sideBtn, { opacity: frac >= 1 ? 1 : canFinish ? 0.75 : 0.4 }]}
          onPress={finish}
        >
          <View style={[styles.sideCircle, { backgroundColor: colors.greenPale }]}>
            <CheckIcon />
          </View>
          <Text style={[styles.sideLabel, { color: colors.green }]}>完了</Text>
        </TapScale>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.cream },
  header: {
    paddingHorizontal: 20,
    paddingBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: colors.chipBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: { fontFamily: fonts.maru700, fontSize: 16, color: colors.textStrong },
  helpText: { fontFamily: fonts.maru700, fontSize: 15, color: colors.textMid2 },
  targetName: {
    textAlign: 'center',
    fontFamily: fonts.maru700,
    fontSize: 15,
    color: colors.textStrong,
    marginTop: 6,
    marginBottom: 3,
  },
  targetHint: {
    textAlign: 'center',
    fontFamily: fonts.kaku500,
    fontSize: 12,
    color: colors.textFaint2,
    marginBottom: 16,
  },
  cameraBox: {
    height: 340,
    borderRadius: 28,
    overflow: 'hidden',
    backgroundColor: '#3A3129',
    borderWidth: 1.5,
    borderColor: colors.border14,
  },
  camera: { flex: 1 },
  permissionBox: {
    alignItems: 'center',
    justifyContent: 'center',
    gap: 14,
    backgroundColor: '#EFE7D9',
  },
  permissionText: {
    fontFamily: fonts.kaku600,
    fontSize: 13,
    lineHeight: 13 * 1.7,
    color: colors.textFaint,
    textAlign: 'center',
  },
  permissionBtn: {
    backgroundColor: colors.accent,
    borderRadius: 14,
    paddingVertical: 10,
    paddingHorizontal: 18,
  },
  permissionBtnText: { fontFamily: fonts.maru700, fontSize: 13, color: '#fff' },
  corner: { position: 'absolute', width: 26, height: 26, borderColor: '#fff' },
  cornerTL: { top: 14, left: 14, borderTopWidth: 3, borderLeftWidth: 3, borderTopLeftRadius: 8 },
  cornerTR: { top: 14, right: 14, borderTopWidth: 3, borderRightWidth: 3, borderTopRightRadius: 8 },
  cornerBL: { bottom: 14, left: 14, borderBottomWidth: 3, borderLeftWidth: 3, borderBottomLeftRadius: 8 },
  cornerBR: { bottom: 14, right: 14, borderBottomWidth: 3, borderRightWidth: 3, borderBottomRightRadius: 8 },
  ringWrap: {
    ...absoluteFill,
    alignItems: 'center',
    justifyContent: 'center',
  },
  autoChip: {
    position: 'absolute',
    top: 14,
    alignSelf: 'center',
    backgroundColor: 'rgba(255,255,255,0.85)',
    borderRadius: 999,
    paddingVertical: 5,
    paddingHorizontal: 13,
  },
  autoChipOn: { backgroundColor: colors.accentRec },
  autoChipText: { fontFamily: fonts.maru700, fontSize: 11, color: colors.textMid2 },
  autoChipTextOn: { color: '#fff' },
  hintBubble: {
    position: 'absolute',
    bottom: 16,
    alignSelf: 'center',
    backgroundColor: 'rgba(74,55,40,0.82)',
    paddingVertical: 5,
    paddingHorizontal: 13,
    borderRadius: 999,
  },
  hintText: { fontFamily: fonts.kaku600, fontSize: 11, color: '#fff' },
  progressRow: {
    marginTop: 18,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  progressLabel: { fontFamily: fonts.kaku600, fontSize: 12, color: colors.textMid },
  progressCount: { fontFamily: fonts.maru700, fontSize: 13, color: colors.accent },
  track: {
    marginTop: 8,
    height: 9,
    borderRadius: 999,
    backgroundColor: colors.trackBg,
    overflow: 'hidden',
  },
  fill: { height: '100%', borderRadius: 999, overflow: 'hidden' },
  minNote: {
    marginTop: 8,
    textAlign: 'center',
    fontFamily: fonts.kaku500,
    fontSize: 11,
    color: colors.textFaint2,
  },
  controls: {
    paddingTop: 16,
    paddingHorizontal: 20,
    paddingBottom: 30,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 26,
  },
  sideBtn: { alignItems: 'center', gap: 4 },
  sideCircle: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: colors.chipBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sideLabel: { fontFamily: fonts.kaku600, fontSize: 10, color: colors.textFaint2 },
  shutter: {
    width: 76,
    height: 76,
    borderRadius: 38,
    backgroundColor: '#fff',
    borderWidth: 4,
    borderColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    ...shadow(0.35, 20, 8, 'rgb(224,138,99)'),
  },
  shutterInner: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.accent,
  },
});
