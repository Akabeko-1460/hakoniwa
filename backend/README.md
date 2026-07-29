# ハコニワ API（FastAPI）

Flutter 版アプリ（[`../app_flutter/`](../app_flutter/)）のクラウド保管・家族間同期をになうサーバー。

アプリ自体は **サーバーなしでも全機能が動く**（オフラインファースト）。このAPIは
せってい画面の「バックアップ」をオンにしたときに使われ、次の3つを足す。

- 端末が壊れても思い出が消えない（メディアの実体もサーバーに置く）
- 夫婦や祖父母など、家族の複数端末で同じハコニワを見られる
- 端末を機種変更しても、家族トークンだけで復元できる

## 起動

```bash
cd backend
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
.venv/bin/uvicorn app.main:app --reload --port 8000
```

- API ドキュメント（Swagger UI）: http://localhost:8000/docs
- ヘルスチェック: http://localhost:8000/api/health

SQLite と アップロードされたメディアは `backend/data/` に置かれる（gitignore 済み）。

### 環境変数

| 変数 | 既定値 | 内容 |
|---|---|---|
| `HAKONIWA_DATA_DIR` | `./data` | SQLite とメディアの置き場 |
| `HAKONIWA_MAX_UPLOAD_BYTES` | `16777216` | 1ファイルの上限（16MB） |
| `HAKONIWA_CORS_ORIGINS` | `*` | Flutter Web からのアクセス許可（カンマ区切り） |

## 認証

`POST /api/families` で家族を作るとトークンが1度だけ返る。以降のリクエストは

```
Authorization: Bearer <token>
```

を付ける。サーバーは SHA-256 ハッシュだけを保存するので、平文トークンは端末側にしか残らない。
家族の境界がそのままデータの境界で、他家族の子ども・思い出・メディアはいっさい読めない
（存在も漏らさないよう 404 を返す）。

> これは家庭内で使う前提の軽量な仕組み。一般公開するならメール認証・トークンの失効・
> レート制限を足すこと。

## エンドポイント

| メソッド | パス | 内容 |
|---|---|---|
| `GET` | `/api/health` | 死活確認 |
| `POST` | `/api/families` | 家族を作りトークンを発行 |
| `GET` | `/api/families/me` | トークンの持ち主を確認 |
| `GET` `POST` | `/api/children` | 子ども（=ハコニワ空間）の一覧・作成 |
| `PATCH` `DELETE` | `/api/children/{id}` | 更新・削除（ぶら下がる思い出もまとめて） |
| `GET` `POST` | `/api/items` | 思い出の一覧（新しい順・`childId`/`q` で絞り込み）・作成 |
| `PATCH` `DELETE` | `/api/items/{id}` | 更新・削除 |
| `PUT` | `/api/items/{id}/pos` | 部屋の床に配置（配置機能） |
| `POST` | `/api/media` | スキャンフレーム・写真・こえメモのアップロード |
| `GET` | `/api/media/{id}` | メディアの取得 |
| `GET` `PUT` | `/api/settings` | アプリ設定 |
| `GET` | `/api/snapshot` | 全データを丸ごと取得 |
| `POST` | `/api/sync` | ローカルDBを送ってマージ結果を受け取る |

JSON のキーは Flutter 側に合わせて camelCase（`childId` `createdAt` `durationSec` …）。

## 同期のしくみ

アプリはローカルDBが正で、通信は1往復にまとめている。

```
端末のローカルDB ──POST /api/sync──▶ サーバーでマージ ──▶ Snapshot を返す ──▶ ローカルDBを置き換え
```

競合は `updatedAt` の新しい方が勝つ（last-write-wins）。削除は論理削除で、
`deletedChildIds` / `deletedItemIds` に載せると他端末にも伝わる。
他の家族が持つIDを送っても無視されるので、IDの当て推量で他家庭のデータは書き換えられない。

## テスト

```bash
.venv/bin/python -m pytest tests -q
```

家族の分離・同期の競合解決・配置座標の検証・メディアの権限まわりを 19 ケースでカバーしている。

## 構成

```
app/
  main.py              # FastAPI アプリ本体・CORS・ルーター登録
  config.py            # 環境変数（HAKONIWA_*）
  db.py                # SQLAlchemy テーブル（Family/Child/Item/FamilySettings/Media）
  schemas.py           # 入出力スキーマ（camelCase）
  security.py          # 家族トークンの発行・検証
  routers/
    families.py        # 家族の作成・確認
    children.py        # 子ども CRUD
    items.py           # 思い出 CRUD・配置
    media.py           # アップロード・配信
    sync.py            # 設定・スナップショット・同期
tests/test_api.py
```
