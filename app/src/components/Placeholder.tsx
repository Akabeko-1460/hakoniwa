// .ph — 縞模様プレースホルダ
// repeating-linear-gradient(135deg,#E9DECC 0 9px,#F2EADA 9px 18px) 相当
import React from 'react';
import { StyleProp, StyleSheet, Text, View, ViewStyle } from 'react-native';
import Svg, { Defs, Pattern, Rect } from 'react-native-svg';
import { colors } from '../theme';

interface Props {
  label?: string;
  fontSize?: number;
  style?: StyleProp<ViewStyle>;
}

let patternSeq = 0;

export default function Placeholder({ label, fontSize = 10, style }: Props) {
  const idRef = React.useRef(`ph-stripes-${patternSeq++}`);
  const id = idRef.current;
  return (
    <View style={[styles.box, style]}>
      <Svg width="100%" height="100%" style={StyleSheet.absoluteFill}>
        <Defs>
          <Pattern
            id={id}
            patternUnits="userSpaceOnUse"
            width={18}
            height={18}
            patternTransform="rotate(135)"
          >
            <Rect width={18} height={18} fill="#F2EADA" />
            <Rect width={9} height={18} fill="#E9DECC" />
          </Pattern>
        </Defs>
        <Rect width="100%" height="100%" fill={`url(#${id})`} />
      </Svg>
      {label ? (
        <Text style={[styles.label, { fontSize }]}>{label}</Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F2EADA',
  },
  label: {
    color: colors.phText,
    fontWeight: '600',
    textAlign: 'center',
    letterSpacing: 0.3,
  },
});
