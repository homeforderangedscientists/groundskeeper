#!/usr/bin/env bash
#
# Groundskeeper: install / update the engineer + agent playbook system
# in ~/.claude/.
#
# Invocation:
#   Fresh install (additive, never overwrites):
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)"
#
#   Update (refresh upstream-tracked files the user hasn't modified):
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)" _ --update
#
#   Force overwrite (clobber all local changes — destructive):
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)" _ --force
#
#   From a local checkout:
#     ./install.sh [--update|--force]
#
# Modes:
#   install (default) — Additive. Missing files are copied in; existing
#                       files are preserved. Records a manifest of SHAs
#                       for update-mode tracking.
#   --update          — For each shipped file, compare disk SHA to the
#                       SHA recorded at last install. If they match (user
#                       hasn't touched it), refresh to the new version.
#                       If they differ (user-modified), preserve and
#                       report. New shipped files are installed fresh.
#   --force           — Overwrite every shipped file regardless of local
#                       modifications. Destructive. Use with deliberation.
#
# Env vars:
#   GROUNDSKEEPER_REPO    override repo URL (default: upstream)
#   GROUNDSKEEPER_BRANCH  override branch (default: main)
#   CLAUDE_DIR            override install target (default: $HOME/.claude)

set -euo pipefail

# --- mode parsing -----------------------------------------------------------

MODE="install"
for arg in "$@"; do
  case "$arg" in
    --update) MODE="update" ;;
    --force)  MODE="force" ;;
    --help|-h)
      sed -n '2,35p' "${BASH_SOURCE[0]:-$0}" 2>/dev/null | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) echo "unknown flag: $arg (use --help)" >&2; exit 2 ;;
    *)  echo "unexpected argument: $arg (use --help)" >&2; exit 2 ;;
  esac
done

# --- config -----------------------------------------------------------------

REPO_URL="${GROUNDSKEEPER_REPO:-https://github.com/homeforderangedscientists/groundskeeper}"
BRANCH="${GROUNDSKEEPER_BRANCH:-main}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CACHE_DIR="${GROUNDSKEEPER_CACHE:-$HOME/.cache/groundskeeper}"

START_MARKER="# <<< groundskeeper engineer+agent playbook >>>"
END_MARKER="# <<< end groundskeeper >>>"
MANIFEST="$CLAUDE_DIR/.groundskeeper-manifest"

# --- presentation -----------------------------------------------------------

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'
  RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

step()  { echo "${BOLD}${BLUE}==>${RESET} ${BOLD}$1${RESET}"; }
ok()    { echo "    ${GREEN}+${RESET} $1"; }
skip()  { echo "    ${YELLOW}-${RESET} ${DIM}$1${RESET}"; }
warn()  { echo "    ${YELLOW}!${RESET} $1"; }
info()  { echo "    ${BLUE}i${RESET} ${DIM}$1${RESET}"; }
fail()  { echo "${RED}${BOLD}error:${RESET} $1" >&2; exit 1; }

# --- counters ---------------------------------------------------------------

added=0; updated=0; kept=0; preserved=0; forced=0; uptodate=0

# --- sha helpers ------------------------------------------------------------

sha_file() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }
sha_stdin() { shasum -a 256 | awk '{print $1}'; }

manifest_get() {
  [[ -f "$MANIFEST" ]] || return 1
  awk -v k="$1" '$2 == k { print $1; found=1; exit } END { exit !found }' "$MANIFEST"
}

manifest_set() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "$MANIFEST")"
  local tmp; tmp=$(mktemp)
  if [[ -f "$MANIFEST" ]]; then
    awk -v k="$key" '$2 != k' "$MANIFEST" > "$tmp"
  fi
  echo "$val  $key" >> "$tmp"
  mv "$tmp" "$MANIFEST"
}

# --- file installer (the decision tree) -------------------------------------
#
# install_file <src_path> <dest_path> <manifest_key>
#
# Decides what to do based on MODE + manifest + disk state. Updates counters.

install_file() {
  local src="$1" dest="$2" key="$3"
  local name="${key}"

  local src_sha; src_sha=$(sha_file "$src")

  # Case 1: destination missing → fresh install
  if [[ ! -e "$dest" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    manifest_set "$key" "$src_sha"
    ok "$name (new)"
    added=$((added + 1))
    return
  fi

  local disk_sha; disk_sha=$(sha_file "$dest")

  # Case 2: on-disk already matches shipped → nothing to do, just sync manifest
  if [[ "$disk_sha" == "$src_sha" ]]; then
    manifest_set "$key" "$src_sha"
    info "$name (up to date)"
    uptodate=$((uptodate + 1))
    return
  fi

  # Case 3: --force mode → overwrite unconditionally
  if [[ "$MODE" == "force" ]]; then
    cp "$src" "$dest"
    manifest_set "$key" "$src_sha"
    warn "$name (overwritten — --force)"
    forced=$((forced + 1))
    return
  fi

  # Case 4: install mode → preserve user copy (additive behavior)
  if [[ "$MODE" == "install" ]]; then
    skip "$name (exists — keeping your copy; use --update or --force to refresh)"
    kept=$((kept + 1))
    return
  fi

  # Case 5: --update mode
  local recorded_sha
  if recorded_sha=$(manifest_get "$key"); then
    if [[ "$disk_sha" == "$recorded_sha" ]]; then
      # User hasn't touched since install → safe to update
      cp "$src" "$dest"
      manifest_set "$key" "$src_sha"
      ok "$name (updated)"
      updated=$((updated + 1))
    else
      # User has modified → preserve, report
      warn "$name (locally modified — keeping your copy; use --force to overwrite)"
      preserved=$((preserved + 1))
    fi
  else
    # No manifest record → can't distinguish user edit from pre-manifest state
    warn "$name (no manifest record — keeping your copy; use --force to overwrite)"
    preserved=$((preserved + 1))
  fi
}

# --- prereq checks ----------------------------------------------------------

step "Checking prerequisites"
command -v git >/dev/null 2>&1 || fail "git is required but not installed"
command -v curl >/dev/null 2>&1 || fail "curl is required but not installed"
command -v shasum >/dev/null 2>&1 || fail "shasum is required but not installed"
[[ -d "$CLAUDE_DIR" ]] || fail "Claude Code config dir not found at $CLAUDE_DIR — is Claude Code installed?"
ok "git, curl, shasum, and $CLAUDE_DIR present"

# --- source (local checkout or fetch) ---------------------------------------

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/claude-config/playbooks/INDEX.md" && -d "$SCRIPT_DIR/claude-config/skills" ]]; then
  SRC_DIR="$SCRIPT_DIR"
  step "Using local checkout at $SRC_DIR"
  ok "source ready"
else
  step "Fetching groundskeeper ($BRANCH) from $REPO_URL"
  mkdir -p "$(dirname "$CACHE_DIR")"
  if [[ -d "$CACHE_DIR/.git" ]]; then
    git -C "$CACHE_DIR" fetch --quiet origin "$BRANCH"
    git -C "$CACHE_DIR" reset --hard --quiet "origin/$BRANCH"
    ok "updated cache at $CACHE_DIR"
  else
    rm -rf "$CACHE_DIR"
    git clone --quiet --depth 1 --branch "$BRANCH" "$REPO_URL" "$CACHE_DIR"
    ok "cloned to $CACHE_DIR"
  fi
  SRC_DIR="$CACHE_DIR"
fi

# Sanity-check the source layout
[[ -d "$SRC_DIR/claude-config/playbooks" ]] || fail "source missing claude-config/playbooks/"
[[ -d "$SRC_DIR/claude-config/skills" ]] || fail "source missing claude-config/skills/"

# --- announce mode ----------------------------------------------------------

case "$MODE" in
  install) step "Mode: install (additive, never overwrites)" ;;
  update)  step "Mode: update (refresh upstream-tracked files only)" ;;
  force)   step "Mode: ${RED}${BOLD}force${RESET} ${BOLD}(overwrite all shipped files)${RESET}" ;;
esac

# --- install playbooks ------------------------------------------------------

step "Installing playbooks to $CLAUDE_DIR/playbooks/"
mkdir -p "$CLAUDE_DIR/playbooks"
for src in "$SRC_DIR/claude-config/playbooks"/*.md; do
  name="$(basename "$src")"
  install_file "$src" "$CLAUDE_DIR/playbooks/$name" "playbooks/$name"
done

# --- install skills ---------------------------------------------------------

step "Installing skills to $CLAUDE_DIR/skills/"
mkdir -p "$CLAUDE_DIR/skills"
# Walk every file under each skill dir (SKILL.md + examples/*.md + anything else)
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_DIR/claude-config/skills/"}"
  install_file "$src" "$CLAUDE_DIR/skills/$rel" "skills/$rel"
done < <(find "$SRC_DIR/claude-config/skills" -type f -print0)

# --- inject / update CLAUDE.md fragment -------------------------------------

step "Updating $CLAUDE_DIR/CLAUDE.md"
claude_md="$CLAUDE_DIR/CLAUDE.md"
fragment="$SRC_DIR/claude-config/CLAUDE.md.fragment"
[[ -f "$fragment" ]] || fail "fragment missing at $fragment"

fragment_sha=$(sha_file "$fragment")

block_content() {
  # Extract lines *between* the markers (exclusive), preserving exact bytes.
  awk -v s="$START_MARKER" -v e="$END_MARKER" '
    $0 == s { in_block = 1; next }
    $0 == e { in_block = 0; next }
    in_block { print }
  ' "$1"
}

if [[ ! -f "$claude_md" ]]; then
  {
    echo "$START_MARKER"
    cat "$fragment"
    echo "$END_MARKER"
  } > "$claude_md"
  manifest_set "CLAUDE.md.block" "$fragment_sha"
  ok "CLAUDE.md (created with groundskeeper block)"
  added=$((added + 1))
elif ! grep -qF "$START_MARKER" "$claude_md"; then
  {
    echo ""
    echo "$START_MARKER"
    cat "$fragment"
    echo "$END_MARKER"
  } >> "$claude_md"
  manifest_set "CLAUDE.md.block" "$fragment_sha"
  ok "CLAUDE.md block (appended)"
  added=$((added + 1))
else
  current_block_sha=$(block_content "$claude_md" | sha_stdin)

  if [[ "$current_block_sha" == "$fragment_sha" ]]; then
    manifest_set "CLAUDE.md.block" "$fragment_sha"
    info "CLAUDE.md block (up to date)"
    uptodate=$((uptodate + 1))
  elif [[ "$MODE" == "force" ]]; then
    replace_block_in_claude_md=1
  elif [[ "$MODE" == "install" ]]; then
    skip "CLAUDE.md block (exists — keeping your copy; use --update or --force to refresh)"
    kept=$((kept + 1))
  else
    # update mode
    if recorded_block_sha=$(manifest_get "CLAUDE.md.block"); then
      if [[ "$current_block_sha" == "$recorded_block_sha" ]]; then
        replace_block_in_claude_md=1
      else
        warn "CLAUDE.md block (locally modified — keeping your copy; use --force to overwrite)"
        preserved=$((preserved + 1))
      fi
    else
      warn "CLAUDE.md block (no manifest record — keeping your copy; use --force to overwrite)"
      preserved=$((preserved + 1))
    fi
  fi

  if [[ "${replace_block_in_claude_md:-0}" == "1" ]]; then
    tmp=$(mktemp)
    awk -v s="$START_MARKER" -v e="$END_MARKER" -v frag="$fragment" '
      BEGIN { while ((getline line < frag) > 0) frag_lines = frag_lines line "\n" }
      $0 == s { print; printf "%s", frag_lines; in_block = 1; next }
      $0 == e { print; in_block = 0; next }
      !in_block { print }
    ' "$claude_md" > "$tmp"
    mv "$tmp" "$claude_md"
    manifest_set "CLAUDE.md.block" "$fragment_sha"
    if [[ "$MODE" == "force" ]]; then
      warn "CLAUDE.md block (overwritten — --force)"
      forced=$((forced + 1))
    else
      ok "CLAUDE.md block (updated)"
      updated=$((updated + 1))
    fi
  fi
fi

# --- summary ----------------------------------------------------------------

total=$((added + updated + uptodate + kept + preserved + forced))

echo
case "$MODE" in
  install) echo "${BOLD}${GREEN}Groundskeeper installed.${RESET}" ;;
  update)  echo "${BOLD}${GREEN}Groundskeeper updated.${RESET}" ;;
  force)   echo "${BOLD}${YELLOW}Groundskeeper force-overwritten.${RESET}" ;;
esac
echo
echo "  Total shipped items checked: ${BOLD}$total${RESET}"
echo "  ${GREEN}new:${RESET}         $added    (newly installed)"
echo "  ${GREEN}updated:${RESET}     $updated    (refreshed from upstream)"
echo "  ${BLUE}up-to-date:${RESET}  $uptodate    (matched upstream — no action)"
echo "  ${DIM}kept:${RESET}        $kept    (exists, not refreshed — use --update)"
echo "  ${YELLOW}preserved:${RESET}   $preserved    (locally modified — keeping yours)"
echo "  ${RED}forced:${RESET}      $forced    (overwritten by --force)"
echo
echo "Manifest: $MANIFEST"
echo
echo "Next steps:"
echo "  - Restart Claude Code to pick up changes."
echo "  - Read $CLAUDE_DIR/playbooks/INDEX.md for the task-to-playbook map."
echo "  - Install the ${BOLD}superpowers${RESET} plugin if not present — five playbooks depend on it."
echo "    See $CLAUDE_DIR/playbooks/prereqs.md."
echo
if [[ "$MODE" == "install" && $kept -gt 0 ]]; then
  echo "To refresh kept files:"
  echo "  Re-run with ${BOLD}--update${RESET} to refresh files you haven't modified."
  echo "  Re-run with ${BOLD}--force${RESET} to overwrite everything (destructive)."
  echo
fi
if [[ "$MODE" == "update" && $preserved -gt 0 ]]; then
  echo "To overwrite preserved (locally-modified) files:"
  echo "  Re-run with ${BOLD}--force${RESET} — this will discard your local changes."
  echo
fi
