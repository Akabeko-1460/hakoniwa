// .tap:active { transform:scale(.96); filter:brightness(.97) } 相当の押下フィードバック
import React from 'react';
import { Pressable, StyleProp, ViewStyle } from 'react-native';

interface Props {
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
  children?: React.ReactNode;
  disabled?: boolean;
  testID?: string;
}

export default function TapScale({ onPress, style, children, disabled, testID }: Props) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      testID={testID}
      style={({ pressed }) => [
        style,
        pressed && { transform: [{ scale: 0.96 }], opacity: 0.97 },
      ]}
    >
      {children}
    </Pressable>
  );
}
