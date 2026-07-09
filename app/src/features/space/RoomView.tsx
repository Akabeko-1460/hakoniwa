// ハコニワの部屋（ジオラマ）ビュー（ダミー実装）
// 実装差し替えポイント: expo-gl + three.js (expo-three) で glTF/USDZ の
// 3Dルームモデルを表示・回転する（README セクション2）。
import React from 'react';
import { Image, StyleProp, StyleSheet, View, ViewStyle } from 'react-native';

const room = require('../../../assets/room-sample.png');

export default function RoomView({ style }: { style?: StyleProp<ViewStyle> }) {
  return (
    <View style={style}>
      <Image source={room} style={styles.img} resizeMode="cover" />
    </View>
  );
}

const styles = StyleSheet.create({
  img: { width: '100%', height: '100%' },
});
