// 永続化されるデータモデル
export type Season = '春' | '夏' | '秋' | '冬';

export interface Child {
  id: string;
  name: string;
  age: number | null;
  tone: string; // テーマカラー（部屋の生成にも使う）
  createdAt: number;
}

export interface VoiceMemo {
  uri: string;
  durationSec: number;
}

/** 部屋の床上の正規化座標（x, z とも -1..1） */
export interface RoomPos {
  x: number;
  z: number;
}

export interface MemoryItem {
  id: string;
  childId: string;
  name: string;
  year: number;
  season: Season;
  memo: string;
  /** スキャンで撮った多方向フレーム（ターンテーブル3D表示に使う） */
  frames: string[];
  /** そえた写真 */
  photos: string[];
  voice: VoiceMemo | null;
  pos: RoomPos | null; // null = 未配置
  tone: string;
  createdAt: number;
}

export interface Settings {
  /** スキャンの撮影方向数（ふつう=12 / たかい=20） */
  scanTarget: 12 | 20;
  backup: boolean;
  notify: boolean;
}

export interface Database {
  version: 1;
  children: Child[];
  items: MemoryItem[];
  settings: Settings;
  onboarded: boolean;
}

export const TONES = ['#E08A63', '#8BA36F', '#C6A05E', '#7FA6C4'] as const;

export const DEFAULT_SETTINGS: Settings = { scanTarget: 20, backup: true, notify: false };

export function newId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}
