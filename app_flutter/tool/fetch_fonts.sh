#!/usr/bin/env bash
# 同梱している書体を Google Fonts から取り直す。
# ふだんは走らせる必要はない（assets/fonts/ に入っているものが使われる）。
# ウェイトを増やすときは、ここと pubspec.yaml の両方に足すこと。
set -euo pipefail
cd "$(dirname "$0")/../assets/fonts"

for spec in "ZenMaruGothic-Bold:Zen+Maru+Gothic:700" \
            "ZenMaruGothic-Black:Zen+Maru+Gothic:900" \
            "ZenKakuGothicNew-Medium:Zen+Kaku+Gothic+New:500" \
            "ZenKakuGothicNew-Bold:Zen+Kaku+Gothic+New:700"; do
  IFS=: read -r out query weight <<<"$spec"
  url=$(curl -fsSL -H "User-Agent: Mozilla/5.0" \
    "https://fonts.googleapis.com/css2?family=${query}:wght@${weight}" |
    grep -o "https://[^)]*\.ttf" | head -1)
  curl -fsSL -o "$out.ttf" "$url"
  echo "$out.ttf"
done

curl -fsSL -o OFL.txt \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/zenmarugothic/OFL.txt"
