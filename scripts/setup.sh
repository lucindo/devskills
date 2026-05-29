#!/usr/bin/env bash
# setup.sh: configure devskills for the current project directory
set -euo pipefail

DEVSKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<EOF
Usage: setup.sh --lang=<profile> [options]

Profiles:
  go                Go 1.22+ backend service
  typescript        TypeScript 5+ (Workers, Next.js, React)
  javascript        ES2022+ (Workers, vanilla frontend)
  rust              Rust stable (systems programming, large projects)

Options:
  --cursor          Install Cursor rules into current project
  --vscode          Install VSCode Copilot instructions into current project
  --dry-run         Show what would happen without writing files

Example:
  setup.sh --lang=go --cursor
  setup.sh --lang=typescript --vscode --cursor
EOF
}

LANG=""
DO_CURSOR=0
DO_VSCODE=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --lang=*) LANG="${arg#--lang=}" ;;
    --claude-dir=*|--skip-cursor|--skip-vscode|--skip-external) ;;  # install-only flags; ignored here
    --cursor) DO_CURSOR=1 ;;
    --vscode) DO_VSCODE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $arg"; usage; exit 1 ;;
  esac
done

if [ -z "$LANG" ]; then
  echo "Error: --lang is required"
  usage
  exit 1
fi

install() {
  local src="$1" dst="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry] $src -> $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  wrote $dst"
}

# Language profile into CLAUDE.md
PROFILE="${DEVSKILLS_DIR}/prompts/language/${LANG}.md"
if [ ! -f "$PROFILE" ]; then
  echo "Error: no profile for '${LANG}'. Available: go, typescript, javascript, rust"
  exit 1
fi

CLAUDE_MD="${PWD}/CLAUDE.md"
echo "Language profile: ${LANG}"

if [ "$DRY_RUN" -eq 0 ]; then
  if [ -f "$CLAUDE_MD" ] && grep -q "devskills language profile" "$CLAUDE_MD" 2>/dev/null; then
    echo "  CLAUDE.md already has a devskills profile. Edit manually to change: ${CLAUDE_MD}"
  else
    {
      [ -f "$CLAUDE_MD" ] && echo ""
      echo "<!-- devskills language profile: ${LANG} -->"
      cat "$PROFILE"
    } >> "$CLAUDE_MD"
    echo "  updated $CLAUDE_MD"
  fi
  mkdir -p "${PWD}/.devskills"
  echo "${LANG}" > "${PWD}/.devskills/language"
  echo "  wrote .devskills/language"
else
  echo "[dry] would append ${LANG} profile to $CLAUDE_MD"
  echo "[dry] would write .devskills/language"
fi

# Cursor rules
if [ "$DO_CURSOR" -eq 1 ]; then
  echo "Cursor rules:"
  mkdir -p "${PWD}/.cursor/rules"
  install "${DEVSKILLS_DIR}/cursor/rules/tiger-style.mdc" "${PWD}/.cursor/rules/tiger-style.mdc"
  case "$LANG" in
    go)         install "${DEVSKILLS_DIR}/cursor/rules/go.mdc"         "${PWD}/.cursor/rules/go.mdc" ;;
    typescript) install "${DEVSKILLS_DIR}/cursor/rules/typescript.mdc" "${PWD}/.cursor/rules/typescript.mdc" ;;
    javascript) install "${DEVSKILLS_DIR}/cursor/rules/typescript.mdc" "${PWD}/.cursor/rules/typescript.mdc" ;;
    rust)       install "${DEVSKILLS_DIR}/cursor/rules/rust.mdc"       "${PWD}/.cursor/rules/rust.mdc" ;;
  esac
fi

# VSCode Copilot
if [ "$DO_VSCODE" -eq 1 ]; then
  echo "VSCode Copilot:"
  install \
    "${DEVSKILLS_DIR}/vscode/copilot-instructions.md" \
    "${PWD}/.github/copilot-instructions.md"
fi

echo ""
echo "Done. Active language profile: ${LANG}"
echo "Activate in Claude Code: /tiger-style"
