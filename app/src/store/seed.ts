// 初回起動時のサンプルデータ（デザインリファレンスのモノたち）
import type { Database } from './types';
import { DEFAULT_SETTINGS } from './types';

const t = Date.now();

export function seedDatabase(): Database {
  return {
    version: 1,
    onboarded: false,
    settings: { ...DEFAULT_SETTINGS },
    children: [
      { id: 'sota', name: 'そうた', age: 6, tone: '#E08A63', createdAt: t - 6 },
      { id: 'mio', name: 'みお', age: 3, tone: '#8BA36F', createdAt: t - 5 },
    ],
    items: [
      {
        id: 'bear', childId: 'sota', name: 'くまのプーさん', year: 2019, season: '春',
        memo: 'はじめて自分でえらんだ ぬいぐるみ。毎ばん いっしょに ねていました。',
        frames: [], photos: [], voice: null, tone: '#E08A63',
        pos: { x: -0.32, z: 0.1 }, createdAt: t - 60,
      },
      {
        id: 'clay', childId: 'sota', name: 'ねんど工作', year: 2023, season: '夏',
        memo: 'ようちえんで つくった さくひん。「これパパ！」と教えてくれた。',
        frames: [], photos: [], voice: null, tone: '#8BA36F',
        pos: { x: 0.4, z: 0.25 }, createdAt: t - 40,
      },
      {
        id: 'draw', childId: 'sota', name: 'かぞくの絵', year: 2024, season: '秋',
        memo: '5人かぞくを おおきく描いた絵。すみっこに いぬのポチも。',
        frames: [], photos: [], voice: null, tone: '#C6A05E',
        pos: { x: 0.56, z: -0.45 }, createdAt: t - 20,
      },
      {
        id: 'shoes', childId: 'mio', name: 'はじめての靴', year: 2021, season: '秋',
        memo: 'あるきはじめた日に はいていた 小さな靴。',
        frames: [], photos: [], voice: null, tone: '#E08A63',
        pos: { x: -0.4, z: 0.18 }, createdAt: t - 50,
      },
      {
        id: 'toy', childId: 'mio', name: 'がらがら', year: 2021, season: '冬',
        memo: 'にぎると よろこんで ふっていた おもちゃ。',
        frames: [], photos: [], voice: null, tone: '#8BA36F',
        pos: { x: 0.28, z: 0.05 }, createdAt: t - 45,
      },
      {
        id: 'photo', childId: 'mio', name: 'たんじょう日', year: 2023, season: '春',
        memo: '1さいの おたんじょう日。ケーキに手をのばして。',
        frames: [], photos: [], voice: null, tone: '#C6A05E',
        pos: { x: 0.52, z: -0.4 }, createdAt: t - 30,
      },
    ],
  };
}
