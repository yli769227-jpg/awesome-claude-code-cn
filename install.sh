#!/usr/bin/env bash
#
# awesome-claude-code-cn installer
#
# 一行装 8 个 discipline-* skill 到 ~/.claude/skills/,
# 并幂等注入 8 行触发说明到 ~/.claude/CLAUDE.md(带标记块,可重跑可卸载)。
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/yli769227-jpg/awesome-claude-code-cn/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --force       # 覆盖已存在的 skill 目录
#   curl -fsSL ... | bash -s -- --dry-run     # 只打印动作,不动文件
#   curl -fsSL ... | bash -s -- --help
#
# 也支持本地直接跑: bash install.sh [--force|--dry-run]
#
# 卸载: 同仓库 uninstall.sh
#

set -euo pipefail

# ---------- 常量 ----------
REPO_TARBALL_URL="https://github.com/yli769227-jpg/awesome-claude-code-cn/archive/refs/heads/main.tar.gz"
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

# ---------- 颜色 / 日志 ----------
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
  C_RED=''; C_GRN=''; C_YEL=''; C_DIM=''; C_RST=''
fi
info() { printf '%s[+]%s %s\n' "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YEL" "$C_RST" "$*"; }
err()  { printf '%s[x]%s %s\n' "$C_RED" "$C_RST" "$*" >&2; }
dim()  { printf '%s    %s%s\n' "$C_DIM" "$*" "$C_RST"; }

# ---------- 参数 ----------
FORCE=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h)
      sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) err "未知参数: $arg (用 --help 看用法)"; exit 2 ;;
  esac
done

# ---------- 前置检查 ----------
need() { command -v "$1" >/dev/null 2>&1 || { err "需要 $1 但没找到"; exit 1; }; }
need curl
need tar

# ---------- 下载源码 (tarball,无需 git) ----------
TMP_DIR="$(mktemp -d -t accc-XXXXXX)"
cleanup() { [ -n "${TMP_DIR:-}" ] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# 如果本地直接 `bash install.sh` 且 cwd 已是仓库根目录,直接复用本地副本
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || pwd)"
if [ -d "$SCRIPT_DIR/skills" ] && [ -f "$SCRIPT_DIR/skills/discipline-test-is-truth/SKILL.md" ]; then
  info "检测到本地仓库,跳过下载"
  SRC_ROOT="$SCRIPT_DIR"
else
  info "下载 awesome-claude-code-cn 源码到临时目录"
  if ! curl -fsSL "$REPO_TARBALL_URL" | tar -xz -C "$TMP_DIR" --strip-components=1; then
    err "下载 / 解压失败,检查网络后重试"
    exit 1
  fi
  SRC_ROOT="$TMP_DIR"
fi

# ---------- 安装 skill ----------
info "目标目录: $SKILLS_DIR"
if [ "$DRY_RUN" = 1 ]; then
  warn "DRY RUN 模式 —— 不会写任何文件"
fi

[ "$DRY_RUN" = 0 ] && mkdir -p "$SKILLS_DIR"

INSTALLED=0; SKIPPED=0; OVERWRITTEN=0
for skill in "${SKILLS[@]}"; do
  src="$SRC_ROOT/skills/$skill"
  dst="$SKILLS_DIR/$skill"
  if [ ! -d "$src" ]; then
    err "源目录缺失: $src(仓库结构异常,跳过)"
    continue
  fi
  if [ -d "$dst" ]; then
    if [ "$FORCE" = 1 ]; then
      info "覆盖 $skill (--force)"
      if [ "$DRY_RUN" = 0 ]; then
        rm -rf "$dst"
        cp -r "$src" "$dst"
      fi
      OVERWRITTEN=$((OVERWRITTEN+1))
    else
      dim "$skill 已存在,跳过(用 --force 覆盖)"
      SKIPPED=$((SKIPPED+1))
    fi
  else
    info "安装 $skill"
    [ "$DRY_RUN" = 0 ] && cp -r "$src" "$dst"
    INSTALLED=$((INSTALLED+1))
  fi
done

# ---------- CLAUDE.md 幂等注入 ----------
inject_claude_md() {
  local target="$CLAUDE_MD"
  if [ ! -f "$target" ]; then
    info "CLAUDE.md 不存在,新建"
    [ "$DRY_RUN" = 0 ] && touch "$target"
  fi

  if [ "$DRY_RUN" = 0 ] && grep -qF "$MARKER_START" "$target"; then
    info "CLAUDE.md 已有 v1 标记块,先剥离再重新追加(幂等)"
    awk -v s="$MARKER_START" -v e="$MARKER_END" '
      index($0,s) { skip=1; next }
      skip && index($0,e) { skip=0; next }
      !skip { print }
    ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  fi

  if [ "$DRY_RUN" = 1 ]; then
    info "将向 CLAUDE.md 追加 awesome-claude-code-cn 触发块(8 行)"
    return 0
  fi

  # 去掉末尾累积的空行(防止反复 install/uninstall 把空行累积起来)
  if [ -s "$target" ]; then
    awk '/^$/{q=q $0 "\n"; next} {print q $0; q=""}' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  fi

  {
    # 块前留一个空行(若文件非空)
    [ -s "$target" ] && printf '\n'
    printf '%s\n' "$MARKER_START"
    cat <<'BLOCK'
当你即将做非平凡的代码变更前 → 加载 ~/.claude/skills/discipline-ask-before-act/SKILL.md
当你即将声明任务完成 → 加载 ~/.claude/skills/discipline-test-is-truth/SKILL.md
当你即将写新模块/新接口/新外部调用前 → 加载 ~/.claude/skills/discipline-log-first/SKILL.md
当你即将用任何具体语言/运行时/SDK API 前 → 加载 ~/.claude/skills/discipline-check-versions/SKILL.md
当你即将大批量改代码或要走 QA 监理 → 加载 ~/.claude/skills/discipline-agent-team/SKILL.md
当你即将连续编辑 3+ 文件或改多处实现的接口 → 加载 ~/.claude/skills/discipline-incremental-build/SKILL.md
当你即将删除任何符号/新增源文件 → 加载 ~/.claude/skills/discipline-no-dead-code/SKILL.md
当你即将引用"通常这样做/最佳实践"做理由 → 加载 ~/.claude/skills/discipline-first-principles/SKILL.md
BLOCK
    printf '%s\n' "$MARKER_END"
  } >> "$target"
  info "CLAUDE.md 触发块已注入: $target"
}

inject_claude_md

# ---------- 汇报 ----------
echo
info "完成 ✅"
dim "新装: $INSTALLED · 跳过: $SKIPPED · 覆盖: $OVERWRITTEN · 共 ${#SKILLS[@]} 个 skill"
if [ "$DRY_RUN" = 1 ]; then
  warn "刚才是 DRY RUN —— 重跑去掉 --dry-run 才会真写"
else
  dim "skill 装在: $SKILLS_DIR"
  dim "触发块在: $CLAUDE_MD (标记块: v1)"
  dim "卸载: curl -fsSL https://raw.githubusercontent.com/yli769227-jpg/awesome-claude-code-cn/main/uninstall.sh | bash"
fi
