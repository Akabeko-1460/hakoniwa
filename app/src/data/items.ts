// モノ・配置・タイムラインのデータ（design_handoff_hakoniwa/README.md セクション4-5, 4-6）

export type ItemId = 'bear' | 'clay' | 'draw' | 'blocks' | 'shoes' | 'toy' | 'photo';
export type ChildName = 'そうた' | 'みお';

export interface Item {
  photo: string; // プレースホルダ表示用ラベル
  name: string;
  date: string;
  memo: string;
}

export const ITEMS: Record<ItemId, Item> = {
  bear: {
    photo: 'くまの\n写真',
    name: 'くまのプーさん',
    date: '2019年 春',
    memo: 'はじめて自分でえらんだ ぬいぐるみ。毎ばん いっしょに ねていました。',
  },
  clay: {
    photo: 'ねんど\n写真',
    name: 'ねんど工作',
    date: '2023年 夏',
    memo: 'ようちえんで つくった さくひん。「これパパ！」と教えてくれた。',
  },
  draw: {
    photo: '絵の\n写真',
    name: 'かぞくの絵',
    date: '2024年 秋',
    memo: '5人かぞくを おおきく描いた絵。すみっこに いぬのポチも。',
  },
  blocks: {
    photo: 'つみきの\n写真',
    name: 'つみき',
    date: '2024年 冬',
    memo: 'たかくたかく つみあげて、くずして わらう。まいにち あそんだ つみき。',
  },
  shoes: {
    photo: 'くつの\n写真',
    name: 'はじめての靴',
    date: '2021年 秋',
    memo: 'あるきはじめた日に はいていた 小さな靴。',
  },
  toy: {
    photo: 'がらがら\n写真',
    name: 'がらがら',
    date: '2021年 冬',
    memo: 'にぎると よろこんで ふっていた おもちゃ。',
  },
  photo: {
    photo: 'たんじょう\n写真',
    name: 'たんじょう日',
    date: '2023年 春',
    memo: '1さいの おたんじょう日。ケーキに手をのばして。',
  },
};

export interface Marker {
  id: ItemId;
  left: number; // %
  top: number; // %
  tone: string;
}

export const LAYOUT: Record<ChildName, { base: number; markers: Marker[] }> = {
  そうた: {
    base: 24,
    markers: [
      { id: 'bear', left: 34, top: 54, tone: '#E08A63' },
      { id: 'clay', left: 70, top: 60, tone: '#8BA36F' },
      { id: 'draw', left: 78, top: 26, tone: '#C6A05E' },
    ],
  },
  みお: {
    base: 11,
    markers: [
      { id: 'shoes', left: 30, top: 58, tone: '#E08A63' },
      { id: 'toy', left: 64, top: 52, tone: '#8BA36F' },
      { id: 'photo', left: 76, top: 30, tone: '#C6A05E' },
    ],
  },
};

// 保存フローで置かれる新しいモノ（そうたの部屋の4つめ）
export const PLACED_MARKER: Marker = { id: 'blocks', left: 52, top: 30, tone: '#7FA6C4' };

export interface TimelineEntry {
  id: ItemId;
  child: ChildName;
  tone: string;
  year: string;
  label: string;
  isNew?: boolean;
}

// おもいで タイムライン（新しい順）。placed 時は先頭に「つみき」が挿入される
export const TIMELINE_BASE: TimelineEntry[] = [
  { id: 'draw', child: 'そうた', tone: '#C6A05E', year: '2024', label: 'かぞくの絵' },
  { id: 'clay', child: 'そうた', tone: '#8BA36F', year: '2023', label: 'ねんど工作' },
  { id: 'photo', child: 'みお', tone: '#C6A05E', year: '2023', label: 'たんじょう日' },
  { id: 'toy', child: 'みお', tone: '#8BA36F', year: '2021', label: 'がらがら' },
  { id: 'shoes', child: 'みお', tone: '#E08A63', year: '2021', label: 'はじめての靴' },
  { id: 'bear', child: 'そうた', tone: '#E08A63', year: '2019', label: 'くまのプーさん' },
];

export const PLACED_TIMELINE_ENTRY: TimelineEntry = {
  id: 'blocks',
  child: 'そうた',
  tone: '#7FA6C4',
  year: '2024',
  label: 'つみき',
  isNew: true,
};

export const TOTAL_BASE = 35;
