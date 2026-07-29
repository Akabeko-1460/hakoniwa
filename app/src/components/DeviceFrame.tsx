// PCブラウザで開いたときの見え方をととのえる枠。
//
// このアプリのデザインは「画面の内寸 402×874」を前提にしている
// （design_handoff_hakoniwa/README.md セクション3「デバイス枠」）。
// そのままブラウザの全幅に広げるとカードも3Dルームも間のびしてしまうので、
// 画面が広いときだけ電話サイズの中央カラムに収め、まわりは
// 指示書どおり「デバイス外」の背景色でうめる。
//
// スマホ（および狭いブラウザ）では何もせず、これまでどおり全画面で表示する。
import React from 'react';
import { StyleSheet, useWindowDimensions, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { colors, shadow } from '../theme';

/** デザイン基準の画面内寸 */
const SCREEN_WIDTH = 402;
const SCREEN_HEIGHT = 874;

/** これより広いときだけ枠に収める（横向きスマホやタブレットは全画面のまま） */
const WIDE_BREAKPOINT = 520;

export default function DeviceFrame({ children }: { children: React.ReactNode }) {
  const { width, height } = useWindowDimensions();

  if (width < WIDE_BREAKPOINT) return <>{children}</>;

  // 縦にも余裕があるときだけ角丸の枠にする（低い画面では上下いっぱい使う）
  const framed = height > SCREEN_HEIGHT + 40;
  const boxHeight = framed ? SCREEN_HEIGHT : height;

  return (
    <LinearGradient colors={[colors.outsideTop, colors.outsideBottom]} style={styles.outside}>
      <View
        style={[
          styles.device,
          { height: boxHeight },
          framed && styles.framed,
        ]}
      >
        {children}
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  outside: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  device: {
    width: SCREEN_WIDTH,
    maxWidth: '100%',
    backgroundColor: colors.cream,
    overflow: 'hidden',
  },
  framed: {
    borderRadius: 30,
    ...shadow(0.22, 48, 18),
  },
});
