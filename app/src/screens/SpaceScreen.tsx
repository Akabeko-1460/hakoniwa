// 4-5. ハコニワ空間（★中心画面）— three.js のリアルタイム3Dルーム
// ドラッグで回転 / ピンをタップで情報シート / 配置モードで床タップ配置
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Image, Modal, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../navigation/types';
import { colors, fonts, shadow, frameShadow } from '../theme';
import { useStore } from '../store/Store';
import type { RoomPos } from '../store/types';
import { useScreenInsets } from '../hooks/useScreenInsets';
import { useVoicePlayer, formatDuration } from '../features/audio/voice';
import TapScale from '../components/TapScale';
import Placeholder from '../components/Placeholder';
import TurntableViewer from '../components/TurntableViewer';
import Room3D, { Room3DHandle } from '../three/Room3D';
import { BackIcon, CheckIcon, CloseIcon, PlayIcon, ReloadIcon, ShareIcon } from '../components/Icons';

type Props = NativeStackScreenProps<RootStackParamList, 'Space'>;

export default function SpaceScreen({ navigation, route }: Props) {
  const { childId, selectedId: paramSelected, placeItemId } = route.params;
  const store = useStore();
  const { top, bottom } = useScreenInsets();
  const roomRef = useRef<Room3DHandle>(null);

  const child = store.childById(childId);
  const items = store.itemsOf(childId);
  const placedItems = items.filter((it) => it.pos !== null);

  const [selectedId, setSelectedId] = useState<string | null>(paramSelected ?? null);
  const [placing, setPlacing] = useState<string | null>(placeItemId ?? null);
  const [viewerOpen, setViewerOpen] = useState(false);
  const player = useVoicePlayer();

  useEffect(() => {
    setSelectedId(paramSelected ?? null);
    setPlacing(placeItemId ?? null);
  }, [paramSelected, placeItemId, childId]);

  const sel = selectedId ? items.find((it) => it.id === selectedId) : null;
  const placingItem = placing ? store.items.find((it) => it.id === placing) : null;

  const roomItems = useMemo(
    () =>
      placedItems.map((it) => ({
        id: it.id,
        tone: it.tone,
        pos: it.pos as RoomPos,
      })),
    [placedItems],
  );

  const place = (pos: RoomPos) => {
    if (!placing) return;
    store.placeItem(placing, pos);
    setSelectedId(placing);
    setPlacing(null);
  };

  const autoPlace = () => {
    // おまかせ配置: ほかのピンから離れた場所をさがす
    if (!placing) return;
    let best: RoomPos = { x: 0.1, z: 0.3 };
    let bestDist = -1;
    for (let i = 0; i < 24; i++) {
      const cand = { x: Math.random() * 1.6 - 0.8, z: Math.random() * 1.4 - 0.6 };
      const d = Math.min(
        ...placedItems.map((it) => Math.hypot(cand.x - it.pos!.x, cand.z - it.pos!.z)),
        2,
      );
      if (d > bestDist) {
        bestDist = d;
        best = cand;
      }
    }
    place(best);
  };

  if (!child) {
    return <View style={styles.root} />;
  }

  const count = items.length;
  const justAdded = store.lastAddedId !== null && items.some((it) => it.id === store.lastAddedId);
  const thumb = sel ? (sel.frames[0] ?? sel.photos[0] ?? null) : null;

  return (
    <View style={styles.root}>
      <LinearGradient
        colors={[colors.spaceGradTop, colors.spaceBg]}
        style={styles.topGrad}
        pointerEvents="none"
      />

      <View style={[styles.header, { paddingTop: top }]}>
        <TapScale testID="space-back" style={styles.headerBtn} onPress={() => navigation.popTo('Main')}>
          <BackIcon />
        </TapScale>
        <View style={{ alignItems: 'center' }}>
          <Text style={styles.title}>{child.name}の ハコニワ</Text>
          <Text style={styles.sub}>{count}コの思い出</Text>
        </View>
        <TapScale style={styles.headerBtn}>
          <ShareIcon />
        </TapScale>
      </View>

      {placing && placingItem ? (
        <View style={[styles.addedBand, styles.placeBand]}>
          <Text style={styles.placeBandText}>
            「{placingItem.name}」を おく場所を タップしてね
          </Text>
          <TapScale style={styles.autoBtn} onPress={autoPlace}>
            <Text style={styles.autoBtnText}>おまかせ</Text>
          </TapScale>
        </View>
      ) : justAdded ? (
        <View style={styles.addedBand}>
          <View style={styles.addedCheck}>
            <CheckIcon size={12} color="#fff" strokeWidth={3} />
          </View>
          <Text style={styles.addedText}>
            ハコニワに「{store.items.find((i) => i.id === store.lastAddedId)?.name ?? ''}」をおきました
          </Text>
        </View>
      ) : null}

      <View style={styles.roomArea}>
        <View style={styles.woodFrame}>
          <LinearGradient
            colors={[colors.woodLight, colors.woodDark]}
            start={{ x: 0, y: 0 }}
            end={{ x: 0.55, y: 1 }}
            style={[StyleSheet.absoluteFill, { borderRadius: 24 }]}
          />
          <View style={styles.roomClip}>
            <Room3D
              key={childId}
              ref={roomRef}
              items={roomItems}
              selectedId={selectedId}
              childTone={child.tone}
              placeMode={placing !== null}
              popItemId={store.lastAddedId}
              onSelect={(id) => setSelectedId(id)}
              onPlace={place}
              style={styles.room}
            />
          </View>
          <View style={styles.countBadge} pointerEvents="none">
            <Text style={styles.countBadgeText}>{count}コの思い出</Text>
          </View>
          <View style={styles.roomBtns}>
            <TapScale style={styles.roomBtn} onPress={() => roomRef.current?.resetCamera()}>
              <ReloadIcon size={19} strokeWidth={2} />
            </TapScale>
            <TapScale style={styles.roomBtnAdd} onPress={() => navigation.navigate('Scan')}>
              <Text style={styles.roomBtnAddText}>＋</Text>
            </TapScale>
          </View>
        </View>
      </View>

      <Text style={styles.caption}>
        {placing
          ? 'お部屋の ゆかを タップしてね'
          : 'ドラッグでまわす ・ モノをタップすると 思い出がひらきます'}
      </Text>

      {sel ? (
        <View style={[styles.sheet, { marginBottom: Math.max(24, bottom) }]}>
          <View style={styles.sheetHandle} />
          <TapScale style={styles.sheetClose} onPress={() => setSelectedId(null)}>
            <CloseIcon />
          </TapScale>
          <View style={styles.sheetRow}>
            <TapScale
              onPress={() => sel.frames.length > 1 && setViewerOpen(true)}
              style={styles.sheetPhotoWrap}
            >
              {thumb ? (
                <Image source={{ uri: thumb }} style={styles.sheetPhoto} />
              ) : (
                <Placeholder label={`${sel.name}\nの写真`} fontSize={8} style={styles.sheetPhoto} />
              )}
              {sel.frames.length > 1 && (
                <View style={styles.badge3d}>
                  <Text style={styles.badge3dText}>3D</Text>
                </View>
              )}
            </TapScale>
            <View style={{ flex: 1, minWidth: 0 }}>
              <View style={styles.sheetTitleRow}>
                <Text style={styles.sheetName} numberOfLines={1}>{sel.name}</Text>
                <Text style={styles.sheetDate}>{sel.year}年 {sel.season}</Text>
              </View>
              <Text style={styles.sheetMemo} numberOfLines={3}>
                {sel.memo || 'まだ メモがありません'}
              </Text>
              <View style={styles.sheetActions}>
                {sel.voice && (
                  <TapScale style={styles.voiceChip} onPress={() => player.toggle(sel.voice!.uri)}>
                    <View style={styles.voicePlay}>
                      <PlayIcon />
                    </View>
                    <Text style={styles.voiceChipText}>
                      {player.playingUri === sel.voice.uri
                        ? '再生中…'
                        : `こえメモ ${formatDuration(sel.voice.durationSec)}`}
                    </Text>
                  </TapScale>
                )}
                <Text style={styles.photoCount}>
                  写真 {sel.photos.length + sel.frames.length > 0 ? sel.photos.length || sel.frames.length : 0}まい
                </Text>
              </View>
            </View>
          </View>
        </View>
      ) : (
        <View style={[styles.emptyWrap, { paddingBottom: Math.max(30, bottom + 4) }]}>
          <TapScale style={styles.scanMore} onPress={() => navigation.navigate('Scan')}>
            <Text style={styles.scanMoreText}>＋ スキャンして モノをふやす</Text>
          </TapScale>
        </View>
      )}

      {/* ターンテーブル3Dビューワー（フルスクリーン） */}
      <Modal
        visible={viewerOpen}
        transparent
        animationType="fade"
        onRequestClose={() => setViewerOpen(false)}
      >
        <View style={styles.viewerBg}>
          <Text style={styles.viewerTitle}>{sel?.name}</Text>
          <TurntableViewer frames={sel?.frames ?? []} style={styles.viewerBox} showHint />
          <TapScale style={styles.viewerClose} onPress={() => setViewerOpen(false)}>
            <Text style={styles.viewerCloseText}>とじる</Text>
          </TapScale>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.spaceBg },
  topGrad: { position: 'absolute', top: 0, left: 0, right: 0, height: '56%' },
  header: {
    paddingHorizontal: 20,
    paddingBottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: 'rgba(255,255,255,0.75)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: { fontFamily: fonts.maru900, fontSize: 17, color: colors.textStrong },
  sub: { fontFamily: fonts.kaku500, fontSize: 10.5, color: colors.textFaint2 },
  addedBand: {
    marginHorizontal: 20,
    marginBottom: 4,
    backgroundColor: colors.greenPale,
    borderWidth: 1.5,
    borderColor: colors.greenBorder,
    borderRadius: 14,
    paddingVertical: 9,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
  },
  placeBand: {
    backgroundColor: colors.accentPale,
    borderColor: '#F2CDB6',
    justifyContent: 'space-between',
  },
  placeBandText: {
    flex: 1,
    fontFamily: fonts.maru700,
    fontSize: 12,
    color: colors.accentDark,
  },
  autoBtn: {
    backgroundColor: colors.accent,
    borderRadius: 999,
    paddingVertical: 5,
    paddingHorizontal: 12,
  },
  autoBtnText: { fontFamily: fonts.maru700, fontSize: 11, color: '#fff' },
  addedCheck: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: colors.green,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addedText: { flex: 1, fontFamily: fonts.maru700, fontSize: 12, color: colors.greenDark },
  roomArea: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 18,
    paddingTop: 6,
  },
  woodFrame: {
    width: '100%',
    borderRadius: 24,
    padding: 11,
    ...frameShadow,
  },
  roomClip: { borderRadius: 15, overflow: 'hidden' },
  room: { width: '100%', height: 330 },
  countBadge: {
    position: 'absolute',
    top: 20,
    left: 22,
    backgroundColor: 'rgba(74,55,40,0.82)',
    paddingVertical: 4,
    paddingHorizontal: 11,
    borderRadius: 999,
  },
  countBadgeText: { fontFamily: fonts.maru700, fontSize: 11, color: '#fff' },
  roomBtns: { position: 'absolute', top: 20, right: 22, gap: 8 },
  roomBtn: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.9)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  roomBtnAdd: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    ...shadow(0.4, 12, 5, 'rgb(224,138,99)'),
  },
  roomBtnAddText: { fontFamily: fonts.maru700, fontSize: 19, color: '#fff', lineHeight: 24 },
  caption: {
    textAlign: 'center',
    fontFamily: fonts.kaku600,
    fontSize: 11,
    color: colors.textFaint2,
    paddingTop: 12,
    paddingBottom: 2,
    paddingHorizontal: 20,
  },
  sheet: {
    marginTop: 6,
    marginHorizontal: 14,
    backgroundColor: '#fff',
    borderRadius: 24,
    padding: 14,
    borderWidth: 1.5,
    borderColor: colors.border10,
    ...shadow(0.16, 26, -2, 'rgb(74,55,40)', 8),
  },
  sheetHandle: {
    width: 38,
    height: 4,
    borderRadius: 999,
    backgroundColor: colors.knob,
    alignSelf: 'center',
    marginTop: -4,
    marginBottom: 12,
  },
  sheetClose: {
    position: 'absolute',
    top: 14,
    right: 14,
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: colors.spaceBg,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2,
  },
  sheetRow: { flexDirection: 'row', gap: 13 },
  sheetPhotoWrap: { width: 82, height: 82 },
  sheetPhoto: { width: 82, height: 82, borderRadius: 16 },
  badge3d: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    backgroundColor: 'rgba(74,55,40,0.82)',
    borderRadius: 999,
    paddingVertical: 1,
    paddingHorizontal: 7,
  },
  badge3dText: { fontFamily: fonts.maru700, fontSize: 9, color: '#fff' },
  sheetTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  sheetName: {
    fontFamily: fonts.maru700,
    fontSize: 16,
    color: colors.textStrong,
    flexShrink: 1,
  },
  sheetDate: {
    fontFamily: fonts.kaku600,
    fontSize: 10,
    color: colors.accent,
    backgroundColor: colors.accentPale,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 999,
    overflow: 'hidden',
  },
  sheetMemo: {
    fontFamily: fonts.kaku500,
    fontSize: 11.5,
    lineHeight: 11.5 * 1.55,
    color: colors.textMid2,
    marginTop: 5,
  },
  sheetActions: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 9 },
  voiceChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    backgroundColor: colors.accentPale,
    borderRadius: 999,
    paddingVertical: 5,
    paddingRight: 12,
    paddingLeft: 8,
  },
  voicePlay: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  voiceChipText: { fontFamily: fonts.maru700, fontSize: 11, color: colors.accentDark },
  photoCount: { fontFamily: fonts.kaku600, fontSize: 11, color: colors.textFaint3 },
  emptyWrap: { paddingHorizontal: 20, paddingTop: 6 },
  scanMore: {
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border16,
    borderRadius: 16,
    padding: 13,
    alignItems: 'center',
    ...shadow(0.08, 16, 6),
  },
  scanMoreText: { fontFamily: fonts.maru700, fontSize: 14, color: colors.accentDark },
  viewerBg: {
    flex: 1,
    backgroundColor: 'rgba(30,22,16,0.92)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  viewerTitle: { fontFamily: fonts.maru700, fontSize: 17, color: '#fff', marginBottom: 14 },
  viewerBox: { width: '100%', aspectRatio: 3 / 4, borderRadius: 20 },
  viewerClose: {
    marginTop: 18,
    backgroundColor: 'rgba(255,255,255,0.16)',
    borderRadius: 999,
    paddingVertical: 9,
    paddingHorizontal: 26,
  },
  viewerCloseText: { fontFamily: fonts.maru700, fontSize: 13, color: '#fff' },
});
