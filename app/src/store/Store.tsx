// アプリ全体のデータストア（子ども・思い出・設定）+ 一時状態（スキャン下書き等）
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { loadDatabase, saveDatabase, importMedia } from './persistence';
import { seedDatabase } from './seed';
import type { Child, Database, MemoryItem, RoomPos, Season, Settings, VoiceMemo } from './types';
import { newId } from './types';

export interface NewItemInput {
  childId: string;
  name: string;
  year: number;
  season: Season;
  memo: string;
  frames: string[]; // スキャンで撮ったキャッシュURI（コピーされる）
  photos: string[];
  voice: VoiceMemo | null;
  tone: string;
}

interface StoreValue {
  ready: boolean;
  children: Child[];
  items: MemoryItem[];
  settings: Settings;
  onboarded: boolean;

  childById: (id: string) => Child | undefined;
  itemsOf: (childId: string) => MemoryItem[];

  addChild: (name: string, age: number | null, tone: string) => Child;
  addItem: (input: NewItemInput) => Promise<MemoryItem>;
  placeItem: (id: string, pos: RoomPos) => void;
  setOnboarded: (v: boolean) => void;
  updateSettings: (patch: Partial<Settings>) => void;

  /** スキャン→思い出をのこす 間で受け渡す撮影フレーム */
  draftFrames: string[];
  setDraftFrames: (frames: string[]) => void;

  /** 追加直後の演出用（3.2秒で自動クリア） */
  lastAddedId: string | null;
}

const Ctx = createContext<StoreValue | null>(null);

export function StoreProvider({ children: node }: { children: React.ReactNode }) {
  const [db, setDb] = useState<Database | null>(null);
  const [draftFrames, setDraftFrames] = useState<string[]>([]);
  const [lastAddedId, setLastAddedId] = useState<string | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    setDb(loadDatabase() ?? seedDatabase());
  }, []);

  // 変更のたびに保存
  useEffect(() => {
    if (db) saveDatabase(db);
  }, [db]);

  const mutate = useCallback((fn: (d: Database) => Database) => {
    setDb((d) => (d ? fn(d) : d));
  }, []);

  const addChild = useCallback(
    (name: string, age: number | null, tone: string): Child => {
      const child: Child = { id: newId(), name, age, tone, createdAt: Date.now() };
      mutate((d) => ({ ...d, children: [...d.children, child] }));
      return child;
    },
    [mutate],
  );

  const markAdded = useCallback((id: string) => {
    setLastAddedId(id);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setLastAddedId(null), 3200);
  }, []);

  const addItem = useCallback(
    async (input: NewItemInput): Promise<MemoryItem> => {
      // メディアを永続領域へコピー
      const frames = await Promise.all(input.frames.map((u) => importMedia(u, 'jpg')));
      const photos = await Promise.all(input.photos.map((u) => importMedia(u, 'jpg')));
      const voice = input.voice
        ? { ...input.voice, uri: await importMedia(input.voice.uri, 'm4a') }
        : null;
      const item: MemoryItem = {
        id: newId(),
        childId: input.childId,
        name: input.name || 'なまえのないモノ',
        year: input.year,
        season: input.season,
        memo: input.memo,
        frames,
        photos,
        voice,
        pos: null,
        tone: input.tone,
        createdAt: Date.now(),
      };
      mutate((d) => ({ ...d, items: [...d.items, item] }));
      return item;
    },
    [mutate],
  );

  const placeItem = useCallback(
    (id: string, pos: RoomPos) => {
      mutate((d) => ({
        ...d,
        items: d.items.map((it) => (it.id === id ? { ...it, pos } : it)),
      }));
      markAdded(id);
    },
    [mutate, markAdded],
  );

  const setOnboarded = useCallback(
    (v: boolean) => mutate((d) => ({ ...d, onboarded: v })),
    [mutate],
  );

  const updateSettings = useCallback(
    (patch: Partial<Settings>) =>
      mutate((d) => ({ ...d, settings: { ...d.settings, ...patch } })),
    [mutate],
  );

  const value = useMemo<StoreValue>(() => {
    const children = db?.children ?? [];
    const items = db?.items ?? [];
    return {
      ready: db !== null,
      children,
      items,
      settings: db?.settings ?? { scanTarget: 20, backup: true, notify: false },
      onboarded: db?.onboarded ?? false,
      childById: (id) => children.find((c) => c.id === id),
      itemsOf: (childId) => items.filter((it) => it.childId === childId),
      addChild,
      addItem,
      placeItem,
      setOnboarded,
      updateSettings,
      draftFrames,
      setDraftFrames,
      lastAddedId,
    };
  }, [db, draftFrames, lastAddedId, addChild, addItem, placeItem, setOnboarded, updateSettings]);

  return <Ctx.Provider value={value}>{node}</Ctx.Provider>;
}

export function useStore(): StoreValue {
  const v = useContext(Ctx);
  if (!v) throw new Error('useStore must be used within StoreProvider');
  return v;
}
