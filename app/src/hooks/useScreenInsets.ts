// デザイン基準: 上 padding 56px（ステータスバー分）/ 下 26px（ホームインジケータ分）
// 実デバイスでは safe-area に合わせて可変にする
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export function useScreenInsets() {
  const insets = useSafeAreaInsets();
  return {
    top: Math.max(56, insets.top + 12),
    bottom: Math.max(26, insets.bottom + 9),
    raw: insets,
  };
}
