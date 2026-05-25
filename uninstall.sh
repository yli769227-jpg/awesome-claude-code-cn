#!/usr/bin/env bash
#
# awesome-claude-code-cn uninstaller
#
# 精确移除 install.sh 留下的痕迹:
#   1. 删除 ~/.claude/skills/discipline-* 8 个目录
#   2. 删除 ~/.claude/CLAUDE.md 里的 awesome-claude-code-cn:start..end 标记块
#
# 安全:
#   - 不动 CLAUDE.md 其他内容
#   - 标记块不存在则跳过,不报错
#   - --dry-run 只打印不删
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/yli769227-jpg/awesome-claude-code-cn/main/uninstall.sh | bash
#   curl -fsSL ... | bash -s -- --dry-run
#

set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_HOME/skills"
CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
MARKER_START="<!-- awesome-claude-code-cn:start v1 -->"
MARKER_END="<!-- awesome-claude-code-cn:end -->"

SKILLS=(
  discipline-ask-before-act
  discipline-test-is-truth
  discipline-log-first
  discipline-check-versions
  discipline-agent-team
  discipline-incremental-build
  discipline-no-dead-code
  discipline-first-principles
)

if [ -t 1 ]; then
  C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
  C_GRN=''; C_YEL=''; C_DIM=''; C_RST=''
fi
info() { printf '%s[+]%s %s\n' "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YEL" "$C_RST" "$*"; }
dim()  { printf '%s    %s%s\n' "$C_DIM" "$*" "$C_RST"; }

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h) sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

[ "$DRY_RUN" = 1 ] && warn "DRY RUN 模式 —— 不会真删"

REMOVED=0
for skill in "${SKILLS[@]}"; do
  dst="$SKILLS_DIR/$skill"
  if [ -d "$dst" ]; then
    info "删除 $dst"
    [ "$DRY_RUN" = 0 ] && rm -rf "$dst"
    REMOVED=$((REMOVED+1))
  else
    dim "$skill 不存在,跳过"
  fi
done

if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER_START" "$CLAUDE_MD"; then
  info "剥离 CLAUDE.md 标记块"
  if [ "$DRY_RUN" = 0 ]; then
    awk -v s="$MARKER_START" -v e="$MARKER_END" '
      index($0,s) { skip=1; next }
      skip && index($0,e) { skip=0; next }
      !skip { print }
    ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
    # 顺手吞掉末尾累积的空行
    awk '/^$/{q=q $0 "\n"; next} {print q $0; q=""}' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
  fi
else
  dim "CLAUDE.md 无标记块,跳过"
fi

echo
info "卸载完成 ✅ (移除 $REMOVED 个 skill 目录)"
