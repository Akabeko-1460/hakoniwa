import type { NavigatorScreenParams } from '@react-navigation/native';

export type TabParamList = {
  Home: undefined;
  Memories: undefined;
  Settings: undefined;
};

export type RootStackParamList = {
  Onboard: undefined;
  Main: NavigatorScreenParams<TabParamList> | undefined;
  Scan: undefined;
  Memory: undefined;
  Space: {
    childId: string;
    selectedId?: string | null;
    /** 保存直後: このモノの置き場所を選ぶ配置モードで開く */
    placeItemId?: string | null;
  };
};
