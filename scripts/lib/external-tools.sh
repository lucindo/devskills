# external-tools.sh — shared tldt installer for devskills.
#
# Sourced by install.sh and scripts/upgrade-deps.sh. `go install @latest`
# always fetches the newest published version, so the command is the same
# for both install and upgrade modes.
#
# Logging: install.sh and upgrade-deps.sh each define log()/warn() with their
# own prefix; this lib uses theirs (resolved at call time). DRY_RUN (0|1) is
# honored; defaults to 0.

[ -n "${DEVSKILLS_EXTERNAL_LIB:-}" ] && return 0
DEVSKILLS_EXTERNAL_LIB=1

# Run a command, or just describe it under --dry-run.
#   $1 human-readable description  $2.. command + args
run_or_dry() {
  local desc="$1"; shift
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log "[dry] would ${desc}"
    return 0
  fi
  "$@"
}

# ------------------------------------------------------------
# osv-scanner (Google OSV vulnerability scanner)
# ------------------------------------------------------------

# Install or upgrade osv-scanner. Prefers Homebrew on macOS; falls back to
# `go install` when Go is present.
#   $1 mode (install|upgrade)
devskills_osv() {
  local mode="$1" verbing="Installing" verb="Install"
  [ "$mode" = upgrade ] && { verbing="Upgrading"; verb="Upgrade"; }

  if [ "$mode" = install ] && command -v osv-scanner &>/dev/null; then
    log "osv-scanner already installed at $(command -v osv-scanner). Skipping."
    return 0
  fi

  if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
    log "${verbing} osv-scanner via Homebrew..."
    if [ "$mode" = upgrade ]; then
      run_or_dry "run brew upgrade osv-scanner" \
        brew upgrade osv-scanner || brew install osv-scanner || warn "osv-scanner brew upgrade failed."
    else
      run_or_dry "run brew install osv-scanner" \
        brew install osv-scanner || warn "osv-scanner brew install failed. See: https://github.com/google/osv-scanner"
    fi
    return 0
  fi

  if command -v go &>/dev/null; then
    log "${verbing} osv-scanner via go install..."
    run_or_dry "run go install github.com/google/osv-scanner/cmd/osv-scanner@latest" \
      go install github.com/google/osv-scanner/cmd/osv-scanner@latest
    if [ "${DRY_RUN:-0}" -eq 0 ]; then
      log "osv-scanner ready at $(go env GOPATH)/bin/osv-scanner"
    fi
    return 0
  fi

  warn "osv-scanner: no Homebrew or Go found. ${verb} manually: https://github.com/google/osv-scanner/releases"
}

# ------------------------------------------------------------
# tldt
# ------------------------------------------------------------

# Install or upgrade tldt. `go install @latest` always fetches the newest
# published version, so the command is the same for both modes.
#   $1 mode (install|upgrade)
devskills_tldt() {
  local mode="$1" verbing="Installing" verb="Install"
  [ "$mode" = upgrade ] && { verbing="Upgrading"; verb="Upgrade"; }

  if command -v go &>/dev/null; then
    log "${verbing} tldt..."
    run_or_dry "run go install github.com/gleicon/tldt/cmd/tldt@latest" \
      go install github.com/gleicon/tldt/cmd/tldt@latest
    if [ "${DRY_RUN:-0}" -eq 0 ]; then
      log "tldt ready at $(go env GOPATH)/bin/tldt"
    fi
  else
    warn "Go not found. ${verb} tldt manually: https://github.com/gleicon/tldt"
  fi
}
