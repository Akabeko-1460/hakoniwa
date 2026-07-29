// 初回起動時のサンプルデータ（デザインリファレンスのモノたち）
import '../models/models.dart';

Database seedDatabase() {
  final t = nowMs();

  Child child(String id, String name, int age, String tone, int back) => Child(
    id: id,
    name: name,
    age: age,
    tone: tone,
    createdAt: t - back,
    updatedAt: t - back,
  );

  MemoryItem item({
    required String id,
    required String childId,
    required String name,
    required int year,
    required Season season,
    required String memo,
    required String tone,
    required RoomPos pos,
    required int back,
  }) => MemoryItem(
    id: id,
    childId: childId,
    name: name,
    year: year,
    season: season,
    memo: memo,
    frames: const [],
    photos: const [],
    voice: null,
    pos: pos,
    tone: tone,
    createdAt: t - back,
    updatedAt: t - back,
  );

  return Database(
    onboarded: false,
    settings: const AppSettings(),
    children: [child('sota', 'そうた', 6, '#E08A63', 6), child('mio', 'みお', 3, '#8BA36F', 5)],
    items: [
      item(
        id: 'bear',
        childId: 'sota',
        name: 'くまのプーさん',
        year: 2019,
        season: Season.haru,
        memo: 'はじめて自分でえらんだ ぬいぐるみ。毎ばん いっしょに ねていました。',
        tone: '#E08A63',
        pos: const RoomPos(-0.32, 0.1),
        back: 60,
      ),
      item(
        id: 'clay',
        childId: 'sota',
        name: 'ねんど工作',
        year: 2023,
        season: Season.natsu,
        memo: 'ようちえんで つくった さくひん。「これパパ！」と教えてくれた。',
        tone: '#8BA36F',
        pos: const RoomPos(0.4, 0.25),
        back: 40,
      ),
      item(
        id: 'draw',
        childId: 'sota',
        name: 'かぞくの絵',
        year: 2024,
        season: Season.aki,
        memo: '5人かぞくを おおきく描いた絵。すみっこに いぬのポチも。',
        tone: '#C6A05E',
        pos: const RoomPos(0.56, -0.45),
        back: 20,
      ),
      item(
        id: 'shoes',
        childId: 'mio',
        name: 'はじめての靴',
        year: 2021,
        season: Season.aki,
        memo: 'あるきはじめた日に はいていた 小さな靴。',
        tone: '#E08A63',
        pos: const RoomPos(-0.4, 0.18),
        back: 50,
      ),
      item(
        id: 'toy',
        childId: 'mio',
        name: 'がらがら',
        year: 2021,
        season: Season.fuyu,
        memo: 'にぎると よろこんで ふっていた おもちゃ。',
        tone: '#8BA36F',
        pos: const RoomPos(0.28, 0.05),
        back: 45,
      ),
      item(
        id: 'photo',
        childId: 'mio',
        name: 'たんじょう日',
        year: 2023,
        season: Season.haru,
        memo: '1さいの おたんじょう日。ケーキに手をのばして。',
        tone: '#C6A05E',
        pos: const RoomPos(0.52, -0.4),
        back: 30,
      ),
    ],
  );
}
