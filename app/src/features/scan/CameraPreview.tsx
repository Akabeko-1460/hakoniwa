// スキャン用カメラビュー（ダミー実装）
// 実装差し替えポイント: expo-camera の <CameraView> に置き換える。
// さらに実スキャンは iOS = Object Capture (RealityKit) / Android = ARCore ベースの
// ネイティブモジュールへ委譲する（README セクション2）。
import React from 'react';
import { StyleProp, ViewStyle } from 'react-native';
import Placeholder from '../../components/Placeholder';

export default function CameraPreview({ style }: { style?: StyleProp<ViewStyle> }) {
  return (
    <Placeholder
      label={'スキャン中の\nライブカメラ映像\n（つみき）'}
      fontSize={11}
      style={style}
    />
  );
}
