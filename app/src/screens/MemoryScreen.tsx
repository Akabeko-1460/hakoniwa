// 4-4. 思い出をのこす — スキャン直後にモノへ情報を付ける（関連情報の付与）
// 名まえ・写真（image-picker）・こえメモ（実録音）・メモ・だれの/いつ を実装
import React, { useMemo, useState } from 'react';
import {
  Image,
  KeyboardAvoidingView,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../navigation/types';
import { colors, deviceWidth, fonts, shadow, buttonShadow } from '../theme';
import { useStore } from '../store/Store';
import type { Season, VoiceMemo } from '../store/types';
import { useScreenInsets } from '../hooks/useScreenInsets';
import { useVoiceRecorder, useVoicePlayer, formatDuration } from '../features/audio/voice';
import TapScale from '../components/TapScale';
import Placeholder from '../components/Placeholder';
import TurntableViewer from '../components/TurntableViewer';
import { BackIcon, MicIcon, PlayIcon, PlusIcon, WaveformSvg } from '../components/Icons';

type Props = NativeStackScreenProps<RootStackParamList, 'Memory'>;

const SEASONS: Season[] = ['春', '夏', '秋', '冬'];
const NEW_ITEM_TONE = '#7FA6C4'; // 新しいモノはブルーのピン

export default function MemoryScreen({ navigation }: Props) {
  const { top, bottom } = useScreenInsets();
  const store = useStore();
  const { draftFrames, children } = store;

  const [name, setName] = useState('');
  const [memo, setMemo] = useState('');
  const [photos, setPhotos] = useState<string[]>([]);
  const [childId, setChildId] = useState(children[0]?.id ?? '');
  const [year, setYear] = useState(new Date().getFullYear());
  const [season, setSeason] = useState<Season>('冬');
  const [whenOpen, setWhenOpen] = useState(false);
  const [voice, setVoice] = useState<VoiceMemo | null>(null);
  const [saving, setSaving] = useState(false);

  const recorder = useVoiceRecorder();
  const player = useVoicePlayer();

  const child = children.find((c) => c.id === childId) ?? children[0];

  const pickPhotos = async () => {
    const res = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      selectionLimit: 4,
      quality: 0.7,
    });
    if (!res.canceled) {
      setPhotos((p) => [...p, ...res.assets.map((a) => a.uri)].slice(0, 4));
    }
  };

  const onMicPress = async () => {
    if (recorder.recording) {
      const v = await recorder.stop();
      if (v) setVoice(v);
      return;
    }
    if (voice) {
      player.toggle(voice.uri);
      return;
    }
    await recorder.start();
  };

  const micColor = recorder.recording ? colors.accentRec : colors.accent;
  const recLabel = recorder.recording
    ? `● ${formatDuration(recorder.seconds)}`
    : voice
      ? formatDuration(voice.durationSec)
      : 'タップで録音';

  const save = async () => {
    if (saving || !child) return;
    setSaving(true);
    try {
      const item = await store.addItem({
        childId: child.id,
        name: name.trim() || 'たからもの',
        year,
        season,
        memo: memo.trim(),
        frames: draftFrames,
        photos,
        voice,
        tone: NEW_ITEM_TONE,
      });
      store.setDraftFrames([]);
      navigation.reset({
        index: 1,
        routes: [
          { name: 'Main' },
          { name: 'Space', params: { childId: child.id, placeItemId: item.id } },
        ],
      });
    } finally {
      setSaving(false);
    }
  };

  const skip = () => {
    store.setDraftFrames([]);
    navigation.reset({
      index: 1,
      routes: [
        { name: 'Main' },
        { name: 'Space', params: { childId: children[0]?.id ?? '', selectedId: null } },
      ],
    });
  };

  const yearChoices = useMemo(() => {
    const now = new Date().getFullYear();
    const list: number[] = [];
    for (let y = now; y >= now - 12; y--) list.push(y);
    return list;
  }, []);

  return (
    <KeyboardAvoidingView
      style={styles.root}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={[styles.header, { paddingTop: top }]}>
        <TapScale style={styles.backBtn} onPress={() => navigation.goBack()}>
          <BackIcon />
        </TapScale>
        <Text style={styles.headerTitle}>思い出をのこす</Text>
        <TapScale onPress={skip}>
          <Text style={styles.skip}>スキップ</Text>
        </TapScale>
      </View>

      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingHorizontal: 20, paddingTop: 6 }}>
        <View style={styles.previewCard}>
          {draftFrames.length > 0 ? (
            <TurntableViewer frames={draftFrames} style={styles.modelPh} showHint={false} />
          ) : (
            <Placeholder label="3Dモデル" fontSize={8} style={styles.modelPh} />
          )}
          <View style={{ flex: 1 }}>
            <Text style={styles.scannedNote}>
              {draftFrames.length > 0
                ? `スキャンできました！（${draftFrames.length}方向）`
                : 'スキャンできました！'}
            </Text>
            <TextInput
              value={name}
              onChangeText={setName}
              placeholder="たとえば つみき"
              placeholderTextColor={colors.textFaint4}
              style={styles.nameInput}
              selectionColor={colors.accent}
            />
            <Text style={styles.nameHint}>名まえを つけてね</Text>
          </View>
        </View>
        {draftFrames.length > 1 && (
          <Text style={styles.turnHint}>うえのサムネイルを 横にドラッグすると まわせるよ</Text>
        )}

        <Text style={styles.sectionTitle}>写真をそえる</Text>
        <View style={styles.photoRow}>
          {photos.map((uri) => (
            <Image key={uri} source={{ uri }} style={styles.photoPh} />
          ))}
          {photos.length < 4 && (
            <TapScale style={styles.photoAdd} onPress={pickPhotos}>
              <PlusIcon size={20} color={colors.addTint} strokeWidth={2.2} />
              <Text style={styles.photoAddLabel}>ついか</Text>
            </TapScale>
          )}
        </View>

        <Text style={styles.sectionTitle}>こえメモ</Text>
        <View style={styles.voiceCard}>
          <TapScale
            style={[styles.micBtn, { backgroundColor: micColor }]}
            onPress={onMicPress}
          >
            {voice && !recorder.recording ? <PlayIcon size={13} /> : <MicIcon />}
          </TapScale>
          <View style={{ flex: 1 }}>
            <WaveformSvg />
          </View>
          <Text style={styles.recLabel}>{recLabel}</Text>
        </View>
        {voice && !recorder.recording && (
          <TapScale onPress={() => setVoice(null)}>
            <Text style={styles.rerecord}>とり直す</Text>
          </TapScale>
        )}
        {recorder.permissionDenied && (
          <Text style={styles.permissionNote}>マイクの許可が必要です（端末の設定から変更できます）</Text>
        )}

        <Text style={styles.sectionTitle}>おもいで メモ</Text>
        <TextInput
          value={memo}
          onChangeText={setMemo}
          multiline
          placeholder="このモノとの 思い出を のこそう"
          placeholderTextColor={colors.textFaint4}
          style={styles.memoCard}
          selectionColor={colors.accent}
        />

        <View style={styles.whoWhenRow}>
          <View style={{ flex: 1 }}>
            <Text style={styles.fieldLabel}>だれの？</Text>
            <View style={styles.childChips}>
              {children.map((c) => (
                <TapScale
                  key={c.id}
                  style={[styles.fieldBox, childId === c.id && styles.fieldBoxActive]}
                  onPress={() => setChildId(c.id)}
                >
                  <View style={[styles.whoDot, { backgroundColor: c.tone }]} />
                  <Text style={styles.fieldValue}>{c.name}</Text>
                </TapScale>
              ))}
            </View>
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.fieldLabel}>いつ？</Text>
            <TapScale style={styles.fieldBox} onPress={() => setWhenOpen(true)}>
              <Text style={styles.fieldValue}>{year}年 {season}</Text>
            </TapScale>
          </View>
        </View>
        <View style={{ height: 18 }} />
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: Math.max(30, bottom + 4) }]}>
        <TapScale style={[styles.saveBtn, saving && { opacity: 0.6 }]} onPress={save}>
          <Text style={styles.saveText}>{saving ? 'しまっています…' : 'ハコニワに しまう'}</Text>
        </TapScale>
      </View>

      {/* いつ？ピッカー */}
      <Modal visible={whenOpen} transparent animationType="fade" onRequestClose={() => setWhenOpen(false)}>
        <View style={styles.modalBg}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>いつの おもいで？</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.yearRow}>
              {yearChoices.map((y) => (
                <TapScale
                  key={y}
                  style={[styles.yearChip, year === y && styles.chipActive]}
                  onPress={() => setYear(y)}
                >
                  <Text style={[styles.chipText, year === y && styles.chipTextActive]}>{y}</Text>
                </TapScale>
              ))}
            </ScrollView>
            <View style={styles.seasonRow}>
              {SEASONS.map((s) => (
                <TapScale
                  key={s}
                  style={[styles.seasonChip, season === s && styles.chipActive]}
                  onPress={() => setSeason(s)}
                >
                  <Text style={[styles.chipText, season === s && styles.chipTextActive]}>{s}</Text>
                </TapScale>
              ))}
            </View>
            <TapScale style={styles.modalOk} onPress={() => setWhenOpen(false)}>
              <Text style={styles.modalOkText}>これで きめる</Text>
            </TapScale>
          </View>
        </View>
      </Modal>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.cream },
  header: {
    paddingHorizontal: 20,
    paddingBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  backBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: colors.chipBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: { fontFamily: fonts.maru700, fontSize: 16, color: colors.textStrong },
  skip: { fontFamily: fonts.maru700, fontSize: 13, color: colors.textFaint4 },
  previewCard: {
    flexDirection: 'row',
    gap: 13,
    alignItems: 'center',
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 20,
    padding: 12,
    ...shadow(0.08, 16, 6),
  },
  modelPh: { width: 74, height: 74, borderRadius: 15 },
  scannedNote: { fontFamily: fonts.kaku500, fontSize: 10.5, color: colors.textFaint2, marginBottom: 3 },
  turnHint: {
    fontFamily: fonts.kaku500,
    fontSize: 10,
    color: colors.textFaint2,
    marginTop: 6,
    marginLeft: 4,
  },
  nameInput: {
    borderBottomWidth: 1.5,
    borderBottomColor: colors.underline,
    fontFamily: fonts.maru700,
    fontSize: 17,
    color: colors.textStrong,
    paddingTop: 2,
    paddingBottom: 5,
    paddingHorizontal: 0,
  },
  nameHint: { fontFamily: fonts.kaku500, fontSize: 10, color: colors.textFaint4, marginTop: 3 },
  sectionTitle: {
    fontFamily: fonts.maru700,
    fontSize: 12.5,
    color: colors.textStrong,
    marginTop: 20,
    marginBottom: 9,
  },
  photoRow: { flexDirection: 'row', gap: 10, flexWrap: 'wrap' },
  photoPh: { width: 78, height: 78, borderRadius: 15, backgroundColor: '#EFE7D9' },
  photoAdd: {
    width: 78,
    height: 78,
    borderRadius: 15,
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: colors.dashed28,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    backgroundColor: 'rgba(255,255,255,0.4)',
  },
  photoAddLabel: { fontFamily: fonts.kaku600, fontSize: 9, color: colors.addTint },
  voiceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 18,
    paddingVertical: 11,
    paddingHorizontal: 14,
  },
  micBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  recLabel: { fontFamily: fonts.maru700, fontSize: 11, color: colors.textFaint },
  rerecord: {
    fontFamily: fonts.kaku600,
    fontSize: 11,
    color: colors.accentDark,
    marginTop: 6,
    marginLeft: 6,
  },
  permissionNote: {
    fontFamily: fonts.kaku500,
    fontSize: 10.5,
    color: colors.accentRec,
    marginTop: 6,
    marginLeft: 6,
  },
  memoCard: {
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 18,
    paddingVertical: 13,
    paddingHorizontal: 15,
    fontFamily: fonts.kaku500,
    fontSize: 13,
    lineHeight: 13 * 1.7,
    color: colors.textMid,
    minHeight: 78,
    textAlignVertical: 'top',
  },
  whoWhenRow: { flexDirection: 'row', gap: 12, marginTop: 18 },
  fieldLabel: { fontFamily: fonts.kaku600, fontSize: 11, color: colors.textFaint2, marginBottom: 6 },
  childChips: { gap: 7 },
  fieldBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 14,
    paddingVertical: 9,
    paddingHorizontal: 12,
  },
  fieldBoxActive: { borderColor: colors.accent, backgroundColor: colors.accentPale },
  whoDot: { width: 9, height: 9, borderRadius: 5 },
  fieldValue: { fontFamily: fonts.maru700, fontSize: 13, color: colors.textStrong },
  footer: {
    paddingTop: 12,
    paddingHorizontal: 20,
    backgroundColor: '#fff',
    borderTopWidth: 1.5,
    borderTopColor: colors.border10,
  },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: 16,
    padding: 15,
    alignItems: 'center',
    ...buttonShadow,
  },
  saveText: { fontFamily: fonts.maru700, fontSize: 16, color: '#fff' },
  modalBg: {
    flex: 1,
    backgroundColor: 'rgba(74,55,40,0.35)',
    justifyContent: 'flex-end',
  },
  modalCard: {
    // PCブラウザではモーダルが画面の外側に描かれるので、ここで幅を抑える
    width: '100%',
    maxWidth: deviceWidth,
    alignSelf: 'center',
    backgroundColor: '#fff',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 20,
    paddingBottom: 34,
  },
  modalTitle: {
    fontFamily: fonts.maru700,
    fontSize: 15,
    color: colors.textStrong,
    marginBottom: 14,
    textAlign: 'center',
  },
  yearRow: { gap: 8, paddingBottom: 12 },
  yearChip: {
    backgroundColor: colors.chipBg,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 15,
  },
  seasonRow: { flexDirection: 'row', gap: 8, justifyContent: 'center', marginTop: 4 },
  seasonChip: {
    backgroundColor: colors.chipBg,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 20,
  },
  chipActive: { backgroundColor: colors.textStrong },
  chipText: { fontFamily: fonts.maru700, fontSize: 13, color: colors.textMid2 },
  chipTextActive: { color: '#fff' },
  modalOk: {
    marginTop: 18,
    backgroundColor: colors.accent,
    borderRadius: 14,
    padding: 13,
    alignItems: 'center',
  },
  modalOkText: { fontFamily: fonts.maru700, fontSize: 14, color: '#fff' },
});
