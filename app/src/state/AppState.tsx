// アプリ全体の状態（プロトタイプの placed / justAdded / recording に対応）
import React, { createContext, useCallback, useContext, useMemo, useRef, useState } from 'react';

interface AppState {
  /** スキャン保存で「つみき」がそうたの部屋に追加されたか */
  placed: boolean;
  /** 追加直後の通知/演出フラグ（3.2秒で自動オフ） */
  justAdded: boolean;
  /** こえメモ録音中（ダミー） */
  recording: boolean;
  /** 「ハコニワにしまう」保存アクション */
  saveItem: () => void;
  toggleRecording: () => void;
}

const Ctx = createContext<AppState | null>(null);

export function AppStateProvider({ children }: { children: React.ReactNode }) {
  const [placed, setPlaced] = useState(false);
  const [justAdded, setJustAdded] = useState(false);
  const [recording, setRecording] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const saveItem = useCallback(() => {
    setPlaced(true);
    setJustAdded(true);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setJustAdded(false), 3200);
  }, []);

  const toggleRecording = useCallback(() => setRecording((r) => !r), []);

  const value = useMemo(
    () => ({ placed, justAdded, recording, saveItem, toggleRecording }),
    [placed, justAdded, recording, saveItem, toggleRecording],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAppState(): AppState {
  const v = useContext(Ctx);
  if (!v) throw new Error('useAppState must be used within AppStateProvider');
  return v;
}
