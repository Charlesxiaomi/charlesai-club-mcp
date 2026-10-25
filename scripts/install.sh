#!/usr/bin/env bash
# 把 skills/ 下的技能复制到各客户端的用户级技能目录。可重复执行（覆盖更新）。
# 用法：scripts/install.sh [workbuddy] [codex] [claude]   不带参数 = 三个都装
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(workbuddy codex claude)

for t in "${targets[@]}"; do
  case "$t" in
    workbuddy) dest="$HOME/.workbuddy/skills" ;;
    codex)     dest="$HOME/.agents/skills" ;;
    claude)    dest="$HOME/.claude/skills" ;;
    *) echo "未知目标：$t（可选 workbuddy / codex / claude）" >&2; exit 1 ;;
  esac
  mkdir -p "$dest"
  for skill in "$ROOT"/skills/*/; do
    name="$(basename "$skill")"
    rm -rf "${dest:?}/$name"
    cp -R "$skill" "$dest/$name"
    echo "✓ $t: $dest/$name"
  done
done

echo
echo "技能已安装。MCP 还需要单独配置，见 README。"
