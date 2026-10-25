#!/usr/bin/env bash
# 组装 WorkBuddy 连接器包：workbuddy/connector/ + skills/ → dist/charlesai-club/ 和 dist/charlesai-club.zip
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/charlesai-club"

rm -rf "$ROOT/dist"
mkdir -p "$OUT/skills"
cp "$ROOT"/workbuddy/connector/* "$OUT/"
for skill in "$ROOT"/skills/*/; do
  name="$(basename "$skill")"
  mkdir -p "$OUT/skills/$name"
  # WorkBuddy 只需要 SKILL.md；agents/openai.yaml 是给 Codex 的
  cp "$skill/SKILL.md" "$OUT/skills/$name/"
done

(cd "$ROOT/dist" && zip -qr charlesai-club.zip charlesai-club)
echo "✓ $OUT"
echo "✓ $ROOT/dist/charlesai-club.zip"
