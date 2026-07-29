# ハコニワ（React Native + Expo）

子どもの大切なモノを **3Dスキャン** して、家族ごとの小さな **3Dデジタル空間「ハコニワ」** に
思い出（写真・こえメモ・メモ）と一緒に残していくアプリ。

`../design_handoff_hakoniwa/`（デザイン）と `../サービス概要書.pdf`（MVP要件）に基づく実装。
**MVPの4機能（3Dスキャン / 関連情報の付与 / ハコニワ空間の生成 / 配置機能）を実装済み。**

## スマホでの動かし方（Expo Go）

```bash
npm install
npm start
```

スマホに **Expo Go** アプリを入れて、ターミナルに出る QR コードを読み取る
（PCとスマホは同じ Wi-Fi に接続）。ネイティブビルド不要で全機能が動きます。

PCブラウザ確認: `npm run web` → http://localhost:8090 （3Dルーム・カメラ・保存まで動作）

## Web（Vercel）へのデプロイ

ルートに [`vercel.json`](vercel.json) があり、`npx expo export --platform web` の結果
（`dist/`）をそのまま配信する。SPA なので全パスを `index.html` に rewrite している。

手元で本番と同じものを確認する:

```bash
npx expo export --platform web
npx serve dist        # もしくは python3 -m http.server --directory dist
```

**PCブラウザで開いたときは、電話サイズ（402px）の中央カラムに収まる。**
このアプリのデザインは画面の内寸 402×874 を前提にしているので、
ブラウザの全幅に広げるとカードも3Dルームも間のびしてしまう。
`src/components/DeviceFrame.tsx` が、幅 520px 以上のときだけ枠に収め、
まわりを指示書どおり「デバイス外」の背景色でうめる。スマホでは何もしない。

## 実装済み機能

| 機能 | 実装 |
|---|---|
| **3D空間の生成** | expo-gl + three.js のリアルタイム3Dルーム。子どもごとにテーマカラーから手続き生成。ドラッグで回転、思い出が増えると家具が増える（空間の拡張） |
| **3Dスキャン** | expo-camera で対象を一周しながら多方向キャプチャ（タップ / じどう撮影）。撮影フレームは「ターンテーブル3Dビュー」（ドラッグで回転）として再構成 |
| **関連情報の付与** | 名まえ・おもいでメモ・写真追加（expo-image-picker）・こえメモの実録音/再生（expo-audio）・だれの/いつ（年・季節） |
| **配置機能** | 保存後に3Dルームの床をタップして配置（レイキャスト）or「おまかせ」自動配置。ピンをタップで情報シート |
| 永続化 | expo-file-system（JSON + メディアコピー）。web は localStorage |
| 家族の追加 | 名前・年齢・部屋の色を選んで新しいハコニワ（3D空間）を生成 |
| タイムライン | 実データを新しい順に表示・テキスト検索・子どもで絞り込み |
| 設定 | スキャン画質（12/20方向）・トグル類・オンボーディング再表示 |

## 構成

```
App.tsx                      # フォント読込 + StoreProvider + ナビゲーション
src/
  theme.ts                   # デザイントークン
  store/                     # types / persistence(expo-file-system) / seed / Store(Context)
  three/
    roomBuilder.ts           # 3Dルームの手続き生成（テーマ・拡張家具・ピン）
    Room3D.tsx               # GLView + three.js（オービット回転・タップ選択・床配置）
  features/audio/voice.ts    # 録音・再生フック（expo-audio）
  components/
    TurntableViewer.tsx      # スキャンフレームを回して見るビューワー
    AddChildModal.tsx        # あたらしいハコニワ作成
    BottomNav / TapScale / Placeholder / Icons
  screens/                   # onboard / home / scan / memory / space / memories / settings
  navigation/                # native-stack + 下部タブ
```

## 今後の発展（概要書のフル機能に向けて）

- **真のフォトグラメトリ**: 現在は撮影フレームのターンテーブル表示。iOS **Object Capture**
  (RealityKit) / Android **ARCore** のネイティブモジュール（EAS 開発ビルドが必要）に差し替えれば
  glTF/USDZ の実3Dモデルになる。`TurntableViewer` と `Room3D` のピンがその差し替えポイント。
- **AIによる関連情報付与**: `MemoryScreen` の保存前に写真からタイトル/メモ候補を生成するAPIを挿す。
- **AR表示**: expo-gl の3Dシーンを AR セッションに載せ替え（ネイティブ）。
- 触感・温度の再現は現状のスマホでは対象外（概要書どおり）。
