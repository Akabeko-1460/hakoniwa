// 4-7. せってい — プロフィール・家族・アプリ設定（実データ）
import React, { useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import type { BottomTabScreenProps } from '@react-navigation/bottom-tabs';
import type { CompositeScreenProps } from '@react-navigation/native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList, TabParamList } from '../navigation/types';
import { colors, fonts, shadow } from '../theme';
import { useStore } from '../store/Store';
import { useScreenInsets } from '../hooks/useScreenInsets';
import TapScale from '../components/TapScale';
import Placeholder from '../components/Placeholder';
import AddChildModal from '../components/AddChildModal';
import { ChevronRightIcon } from '../components/Icons';

type Props = CompositeScreenProps<
  BottomTabScreenProps<TabParamList, 'Settings'>,
  NativeStackScreenProps<RootStackParamList>
>;

function Toggle({ on, onToggle }: { on: boolean; onToggle: () => void }) {
  return (
    <TapScale
      style={[styles.toggle, { backgroundColor: on ? colors.green : colors.toggleOff }]}
      onPress={onToggle}
    >
      <View style={[styles.toggleKnob, on ? { right: 2 } : { left: 2 }]} />
    </TapScale>
  );
}

export default function SettingsScreen({ navigation }: Props) {
  const store = useStore();
  const { top } = useScreenInsets();
  const [addOpen, setAddOpen] = useState(false);
  const { settings } = store;

  return (
    <View style={styles.root}>
      <View style={{ paddingTop: top, paddingHorizontal: 20, paddingBottom: 8 }}>
        <Text style={styles.title}>せってい</Text>
      </View>
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingTop: 8, paddingHorizontal: 20, paddingBottom: 20 }}
      >
        <TapScale style={styles.profileCard}>
          <Placeholder label="似顔" fontSize={8} style={styles.profileAvatar} />
          <View style={{ flex: 1 }}>
            <Text style={styles.profileName}>ゆい</Text>
            <Text style={styles.profileEmail}>yui@example.com</Text>
          </View>
          <ChevronRightIcon />
        </TapScale>

        <Text style={styles.sectionLabel}>かぞく</Text>
        <View style={styles.card}>
          {store.children.map((c) => (
            <View key={c.id} style={[styles.row, styles.rowBorder]}>
              <View style={[styles.childDot, { backgroundColor: c.tone }]} />
              <Text style={styles.childName}>{c.name}</Text>
              <Text style={styles.childAge}>
                {c.age !== null ? `${c.age}さい` : `${store.itemsOf(c.id).length}コ`}
              </Text>
            </View>
          ))}
          <TapScale style={styles.row} onPress={() => setAddOpen(true)}>
            <View style={styles.addCircle}>
              <Text style={styles.addPlus}>＋</Text>
            </View>
            <Text style={styles.addLabel}>子どもを ついか</Text>
          </TapScale>
        </View>

        <Text style={styles.sectionLabel}>アプリ</Text>
        <View style={styles.card}>
          <TapScale
            style={[styles.row, styles.rowBorder]}
            onPress={() =>
              store.updateSettings({ scanTarget: settings.scanTarget === 20 ? 12 : 20 })
            }
          >
            <Text style={styles.settingLabel}>スキャンの画質</Text>
            <Text style={styles.settingValue}>
              {settings.scanTarget === 20 ? 'たかい（20方向）' : 'ふつう（12方向）'} ›
            </Text>
          </TapScale>
          <View style={[styles.row, styles.rowBorder]}>
            <Text style={styles.settingLabel}>バックアップ</Text>
            <Toggle
              on={settings.backup}
              onToggle={() => store.updateSettings({ backup: !settings.backup })}
            />
          </View>
          <View style={styles.row}>
            <Text style={styles.settingLabel}>おもいで通知</Text>
            <Toggle
              on={settings.notify}
              onToggle={() => store.updateSettings({ notify: !settings.notify })}
            />
          </View>
        </View>

        <TapScale style={styles.onboardLink} onPress={() => navigation.navigate('Onboard')}>
          <Text style={styles.onboardLinkText}>オンボーディングを もう一度みる</Text>
        </TapScale>
      </ScrollView>

      <AddChildModal
        visible={addOpen}
        onClose={() => setAddOpen(false)}
        onCreate={(name, age, tone) => {
          const child = store.addChild(name, age, tone);
          setAddOpen(false);
          navigation.navigate('Space', { childId: child.id, selectedId: null });
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.cream },
  title: { fontFamily: fonts.maru900, fontSize: 24, color: colors.textStrong },
  profileCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 20,
    padding: 14,
    ...shadow(0.08, 16, 6),
  },
  profileAvatar: { width: 54, height: 54, borderRadius: 27 },
  profileName: { fontFamily: fonts.maru700, fontSize: 16, color: colors.textStrong },
  profileEmail: { fontFamily: fonts.kaku500, fontSize: 11, color: colors.textFaint2, marginTop: 2 },
  sectionLabel: {
    fontFamily: fonts.maru700,
    fontSize: 12,
    color: colors.textFaint2,
    marginTop: 22,
    marginBottom: 9,
    marginHorizontal: 6,
  },
  card: {
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border12,
    borderRadius: 18,
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 11,
    paddingVertical: 13,
    paddingHorizontal: 15,
  },
  rowBorder: { borderBottomWidth: 1, borderBottomColor: colors.divider },
  childDot: { width: 11, height: 11, borderRadius: 6 },
  childName: { flex: 1, fontFamily: fonts.maru700, fontSize: 14, color: colors.textStrong },
  childAge: { fontFamily: fonts.kaku500, fontSize: 11, color: colors.textFaint2 },
  addCircle: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: colors.accentPale,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addPlus: { fontFamily: fonts.maru700, fontSize: 15, color: colors.accent, lineHeight: 18 },
  addLabel: { fontFamily: fonts.maru700, fontSize: 13, color: colors.accent },
  settingLabel: { flex: 1, fontFamily: fonts.kaku600, fontSize: 13, color: colors.textMid },
  settingValue: { fontFamily: fonts.kaku600, fontSize: 12, color: colors.textFaint2 },
  toggle: { width: 42, height: 25, borderRadius: 999 },
  toggleKnob: {
    position: 'absolute',
    top: 2,
    width: 21,
    height: 21,
    borderRadius: 11,
    backgroundColor: '#fff',
  },
  onboardLink: { alignItems: 'center', padding: 20 },
  onboardLinkText: { fontFamily: fonts.maru700, fontSize: 13, color: colors.accentDark },
});
