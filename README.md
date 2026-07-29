# ハコニワ

子どもの大切なモノ（ぬいぐるみ・工作・絵など）を **3Dスキャン** して、
家族ごとの小さな **3Dデジタル空間「ハコニワ」** に思い出（写真・こえメモ・メモ）と
一緒に残していくアプリ。

**アプリ本体は React Native 版と Flutter 版の2つがあり、どちらも同じデザイン・同じ機能。**

| パス | 内容 |
|---|---|
| [`app/`](app/) | アプリ本体 ①（**React Native + Expo** / TypeScript）。起動方法は [app/README.md](app/README.md) |
| [`app_flutter/`](app_flutter/) | アプリ本体 ②（**Flutter** / Dart）。起動方法は [app_flutter/README.md](app_flutter/README.md) |
| [`backend/`](backend/) | クラウド保管・家族間同期の API（**FastAPI** / Python）。[backend/README.md](backend/README.md) |
| [`design_handoff_hakoniwa/`](design_handoff_hakoniwa/) | デザインリファレンス（動くHTMLプロトタイプ + 実装指示書） |
| [`サービス概要書.pdf`](サービス概要書.pdf) | サービスの企画・MVP要件（`サービス概要書_extracted.md` はそのテキスト抽出） |

## クイックスタート

**React Native 版**

```bash
cd app
npm install
npm start   # スマホの Expo Go アプリで QR コードを読み取る
```

PCブラウザで見る場合は `npm run web`。

**Flutter 版**

```bash
cd app_flutter
flutter pub get
flutter run              # つないだ実機・エミュレータへ
flutter run -d chrome    # PCブラウザで確認
```

**バックエンド（任意）**

```bash
cd backend
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
.venv/bin/uvicorn app.main:app --reload --port 8000
```

アプリは **サーバーが無くても全機能そのまま動く**（オフラインファースト）。
サーバーをつなぐと、端末が壊れても思い出が残り、家族の複数端末で同じハコニワを見られる。
Flutter 版の **せってい → バックアップ** から接続する。

## Webアプリとして公開する

どちらのアプリも **PCブラウザでもスマホのブラウザでも動く**。
デザインが画面の内寸 402×874 を前提にしているので、広い画面では
電話サイズの中央カラムに収め、まわりを指示書どおり「デバイス外」の背景でうめる。

| | ビルド | 出力 | 設定 |
|---|---|---|---|
| React Native 版 | `npx expo export --platform web` | `app/dist` | [`app/vercel.json`](app/vercel.json) |
| Flutter 版 | `flutter build web --release --no-web-resources-cdn` | `app_flutter/build/web` | [`app_flutter/vercel.json`](app_flutter/vercel.json) |

Flutter 版の `--no-web-resources-cdn` は必須。付けないと描画エンジン（CanvasKit）を
実行時に `www.gstatic.com` から取りにいき、届かないネットワークでは画面が真っ白になる。

## MVP実装状況

両方のアプリで実装済み。

- ✅ 3Dスキャン（実カメラで多方向キャプチャ → ターンテーブル3Dビュー）
- ✅ ハコニワ空間の生成（リアルタイム3Dルーム、子どもごとに生成・拡張）
- ✅ 関連情報の付与（写真・こえメモ録音・メモ・時期）
- ✅ 配置機能（3Dルームの床タップ配置 / おまかせ配置）
- ✅ 永続化・家族の追加・タイムライン検索

## 2つの実装のちがい

見た目と機能は同じで、中身の作りだけが違う。

| | React Native 版 | Flutter 版 |
|---|---|---|
| 言語 | TypeScript | Dart |
| 状態管理 | React Context | provider（ChangeNotifier） |
| **3Dルーム** | expo-gl + **three.js** | **自前のソフトウェア3Dレンダラ**（Canvas に直接描く。ネイティブGL不要で、Web でもテストの中でも同じ絵になる） |
| カメラ / 写真 / 音声 | expo-camera / expo-image-picker / expo-audio | camera / image_picker / record + audioplayers |
| 永続化 | expo-file-system（Web は localStorage） | ドキュメント領域に JSON + メディア（Web は shared_preferences） |
| サーバー同期 | （未対応） | FastAPI バックエンドへ同期 |
