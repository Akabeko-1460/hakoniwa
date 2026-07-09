// 4-6. おもいで（タイムライン）— 実データを時系列で一覧・検索・絞り込み
import React, { useMemo, useState } from 'react';
import { ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import type { BottomTabScreenProps } from '@react-navigation/bottom-tabs';
import type { CompositeScreenProps } from '@react-navigation/native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList, TabParamList } from '../navigation/types';
import { colors, fonts, shadow } from '../theme';
import { useStore } from '../store/Store';
import { useScreenInsets } from '../hooks/useScreenInsets';
import TapScale from '../components/TapScale';
import { SearchIcon } from '../components/Icons';

type Props = CompositeScreenProps<
  BottomTabScreenProps<TabParamList, 'Memories'>,
  NativeStackScreenProps<RootStackParamList>
>;

const SEASON_ORDER = { 冬: 3, 秋: 2, 夏: 1, 春: 0 } as const;

export default function MemoriesScreen({ navigation }: Props) {
  const store = useStore();
  const { top } = useScreenInsets();
  const [filter, setFilter] = useState<string>('all');
  const [query, setQuery] = useState('');

  const timeline = useMemo(() => {
    const q = query.trim();
    return [...store.items]
      .filter((it) => (filter === 'all' ? true : it.childId === filter))
      .filter((it) => (q ? it.name.includes(q) || it.memo.includes(q) : true))
      .sort(
        (a, b) =>
          b.year - a.year ||
          SEASON_ORDER[b.season] - SEASON_ORDER[a.season] ||
          b.createdAt - a.createdAt,
      );
  }, [store.items, filter, query]);

  return (
    <View style={styles.root}>
      <View style={[styles.header, { paddingTop: top }]}>
        <Text style={styles.title}>おもいで</Text>
        <Text style={styles.sub}>ぜんぶで {store.items.length}コ ・ 古いものから いまへ</Text>
        <View style={styles.searchBar}>
          <SearchIcon size={17} color={colors.textFaint4} />
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="思い出をさがす"
            placeholderTextColor={colors.textFaint4}
            style={styles.searchInput}
            selectionColor={colors.accent}
          />
        </View>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>
          <TapScale
            style={[styles.chip, filter === 'all' && styles.chipActive]}
            onPress={() => setFilter('all')}
          >
            <Text style={[styles.chipText, filter === 'all' && styles.chipTextActive]}>すべて</Text>
          </TapScale>
          {store.children.map((c) => (
            <TapScale
              key={c.id}
              style={[styles.chip, filter === c.id && styles.chipActive]}
              onPress={() => setFilter(c.id)}
            >
              <Text style={[styles.chipText, filter === c.id && styles.chipTextActive]}>{c.name}</Text>
            </TapScale>
          ))}
        </ScrollView>
      </View>

      <ScrollView style={{ flex: 1 }} contentContainerStyle={styles.timeline}>
        {timeline.length > 1 && <View style={styles.line} />}
        <View style={{ gap: 14 }}>
          {timeline.map((it) => (
            <TapScale
              key={it.id}
              style={styles.row}
              onPress={() =>
                navigation.navigate('Space', { childId: it.childId, selectedId: it.id })
              }
            >
              <View style={styles.dotCol}>
                <View style={[styles.dot, { backgroundColor: it.tone }]} />
                <Text style={styles.year}>{it.year}</Text>
              </View>
              <View style={styles.card}>
                <View style={styles.cardTitleRow}>
                  <Text style={styles.cardName}>{it.name}</Text>
                  <Text style={styles.childBadge}>
                    {store.childById(it.childId)?.name ?? '？'}
                  </Text>
                </View>
                <Text style={styles.cardMemo} numberOfLines={2}>
                  {it.memo || `${it.year}年${it.season}の おもいで`}
                </Text>
              </View>
            </TapScale>
          ))}
          {timeline.length === 0 && (
            <Text style={styles.emptyText}>みつかりませんでした</Text>
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.cream },
  header: { paddingHorizontal: 20, paddingBottom: 6 },
  title: { fontFamily: fonts.maru900, fontSize: 24, color: colors.textStrong },
  sub: { fontFamily: fonts.kaku500, fontSize: 11, color: colors.textFaint2, marginTop: 2 },
  searchBar: {
    marginTop: 13,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 14,
    paddingVertical: 4,
    paddingHorizontal: 13,
  },
  searchInput: {
    flex: 1,
    fontFamily: fonts.kaku500,
    fontSize: 12.5,
    color: colors.textStrong,
    paddingVertical: 6,
  },
  chips: { flexDirection: 'row', gap: 8, marginTop: 12, paddingRight: 8 },
  chip: {
    backgroundColor: colors.chipBg,
    paddingVertical: 5,
    paddingHorizontal: 14,
    borderRadius: 999,
  },
  chipActive: { backgroundColor: colors.textStrong },
  chipText: { fontFamily: fonts.maru700, fontSize: 11.5, color: colors.textMid2 },
  chipTextActive: { color: '#fff' },
  timeline: {
    paddingTop: 16,
    paddingHorizontal: 20,
    paddingBottom: 20,
    position: 'relative',
  },
  line: {
    position: 'absolute',
    left: 33,
    top: 16,
    bottom: 20,
    width: 2,
    backgroundColor: colors.underline,
  },
  row: { flexDirection: 'row', gap: 14, alignItems: 'flex-start' },
  dotCol: { width: 28, alignItems: 'center', zIndex: 1 },
  dot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    marginTop: 6,
    borderWidth: 3,
    borderColor: colors.cream,
  },
  year: { fontFamily: fonts.maru700, fontSize: 10, color: colors.textFaint2, marginTop: 4 },
  card: {
    flex: 1,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border12,
    borderRadius: 18,
    paddingVertical: 11,
    paddingHorizontal: 13,
    ...shadow(0.07, 14, 6),
  },
  cardTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  cardName: { fontFamily: fonts.maru700, fontSize: 14, color: colors.textStrong, flexShrink: 1 },
  childBadge: {
    fontFamily: fonts.kaku600,
    fontSize: 9.5,
    color: colors.textMid2,
    backgroundColor: colors.chipBg,
    paddingHorizontal: 7,
    paddingVertical: 1,
    borderRadius: 999,
    overflow: 'hidden',
  },
  cardMemo: {
    fontFamily: fonts.kaku500,
    fontSize: 11,
    lineHeight: 11 * 1.5,
    color: colors.textFaint,
    marginTop: 4,
  },
  emptyText: {
    textAlign: 'center',
    fontFamily: fonts.kaku500,
    fontSize: 12,
    color: colors.textFaint2,
    paddingVertical: 30,
  },
});
