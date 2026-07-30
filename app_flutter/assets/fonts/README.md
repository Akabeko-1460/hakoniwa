# 同梱している書体について

デザイン指示書が指定する 2 書体を、アプリに同梱している。

| ファミリー | ウェイト | 用途 |
|---|---|---|
| Zen Maru Gothic | 700 / 900 | 見出し・タイトル・数字・ボタン |
| Zen Kaku Gothic New | 500 / 700 | 本文・ラベル・メモ |

コードが実際に使うウェイトだけを入れている（`AppFonts.maru` は既定 700 と 900、
`AppFonts.kaku` は既定 500 と 600/700）。

## なぜ同梱するのか

はじめは `google_fonts` で実行時に取得していたが、**Flutter Web では
fonts.gstatic.com に届かないと文字が1文字も表示されない**（Flutter Web は
システムフォントへ落ちてくれない）。読み込みが遅いだけでも、その間ずっと
文字が出ないままになる。同梱すれば、オフラインでも初回でも確実に出る。

## ライセンス

どちらも SIL Open Font License 1.1。全文は [`OFL.txt`](OFL.txt)。

入手元:
- https://fonts.google.com/specimen/Zen+Maru+Gothic
- https://fonts.google.com/specimen/Zen+Kaku+Gothic+New

差し替えるときは [`../../tool/fetch_fonts.sh`](../../tool/fetch_fonts.sh) を使う。
