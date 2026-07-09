// 下部タブナビ（README セクション5）
// 5項目: ホーム / さがす(→memories) / のこす(→scan・中央丸) / おもいで(→memories) / せってい
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { colors, fonts, shadow } from '../theme';
import TapScale from './TapScale';
import { GearIcon, HeartIcon, HomeIcon, PlusIcon, SearchIcon } from './Icons';

export default function BottomNav({ state, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const active = state.routes[state.index].name; // 'Home' | 'Memories' | 'Settings'
  const on = colors.accent;
  const off = colors.textFaint3;

  const goScan = () => navigation.getParent()?.navigate('Scan' as never);

  return (
    <View style={[styles.bar, { paddingBottom: Math.max(26, insets.bottom + 9) }]}>
      <TapScale style={styles.item} onPress={() => navigation.navigate('Home')}>
        <HomeIcon color={active === 'Home' ? on : off} filled={active === 'Home'} />
        <Text style={[styles.label, active === 'Home' ? styles.labelOn : styles.labelOff]}>ホーム</Text>
      </TapScale>
      <TapScale style={styles.item} onPress={() => navigation.navigate('Memories')}>
        <SearchIcon color={active === 'Memories' ? on : off} />
        <Text style={[styles.label, active === 'Memories' ? styles.labelOn : styles.labelOff]}>さがす</Text>
      </TapScale>
      <TapScale style={[styles.item, styles.centerItem]} onPress={goScan}>
        <View style={styles.centerCircle}>
          <PlusIcon size={24} strokeWidth={2.6} />
        </View>
        <Text style={[styles.label, styles.labelBold, { color: active === 'Home' ? on : off }]}>のこす</Text>
      </TapScale>
      <TapScale style={styles.item} onPress={() => navigation.navigate('Memories')}>
        <HeartIcon color={active === 'Memories' ? on : off} filled={active === 'Memories'} />
        <Text style={[styles.label, active === 'Memories' ? styles.labelOn : styles.labelOff]}>おもいで</Text>
      </TapScale>
      <TapScale style={styles.item} onPress={() => navigation.navigate('Settings')}>
        <GearIcon color={active === 'Settings' ? on : off} />
        <Text style={[styles.label, active === 'Settings' ? styles.labelOn : styles.labelOff]}>せってい</Text>
      </TapScale>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-around',
    backgroundColor: '#fff',
    borderTopWidth: 1.5,
    borderTopColor: colors.border10,
    paddingTop: 9,
    paddingHorizontal: 8,
  },
  item: {
    flex: 1,
    alignItems: 'center',
    gap: 3,
  },
  centerItem: {
    marginTop: -14,
    gap: 4,
  },
  centerCircle: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    ...shadow(0.4, 14, 6, 'rgb(224,138,99)'),
  },
  label: {
    fontSize: 9.5,
  },
  labelOn: {
    color: colors.accent,
    fontFamily: fonts.kaku700,
  },
  labelOff: {
    color: colors.textFaint3,
    fontFamily: fonts.kaku600,
  },
  labelBold: {
    fontFamily: fonts.kaku700,
  },
});
