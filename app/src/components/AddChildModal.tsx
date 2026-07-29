// あたらしい ハコニワ（子ども）をつくる — 3D空間の生成につながる入口
import React, { useState } from 'react';
import { Modal, StyleSheet, Text, TextInput, View } from 'react-native';
import { colors, deviceWidth, fonts } from '../theme';
import { TONES } from '../store/types';
import TapScale from './TapScale';

interface Props {
  visible: boolean;
  onClose: () => void;
  onCreate: (name: string, age: number | null, tone: string) => void;
}

export default function AddChildModal({ visible, onClose, onCreate }: Props) {
  const [name, setName] = useState('');
  const [age, setAge] = useState('');
  const [tone, setTone] = useState<string>(TONES[0]);

  const create = () => {
    const n = name.trim();
    if (!n) return;
    const a = parseInt(age, 10);
    onCreate(n, Number.isFinite(a) ? a : null, tone);
    setName('');
    setAge('');
    setTone(TONES[0]);
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.bg}>
        <View style={styles.card}>
          <Text style={styles.title}>あたらしい ハコニワ</Text>
          <Text style={styles.sub}>お部屋（3D空間）が じどうで つくられます</Text>

          <Text style={styles.label}>おなまえ</Text>
          <TextInput
            value={name}
            onChangeText={setName}
            placeholder="たとえば はると"
            placeholderTextColor={colors.textFaint4}
            style={styles.input}
            selectionColor={colors.accent}
          />

          <Text style={styles.label}>ねんれい</Text>
          <TextInput
            value={age}
            onChangeText={setAge}
            placeholder="たとえば 4"
            placeholderTextColor={colors.textFaint4}
            keyboardType="number-pad"
            style={styles.input}
            selectionColor={colors.accent}
          />

          <Text style={styles.label}>お部屋のいろ</Text>
          <View style={styles.tones}>
            {TONES.map((t) => (
              <TapScale
                key={t}
                style={[
                  styles.toneDot,
                  { backgroundColor: t },
                  tone === t && styles.toneDotActive,
                ]}
                onPress={() => setTone(t)}
              />
            ))}
          </View>

          <TapScale
            style={[styles.create, !name.trim() && { opacity: 0.45 }]}
            onPress={create}
          >
            <Text style={styles.createText}>ハコニワを つくる</Text>
          </TapScale>
          <TapScale style={styles.cancel} onPress={onClose}>
            <Text style={styles.cancelText}>やめる</Text>
          </TapScale>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  bg: {
    flex: 1,
    backgroundColor: 'rgba(74,55,40,0.35)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    width: '100%',
    // PCブラウザではモーダルが画面の外側に描かれるので、ここで幅を抑える
    maxWidth: deviceWidth - 48,
    alignSelf: 'center',
    backgroundColor: '#fff',
    borderRadius: 24,
    padding: 22,
  },
  title: {
    fontFamily: fonts.maru900,
    fontSize: 18,
    color: colors.textStrong,
    textAlign: 'center',
  },
  sub: {
    fontFamily: fonts.kaku500,
    fontSize: 11,
    color: colors.textFaint2,
    textAlign: 'center',
    marginTop: 4,
    marginBottom: 14,
  },
  label: {
    fontFamily: fonts.kaku600,
    fontSize: 11,
    color: colors.textFaint2,
    marginTop: 12,
    marginBottom: 5,
  },
  input: {
    borderWidth: 1.5,
    borderColor: colors.border14,
    borderRadius: 14,
    paddingVertical: 10,
    paddingHorizontal: 13,
    fontFamily: fonts.maru700,
    fontSize: 15,
    color: colors.textStrong,
    backgroundColor: colors.cream,
  },
  tones: { flexDirection: 'row', gap: 12, marginTop: 4 },
  toneDot: { width: 34, height: 34, borderRadius: 17 },
  toneDotActive: { borderWidth: 3, borderColor: colors.textStrong },
  create: {
    marginTop: 20,
    backgroundColor: colors.accent,
    borderRadius: 14,
    padding: 14,
    alignItems: 'center',
  },
  createText: { fontFamily: fonts.maru700, fontSize: 15, color: '#fff' },
  cancel: { alignItems: 'center', padding: 12 },
  cancelText: { fontFamily: fonts.kaku600, fontSize: 12, color: colors.textFaint2 },
});
