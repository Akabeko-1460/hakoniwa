// 4-2. ホーム — 家族のハコニワ一覧と最近の思い出、スキャン導線（実データ）
import React, { useState } from 'react';
import { Image, ScrollView, StyleSheet, Text, View } from 'react-native';
import type { BottomTabScreenProps } from '@react-navigation/bottom-tabs';
import type { CompositeScreenProps } from '@react-navigation/native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList, TabParamList } from '../navigation/types';
import { absoluteFill, colors, fonts, cardShadow } from '../theme';
import { useStore } from '../store/Store';
import { useScreenInsets } from '../hooks/useScreenInsets';
import TapScale from '../components/TapScale';
import Placeholder from '../components/Placeholder';
import AddChildModal from '../components/AddChildModal';
import { PlusIcon } from '../components/Icons';

const room = require('../../assets/room-sample.png');

type Props = CompositeScreenProps<
  BottomTabScreenProps<TabParamList, 'Home'>,
  NativeStackScreenProps<RootStackParamList>
>;

function hexToRgba(hex: string, alpha: number): string {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${alpha})`;
}

export default function HomeScreen({ navigation }: Props) {
  const store = useStore();
  const { top } = useScreenInsets();
  const [addOpen, setAddOpen] = useState(false);

  const recent = [...store.items]
    .sort((a, b) => b.createdAt - a.createdAt)
    .slice(0, 3);

  return (
    <View style={styles.root}>
      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingTop: top, paddingHorizontal: 20 }}>
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.hello}>こんにちは、ゆいさん</Text>
            <Text style={styles.logo}>ハコニワ</Text>
          </View>
          <View style={styles.avatar}>
            <Placeholder label="似顔" fontSize={8} style={styles.avatarPh} />
          </View>
        </View>
        <Text style={styles.tagline}>大切なモノを、思い出と一緒に。</Text>

        <View style={styles.grid}>
          {store.children.map((c) => {
            const count = store.itemsOf(c.id).length;
            return (
              <TapScale
                key={c.id}
                style={styles.familyCard}
                onPress={() => navigation.navigate('Space', { childId: c.id, selectedId: null })}
              >
                <View style={styles.familyImgBox}>
                  <Image source={room} style={styles.familyImg} resizeMode="cover" />
                  <View
                    style={[styles.familyTint, { backgroundColor: hexToRgba(c.tone, 0.16) }]}
                    pointerEvents="none"
                  />
                </View>
                <View style={styles.familyBody}>
                  <Text style={styles.familyName}>{c.name}</Text>
                  <View style={styles.familyMeta}>
                    <Text
                      style={[
                        styles.countBadge,
                        { color: c.tone, backgroundColor: hexToRgba(c.tone, 0.14) },
                      ]}
                    >
                      {count}コ
                    </Text>
                    {c.age !== null && <Text style={styles.age}>{c.age}さい</Text>}
                  </View>
                </View>
              </TapScale>
            );
          })}
        </View>

        <TapScale style={styles.newCard} onPress={() => setAddOpen(true)}>
          <View style={styles.newPlus}>
            <PlusIcon size={20} strokeWidth={2.4} />
          </View>
          <View>
            <Text style={styles.newTitle}>あたらしい ハコニワ</Text>
            <Text style={styles.newSub}>家族のおへや（3D空間）を つくる</Text>
          </View>
        </TapScale>

        {recent.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>さいきん ふえた思い出</Text>
            <View style={styles.recentRow}>
              {recent.map((it) => {
                const thumb = it.frames[0] ?? it.photos[0] ?? null;
                return (
                  <TapScale
                    key={it.id}
                    style={styles.recentCard}
                    onPress={() =>
                      navigation.navigate('Space', { childId: it.childId, selectedId: it.id })
                    }
                  >
                    {thumb ? (
                      <Image source={{ uri: thumb }} style={styles.recentPh} />
                    ) : (
                      <Placeholder label={it.name} fontSize={8} style={styles.recentPh} />
                    )}
                    <Text style={styles.recentLabel} numberOfLines={1}>{it.name}</Text>
                  </TapScale>
                );
              })}
            </View>
          </>
        )}
        <View style={{ height: 20 }} />
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
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  hello: { fontFamily: fonts.kaku500, fontSize: 12, color: colors.textFaint2 },
  logo: {
    fontFamily: fonts.maru900,
    fontSize: 27,
    lineHeight: 27 * 1.1,
    color: colors.textStrong,
    marginTop: 3,
  },
  avatar: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: colors.chipBg,
    overflow: 'hidden',
  },
  avatarPh: { width: 42, height: 42, borderRadius: 21 },
  tagline: {
    fontFamily: fonts.kaku500,
    fontSize: 13,
    lineHeight: 13 * 1.5,
    color: colors.textFaint,
    marginBottom: 20,
  },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 14 },
  familyCard: {
    width: '47%',
    flexGrow: 1,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 22,
    overflow: 'hidden',
    ...cardShadow,
  },
  familyImgBox: { height: 118, backgroundColor: '#EFE7D9' },
  familyImg: { width: '100%', height: '100%' },
  familyTint: { ...absoluteFill },
  familyBody: { paddingTop: 11, paddingHorizontal: 13, paddingBottom: 13 },
  familyName: { fontFamily: fonts.maru700, fontSize: 15, color: colors.textStrong },
  familyMeta: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 5 },
  countBadge: {
    fontFamily: fonts.kaku600,
    fontSize: 11,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 999,
    overflow: 'hidden',
  },
  age: { fontFamily: fonts.kaku500, fontSize: 11, color: colors.textFaint2 },
  newCard: {
    marginTop: 14,
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: colors.dashed28,
    borderRadius: 22,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 13,
    backgroundColor: 'rgba(255,255,255,0.4)',
  },
  newPlus: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  newTitle: { fontFamily: fonts.maru700, fontSize: 14, color: colors.textStrong },
  newSub: { fontFamily: fonts.kaku500, fontSize: 11, color: colors.textFaint2, marginTop: 2 },
  sectionTitle: {
    fontFamily: fonts.maru700,
    fontSize: 13,
    color: colors.textStrong,
    marginTop: 22,
    marginBottom: 11,
  },
  recentRow: { flexDirection: 'row', gap: 11 },
  recentCard: {
    flex: 1,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border12,
    borderRadius: 16,
    overflow: 'hidden',
  },
  recentPh: { height: 66, width: '100%' },
  recentLabel: {
    paddingVertical: 7,
    paddingHorizontal: 9,
    fontFamily: fonts.kaku600,
    fontSize: 11,
    color: colors.textMid,
  },
});
