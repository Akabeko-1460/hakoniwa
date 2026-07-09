// 永続化: ネイティブ = expo-file-system（JSON + media ディレクトリ）
// Web = localStorage（開発プレビュー用。メディアは元URIのまま保持）
import { Platform } from 'react-native';
import type { Database } from './types';

const DB_FILENAME = 'hakoniwa.json';
const MEDIA_DIR = 'media';
const WEB_KEY = 'hakoniwa-db';

// expo-file-system は web では未サポートのため遅延 import
function fs() {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  return require('expo-file-system') as typeof import('expo-file-system');
}

export function loadDatabase(): Database | null {
  try {
    if (Platform.OS === 'web') {
      const raw = globalThis.localStorage?.getItem(WEB_KEY);
      return raw ? (JSON.parse(raw) as Database) : null;
    }
    const { File, Paths } = fs();
    const file = new File(Paths.document, DB_FILENAME);
    if (!file.exists) return null;
    return JSON.parse(file.textSync()) as Database;
  } catch (e) {
    console.warn('DB load failed:', e);
    return null;
  }
}

export function saveDatabase(db: Database): void {
  try {
    const json = JSON.stringify(db);
    if (Platform.OS === 'web') {
      globalThis.localStorage?.setItem(WEB_KEY, json);
      return;
    }
    const { File, Paths } = fs();
    const file = new File(Paths.document, DB_FILENAME);
    if (!file.exists) file.create();
    file.write(json);
  } catch (e) {
    console.warn('DB save failed:', e);
  }
}

/**
 * カメラ/レコーダーのキャッシュURIをアプリの永続領域へコピーして
 * 永続URIを返す。web ではそのまま返す（blob/data URI）。
 */
export async function importMedia(uri: string, ext: string): Promise<string> {
  if (Platform.OS === 'web') return uri;
  try {
    const { File, Directory, Paths } = fs();
    const dir = new Directory(Paths.document, MEDIA_DIR);
    if (!dir.exists) dir.create();
    const dest = new File(dir, `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}.${ext}`);
    const src = new File(uri);
    src.copy(dest);
    return dest.uri;
  } catch (e) {
    console.warn('media import failed, keeping original uri:', e);
    return uri;
  }
}
