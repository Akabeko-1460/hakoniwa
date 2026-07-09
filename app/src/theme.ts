// デザイントークン（design_handoff_hakoniwa/README.md セクション3）
import { Platform, ViewStyle } from 'react-native';

export const colors = {
  accent: '#E08A63', // アクセント（メイン・オレンジ）
  accentDark: '#C25E3A', // アクセント濃（テキスト・押下）
  accentRec: '#C2452F', // 録音中
  accentPale: '#FBEDE4', // アクセント淡背景
  green: '#8BA36F', // サブ（グリーン・みお/完了）
  greenPale: '#EEF2E6',
  greenDark: '#5E7345',
  greenBorder: '#CBDAB6',
  yellow: '#C6A05E', // サブ（イエロー）
  blue: '#7FA6C4', // 追加ピン（ブルー・つみき）
  textStrong: '#4A3728',
  textMid: '#5C4A38',
  textMid2: '#7A6650',
  textFaint: '#8B7355',
  textFaint2: '#A18A72',
  textFaint3: '#B7A488',
  textFaint4: '#C6B79E',
  cream: '#FBF6EE', // 背景・クリーム（画面）
  spaceBg: '#F3EAD9', // 背景・ハコニワ画面
  spaceGradTop: '#EBDFC8',
  card: '#FFFFFF',
  border14: 'rgba(120,85,55,0.14)',
  border10: 'rgba(120,85,55,0.10)',
  border12: 'rgba(120,85,55,0.12)',
  border16: 'rgba(120,85,55,0.16)',
  dashed28: 'rgba(120,85,55,0.28)',
  underline: '#EADFCC',
  divider: '#F1E9DA',
  chipBg: '#F0E7D7',
  woodLight: '#CBA271',
  woodDark: '#A97C4E',
  trackBg: '#EEE4D3',
  toggleOff: '#E4D8C2',
  phText: '#B3A188',
  onboardTop: '#F6EEDF',
  onboardBottom: '#EBDCC3',
  waveA: '#E7C4AE',
  waveB: '#EBDCC6',
  knob: '#E7DAC4',
  addTint: '#C29A72',
};

// 見出し・タイトル・数字・ボタン = Zen Maru Gothic / 本文・ラベル = Zen Kaku Gothic New
// Zen Kaku Gothic New に 600 は無いため、CSS のフォールバック規則に合わせ 700 を使う
export const fonts = {
  maru400: 'ZenMaruGothic_400Regular',
  maru500: 'ZenMaruGothic_500Medium',
  maru700: 'ZenMaruGothic_700Bold',
  maru900: 'ZenMaruGothic_900Black',
  kaku400: 'ZenKakuGothicNew_400Regular',
  kaku500: 'ZenKakuGothicNew_500Medium',
  kaku600: 'ZenKakuGothicNew_700Bold',
  kaku700: 'ZenKakuGothicNew_700Bold',
};

export function shadow(
  opacity: number,
  radius: number,
  offsetY: number,
  color = 'rgb(120,85,55)',
  elevation?: number,
): ViewStyle {
  return Platform.select<ViewStyle>({
    web: {
      boxShadow: `0 ${offsetY}px ${radius}px ${color.replace('rgb', 'rgba').replace(')', `,${opacity})`)}`,
    },
    default: {
      shadowColor: color,
      shadowOpacity: opacity,
      shadowRadius: radius,
      shadowOffset: { width: 0, height: offsetY },
      elevation: elevation ?? Math.round(offsetY),
    },
  })!;
}

// RN 0.86 で StyleSheet.absoluteFillObject が削除されたため自前定義
export const absoluteFill = {
  position: 'absolute',
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
} as const;

export const cardShadow = shadow(0.1, 20, 8); // カード
export const buttonShadow = shadow(0.32, 18, 8, 'rgb(224,138,99)'); // ボタン
export const frameShadow = shadow(0.3, 38, 20); // 木枠
