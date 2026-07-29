#!/usr/bin/env bash
# 目視確認（test/screenshots.dart）で日本語をちゃんと表示するための書体を
# build/fonts/ に落とす。アプリ本体は google_fonts が実行時に取ってくるので、
# これは開発者の手元だけの話（build/ は git 管理外）。
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/fonts

for spec in "ZenMaruGothic:Zen+Maru+Gothic:400" \
            "ZenMaruGothic:Zen+Maru+Gothic:700" \
            "ZenMaruGothic:Zen+Maru+Gothic:900" \
            "ZenKakuGothicNew:Zen+Kaku+Gothic+New:400" \
            "ZenKakuGothicNew:Zen+Kaku+Gothic+New:700"; do
  IFS=: read -r family query weight <<<"$spec"
  url=$(curl -sS -H "User-Agent: Mozilla/5.0" \
    "https://fonts.googleapis.com/css2?family=${query}:wght@${weight}" |
    grep -o "https://[^)]*\.ttf" | head -1)
  [ -n "$url" ] && curl -sS -o "build/fonts/${family}-${weight}.ttf" "$url"
done

ls -la build/fonts/
