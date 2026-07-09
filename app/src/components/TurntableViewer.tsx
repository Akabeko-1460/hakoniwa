// スキャンした多方向フレームを「回して見る」ターンテーブル3Dビュー
// 横ドラッグで撮影方向を切り替える（フォトグラメトリ導入後は glTF ビューアに差し替え）
import React, { useMemo, useRef, useState } from 'react';
import { Image, PanResponder, StyleProp, StyleSheet, Text, View, ViewStyle } from 'react-native';
import { colors, fonts } from '../theme';

interface Props {
  frames: string[];
  style?: StyleProp<ViewStyle>;
  showHint?: boolean;
}

export default function TurntableViewer({ frames, style, showHint }: Props) {
  const [idx, setIdx] = useState(0);
  const startIdx = useRef(0);

  const pan = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: (_e, g) => Math.abs(g.dx) > 4,
        onPanResponderGrant: () => {
          startIdx.current = idx;
        },
        onPanResponderMove: (_e, g) => {
          if (frames.length < 2) return;
          const step = Math.round(-g.dx / 18);
          const n = frames.length;
          setIdx(((startIdx.current + step) % n + n) % n);
        },
      }),
    [frames.length, idx],
  );

  if (frames.length === 0) return <View style={[styles.empty, style]} />;

  return (
    <View style={[styles.box, style]} {...pan.panHandlers}>
      <Image source={{ uri: frames[idx] }} style={StyleSheet.absoluteFill as never} resizeMode="cover" />
      {showHint && frames.length > 1 && (
        <View style={styles.hint}>
          <Text style={styles.hintText}>⟲ ドラッグで まわせるよ（{idx + 1}/{frames.length}）</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  box: { overflow: 'hidden', backgroundColor: '#EFE7D9' },
  empty: { backgroundColor: '#EFE7D9' },
  hint: {
    position: 'absolute',
    bottom: 8,
    alignSelf: 'center',
    backgroundColor: 'rgba(74,55,40,0.78)',
    borderRadius: 999,
    paddingVertical: 4,
    paddingHorizontal: 11,
  },
  hintText: { fontFamily: fonts.kaku600, fontSize: 10, color: '#fff' },
});
