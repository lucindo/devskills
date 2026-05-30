# profile.sh — shared language-profile installer for devskills.
#
# Sourced by install.sh and scripts/setup.sh. Writes the language profile
# into AGENTS.md (the canonical, cross-tool instructions file) inside a
# managed block, and makes CLAUDE.md import it via `@AGENTS.md` so Claude
# Code and OpenCode read the same content with no duplication.
#
# Behavior:
#   - Never clobbers: existing files are backed up (sibling .bak) before
#     any change, and only when the content actually changes.
#   - Idempotent: re-running with the same profile is a no-op; re-running
#     with a different --lang replaces the managed block in place.

[ -n "${DEVSKILLS_PROFILE_LIB:-}" ] && return 0
DEVSKILLS_PROFILE_LIB=1

_dsk_log()  { printf '[devskills] %s\n' "$1"; }
_dsk_warn() { printf '[devskills] WARN: %s\n' "$1" >&2; }

# Back up a file to a sibling, timestamped .bak. One stamp per run.
_dsk_backup() {
  local f="$1"
  : "${DEVSKILLS_STAMP:=$(date +%Y%m%d-%H%M%S)}"
  local bak="${f}.${DEVSKILLS_STAMP}.bak"
  cp "$f" "$bak"
  _dsk_log "backed up $(basename "$f") -> $(basename "$bak")"
}

# Insert or replace a managed block in a file.
#   $1 file  $2 block id  $3 file holding the full block (incl. markers)
#   $4 dry-run (1|0)  $5 display label
# Returns without writing when the result would be byte-identical.
_dsk_upsert_block() {
  local file="$1" id="$2" block_file="$3" dry="$4" label="${5:-$1}"
  local begin="<!-- BEGIN devskills:${id} -->"
  local end="<!-- END devskills:${id} -->"
  local tmp; tmp="$(mktemp)"

  if [ -f "$file" ] && grep -qF "$begin" "$file"; then
    # Replace the existing block in place.
    awk -v b="$begin" -v e="$end" -v bf="$block_file" '
      $0 == b { while ((getline line < bf) > 0) print line; close(bf); skip = 1; next }
      skip && $0 == e { skip = 0; next }
      skip { next }
      { print }
    ' "$file" > "$tmp"
  else
    # Append, preserving existing content with a blank-line separator.
    if [ -f "$file" ] && [ -s "$file" ]; then
      cat "$file" > "$tmp"
      [ -z "$(tail -c1 "$file")" ] || printf '\n' >> "$tmp"
      printf '\n' >> "$tmp"
    fi
    cat "$block_file" >> "$tmp"
  fi

  if [ -f "$file" ] && cmp -s "$tmp" "$file"; then
    _dsk_log "${label} already up to date."
    rm -f "$tmp"
    return 0
  fi

  if [ "$dry" = "1" ]; then
    if [ -f "$file" ]; then
      _dsk_log "[dry] would back up ${label} and update it."
    else
      _dsk_log "[dry] would create ${label}."
    fi
    rm -f "$tmp"
    return 0
  fi

  if [ -f "$file" ]; then
    _dsk_backup "$file"
    mv "$tmp" "$file"
    _dsk_log "updated ${label}"
  else
    mv "$tmp" "$file"
    _dsk_log "created ${label}"
  fi
}

# Apply a language profile to a project directory.
#   $1 lang  $2 profile .md file  $3 target dir  $4 dry-run (1|0)
devskills_apply_profile() {
  local lang="$1" profile="$2" dir="$3" dry="$4"
  local agents="${dir}/AGENTS.md"
  local claude="${dir}/CLAUDE.md"

  # 1. Canonical profile -> AGENTS.md (managed block).
  local blk; blk="$(mktemp)"
  {
    echo "<!-- BEGIN devskills:language -->"
    echo "<!-- profile: ${lang} — managed by devskills; edits between these markers are overwritten -->"
    cat "$profile"
  } > "$blk"
  [ -z "$(tail -c1 "$profile")" ] || printf '\n' >> "$blk"
  echo "<!-- END devskills:language -->" >> "$blk"
  _dsk_upsert_block "$agents" "language" "$blk" "$dry" "AGENTS.md"
  rm -f "$blk"

  # 2. CLAUDE.md imports AGENTS.md (skip if it already imports it manually).
  if [ -f "$claude" ] && grep -qE '^[[:space:]]*@AGENTS\.md' "$claude" \
       && ! grep -qF "<!-- BEGIN devskills:import -->" "$claude"; then
    _dsk_log "CLAUDE.md already imports AGENTS.md; leaving as-is."
  else
    local imp; imp="$(mktemp)"
    {
      echo "<!-- BEGIN devskills:import -->"
      echo "@AGENTS.md"
      echo "<!-- END devskills:import -->"
    } > "$imp"
    _dsk_upsert_block "$claude" "import" "$imp" "$dry" "CLAUDE.md"
    rm -f "$imp"
  fi

  # 3. Flag a legacy inline profile from older devskills versions.
  if [ -f "$claude" ] && grep -qF "devskills language profile" "$claude"; then
    _dsk_warn "CLAUDE.md has a legacy inline devskills profile."
    _dsk_warn "The profile now lives in AGENTS.md — remove the old inline block from CLAUDE.md."
  fi

  # 4. Record the active language.
  if [ "$dry" = "1" ]; then
    _dsk_log "[dry] would write ${dir}/.devskills/language: ${lang}"
  else
    mkdir -p "${dir}/.devskills"
    echo "${lang}" > "${dir}/.devskills/language"
    _dsk_log "wrote .devskills/language: ${lang}"
  fi
}
