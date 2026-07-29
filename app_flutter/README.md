# ハコニワ（Flutter）

子どもの大切なモノを **3Dスキャン** して、家族ごとの小さな **3Dデジタル空間「ハコニワ」** に
思い出（写真・こえメモ・メモ）と一緒に残していくアプリ。

[`../app/`](../app/) の React Native + Expo 実装と **同じデザイン・同じ機能** を Flutter で作りなおしたもの。
`../design_handoff_hakoniwa/`（デザイン）と `../サービス概要書.pdf`（MVP要件）に基づく。
**MVPの4機能（3Dスキャン / 関連情報の付与 / ハコニワ空間の生成 / 配置機能）を実装済み。**

## 動かし方

```bash
cd app_flutter
flutter pub get
flutter run              # つないだ実機・エミュレータへ
flutter run -d chrome    # PCブラウザで確認
```

サーバー（バックアップ・家族間同期）を使う場合は [`../backend/`](../backend/) を起動して、
アプリの **せってい → バックアップ** から接続する。**つながなくても全機能そのまま動く。**

## 実装済み機能

| 機能 | 実装 |
|---|---|
| **3D空間の生成** | 自前のソフトウェア3Dレンダラ（`lib/room3d/`）。子どもごとにテーマカラーから手続き生成。ドラッグで回転、思い出が増えると家具が増える（空間の拡張） |
| **3Dスキャン** | `camera` で対象を一周しながら多方向キャプチャ（タップ / じどう撮影）。撮影フレーム列は「ターンテーブル3Dビュー」（ドラッグで回転）として再構成 |
| **関連情報の付与** | 名まえ・おもいでメモ・写真追加（`image_picker`）・こえメモの実録音/再生（`record` + `audioplayers`）・だれの/いつ（年・季節） |
| **配置機能** | 保存後に3Dルームの床をタップして配置（レイキャスト）or「おまかせ」自動配置。ピンをタップで情報シート |
| 永続化 | アプリのドキュメント領域に JSON + メディアをコピー。Web は `shared_preferences` |
| 家族の追加 | 名前・年齢・部屋の色を選んで新しいハコニワ（3D空間）を生成 |
| タイムライン | 実データを新しい順に表示・テキスト検索・子どもで絞り込み |
| 設定 | スキャン画質（12/20方向）・通知トグル・バックアップ接続・オンボーディング再表示 |
| **バックアップ / 家族間同期** | FastAPI バックエンド（`../backend/`）へオフラインファーストで同期 |

## 3Dルームについて

RN 版は `expo-gl` + three.js を使っているが、Flutter 版は **Canvas に直接描くソフトウェア
3Dレンダラを自前で持っている**（`lib/room3d/scene3d.dart`、約300行）。

部屋は軸ぞろえの箱と円柱・球だけでできていて半透明も無いので、面をカメラからの距離順に
並べて描く（画家のアルゴリズム）だけで正しく見える。ネイティブGLのプラグインに依存しないぶん、
**iOS / Android / Web / デスクトップで同じ絵**になり、ウィジェットテストの中でも描画できる。

- 陰影は面ごとに組み立て時に一度だけ計算する（光源が固定なので毎フレーム計算する必要がない）
- 裏を向いた面は画面上の符号つき面積で捨てる
- 床・壁のような大きな一枚板は「外殻」の段として先に描き、その上のものと並び順で競合させない
- タップ判定は投影の逆演算（レイと床平面 / レイと球）で、見えている絵と正確に一致する

`flutter test test/render_preview.dart` で `build/preview/*.png` に部屋を書き出せる。

## 構成

```
lib/
  main.dart                  # Provider + オンボーディング/本編の切り替え
  theme.dart                 # デザイントークン（色・書体・影・角丸）
  models/models.dart         # Child / MemoryItem / RoomPos / Settings / Database
  data/
    local_store.dart         # 端末への永続化（JSON + メディア）
    file_io.dart             # dart:io と Web のスタブを切り替える薄い層
    api_client.dart          # FastAPI バックエンドとの通信
    seed.dart                # 初回起動時のサンプルデータ
  state/app_store.dart       # ChangeNotifier（子ども・思い出・設定・同期）
  room3d/
    scene3d.dart             # ソフトウェア3Dレンダラ（投影・陰影・並べ替え・レイキャスト）
    room_builder.dart        # 部屋の手続き生成（テーマ・拡張家具・ピン）
    room_view.dart           # オービット回転・タップ選択・床配置のウィジェット
  features/voice.dart        # こえメモの録音と再生
  widgets/                   # BottomNav / TapScale / Icons / TurntableViewer ほか
  screens/                   # onboard / home / scan / memory / space / memories / settings / backup
test/
  room3d_test.dart           # 3Dの数学と描画（14ケース）
  app_store_test.dart        # ストア・並べ替え・検索・同期（17ケース）
  screens_test.dart          # 画面と導線（9ケース）
  integration_sync_test.dart # 実際に動く FastAPI との結合（4ケース・未起動ならスキップ）
  render_preview.dart        # 目視確認用: 部屋を PNG に書き出す
  screenshots.dart           # 目視確認用: 各画面を PNG に書き出す
tool/fetch_fonts.sh          # 目視確認で日本語を出すための書体を build/fonts/ に落とす
```

## テスト

```bash
flutter analyze
flutter test
```

`test/integration_sync_test.dart` だけは実際に動いている FastAPI サーバーを見にいく。
起動していなければ自動でスキップするので、ふだんは意識しなくてよい。

```bash
cd ../backend && .venv/bin/uvicorn app.main:app --port 8000 &
flutter test test/integration_sync_test.dart
```

`test/screenshots.dart` と `test/render_preview.dart` は目視確認用のツールで、
`build/preview/` に PNG を書き出す。日本語をちゃんと表示させたいときは先に
`tool/fetch_fonts.sh` を走らせる（書体は `build/` 配下なので git には入らない）。

## RN 版との対応

| React Native（`../app/`） | Flutter（ここ） |
|---|---|
| `src/theme.ts` | `lib/theme.dart` |
| `src/store/Store.tsx`（Context） | `lib/state/app_store.dart`（ChangeNotifier + provider） |
| `src/store/persistence.ts`（expo-file-system） | `lib/data/local_store.dart` + `file_io*.dart` |
| `src/three/roomBuilder.ts`（three.js） | `lib/room3d/room_builder.dart` |
| `src/three/Room3D.tsx`（expo-gl） | `lib/room3d/room_view.dart` + `scene3d.dart`（自前レンダラ） |
| `src/features/audio/voice.ts`（expo-audio） | `lib/features/voice.dart`（record + audioplayers） |
| `src/navigation/`（React Navigation） | `lib/screens/main_shell.dart` + `Navigator` |
| （なし） | `lib/data/api_client.dart` + `screens/backup_screen.dart`（FastAPI 同期） |

## 今後の発展（概要書のフル機能に向けて）

- **真のフォトグラメトリ**: 現在は撮影フレームのターンテーブル表示。iOS **Object Capture**
  (RealityKit) / Android **ARCore** のプラットフォームチャネルに差し替えれば glTF/USDZ の実3Dモデルになる。
  差し替え点は `TurntableViewer` と `room3d` のピン。
- **AIによる関連情報付与**: `MemoryScreen` の保存前に、写真からタイトル/メモ候補を生成するAPIを挿す
  （バックエンドに endpoint を足すのが素直）。
- **AR表示**: 3Dシーンを ARKit / ARCore のセッションに載せ替え。
- 触感・温度の再現は現状のスマホでは対象外（概要書どおり）。
