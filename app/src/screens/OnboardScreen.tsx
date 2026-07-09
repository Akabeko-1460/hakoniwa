// 4-1. オンボーディング
import React, { useEffect, useRef } from 'react';
import { Animated, Easing, Image, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../navigation/types';
import { absoluteFill, colors, fonts, shadow } from '../theme';
import TapScale from '../components/TapScale';
import { useScreenInsets } from '../hooks/useScreenInsets';
import { useStore } from '../store/Store';

const room = require('../../assets/room-sample.png');

type Props = NativeStackScreenProps<RootStackParamList, 'Onboard'>;

export default function OnboardScreen({ navigation }: Props) {
  const { setOnboarded } = useStore();
  const float = useRef(new Animated.Value(0)).current;

  // hako-float 5s ease-in-out infinite（±5px 上下）
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(float, { toValue: 1, duration: 2500, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
        Animated.timing(float, { toValue: 0, duration: 2500, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [float]);

  const translateY = float.interpolate({ inputRange: [0, 1], outputRange: [0, -5] });

  return (
    <LinearGradient colors={[colors.onboardTop, colors.onboardBottom]} style={styles.root}>
      <View style={styles.body}>
        <View style={styles.hero}>
          <Animated.View style={[styles.heroFrame, { transform: [{ translateY }] }]}>
            <LinearGradient
              colors={[colors.woodLight, colors.woodDark]}
              start={{ x: 0, y: 0 }}
              end={{ x: 0.55, y: 1 }}
              style={StyleSheet.absoluteFill}
            />
            <View style={styles.heroInner}>
              <Image source={room} style={styles.heroImg} resizeMode="cover" />
            </View>
            <View style={[styles.pin, styles.pinOrange]} />
            <View style={[styles.pin, styles.pinGreen]} />
          </Animated.View>
        </View>
        <Text style={styles.title}>大切なモノを、{'\n'}思い出と一緒に。</Text>
        <Text style={styles.desc}>
          子どもの宝物を3Dスキャンして、{'\n'}ちいさなハコニワにのこそう。{'\n'}写真やこえメモも いっしょに。
        </Text>
      </View>
      <View style={styles.footer}>
        <TapScale
          style={styles.cta}
          onPress={() => {
            setOnboarded(true);
            navigation.reset({ index: 0, routes: [{ name: 'Main' }] });
          }}
        >
          <Text style={styles.ctaText}>はじめる</Text>
        </TapScale>
        <TapScale style={styles.sub}>
          <Text style={styles.subText}>すでに アカウントを おもちの方</Text>
        </TapScale>
      </View>
      <View style={{ height: useScreenInsets().bottom }} />
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  body: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
    paddingHorizontal: 34,
  },
  hero: { width: 210, height: 210, marginBottom: 34 },
  heroFrame: {
    ...absoluteFill,
    borderRadius: 34,
    overflow: 'hidden',
    ...shadow(0.32, 44, 24),
  },
  heroInner: {
    position: 'absolute',
    top: 10,
    left: 10,
    right: 10,
    bottom: 10,
    borderRadius: 26,
    overflow: 'hidden',
  },
  heroImg: { width: '100%', height: '100%' },
  pin: {
    position: 'absolute',
    borderRadius: 999,
    backgroundColor: '#fff',
    ...shadow(0.3, 11, 4, 'rgb(74,55,40)'),
  },
  pinOrange: {
    top: '38%',
    left: '32%',
    width: 26,
    height: 26,
    borderWidth: 2.5,
    borderColor: colors.accent,
  },
  pinGreen: {
    top: '26%',
    right: '26%',
    width: 22,
    height: 22,
    borderWidth: 2.5,
    borderColor: colors.green,
  },
  title: {
    fontFamily: fonts.maru900,
    fontSize: 30,
    lineHeight: 30 * 1.25,
    color: colors.textStrong,
    textAlign: 'center',
  },
  desc: {
    fontFamily: fonts.kaku500,
    fontSize: 14,
    lineHeight: 14 * 1.9,
    color: colors.textFaint,
    textAlign: 'center',
    marginTop: 16,
    maxWidth: 280,
  },
  footer: { paddingHorizontal: 28, paddingBottom: 20, gap: 11 },
  cta: {
    backgroundColor: colors.accent,
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    ...shadow(0.34, 22, 10, 'rgb(224,138,99)'),
  },
  ctaText: { fontFamily: fonts.maru700, fontSize: 16, color: '#fff' },
  sub: { alignItems: 'center', padding: 6 },
  subText: { fontFamily: fonts.kaku600, fontSize: 12, color: colors.textFaint2 },
});
