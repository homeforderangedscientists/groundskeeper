#!/usr/bin/env bash
#
# Groundskeeper: install the engineer + agent playbook system into ~/.claude/.
#
# Invocation:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/homeforderangedscientists/groundskeeper/main/install.sh)"
#
# Or from a local checkout:
#   ./install.sh
#
# Behavior:
#   - Additive only. Never overwrites existing files.
#   - Existing playbooks, skills, and CLAUDE.md blocks are preserved.
#   - Run it twice: second run is a no-op except for new files upstream.
#
# Env vars:
#   GROUNDSKEEPER_REPO    override repo URL (default: upstream)
#   GROUNDSKEEPER_BRANCH  override branch (default: main)
#   CLAUDE_DIR            override install target (default: $HOME/.claude)

set -euo pipefail

# --- config -----------------------------------------------------------------

REPO_URL="${GROUNDSKEEPER_REPO:-https://github.com/homeforderangedscientists/groundskeeper}"
BRANCH="${GROUNDSKEEPER_BRANCH:-main}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CACHE_DIR="${GROUNDSKEEPER_CACHE:-$HOME/.cache/groundskeeper}"

START_MARKER="# <<< groundskeeper engineer+agent playbook >>>"
END_MARKER="# <<< end groundskeeper >>>"

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
fail()  { echo "${RED}${BOLD}error:${RESET} $1" >&2; exit 1; }

# --- prereq checks ----------------------------------------------------------

step "Checking prerequisites"
command -v git >/dev/null 2>&1 || fail "git is required but not installed"
command -v curl >/dev/null 2>&1 || fail "curl is required but not installed"
[[ -d "$CLAUDE_DIR" ]] || fail "Claude Code config dir not found at $CLAUDE_DIR — is Claude Code installed?"
ok "git, curl, and $CLAUDE_DIR present"

# --- source (local checkout or fetch) ---------------------------------------

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/docs/agent-playbooks/INDEX.md" && -d "$SCRIPT_DIR/claude-config" ]]; then
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
[[ -d "$SRC_DIR/docs/agent-playbooks" ]] || fail "source missing docs/agent-playbooks/"
[[ -d "$SRC_DIR/claude-config" ]] || fail "source missing claude-config/"

# --- install playbooks ------------------------------------------------------

step "Installing playbooks to $CLAUDE_DIR/playbooks/"
mkdir -p "$CLAUDE_DIR/playbooks"

playbooks_added=0
playbooks_skipped=0
for src in "$SRC_DIR/docs/agent-playbooks"/*.md; do
  name="$(basename "$src")"
  dest="$CLAUDE_DIR/playbooks/$name"
  if [[ -e "$dest" ]]; then
    skip "$name (already installed — keeping your copy)"
    playbooks_skipped=$((playbooks_skipped + 1))
  else
    cp "$src" "$dest"
    ok "$name"
    playbooks_added=$((playbooks_added + 1))
  fi
done

# --- install skills ---------------------------------------------------------

step "Installing skills to $CLAUDE_DIR/skills/"
mkdir -p "$CLAUDE_DIR/skills"

skills_added=0
skills_skipped=0
for src_skill in "$SRC_DIR/claude-config/skills"/*/; do
  name="$(basename "$src_skill")"
  dest="$CLAUDE_DIR/skills/$name"
  if [[ -d "$dest" ]]; then
    skip "$name (already installed — keeping your copy)"
    skills_skipped=$((skills_skipped + 1))
  else
    cp -R "$src_skill" "$dest"
    ok "$name"
    skills_added=$((skills_added + 1))
  fi
done

# --- inject CLAUDE.md fragment ----------------------------------------------

step "Updating $CLAUDE_DIR/CLAUDE.md"
claude_md="$CLAUDE_DIR/CLAUDE.md"
fragment="$SRC_DIR/claude-config/CLAUDE.md.fragment"
[[ -f "$fragment" ]] || fail "fragment missing at $fragment"

if [[ ! -f "$claude_md" ]]; then
  {
    echo "$START_MARKER"
    cat "$fragment"
    echo "$END_MARKER"
  } > "$claude_md"
  ok "created CLAUDE.md with groundskeeper block"
elif grep -qF "$START_MARKER" "$claude_md"; then
  skip "CLAUDE.md already has groundskeeper block — not modifying (delete the block and re-run to refresh)"
else
  {
    echo ""
    echo "$START_MARKER"
    cat "$fragment"
    echo "$END_MARKER"
  } >> "$claude_md"
  ok "appended groundskeeper block to CLAUDE.md"
fi

# --- summary ----------------------------------------------------------------

echo
echo "${BOLD}${GREEN}Groundskeeper installed.${RESET}"
echo
echo "  Playbooks: ${BOLD}$playbooks_added${RESET} added, ${DIM}$playbooks_skipped kept${RESET}"
echo "  Skills:    ${BOLD}$skills_added${RESET} added, ${DIM}$skills_skipped kept${RESET}"
echo
echo "Next steps:"
echo "  1. Restart Claude Code to pick up the new CLAUDE.md and skills."
echo "  2. Read $CLAUDE_DIR/playbooks/INDEX.md for the task-to-playbook map."
echo "  3. Install the superpowers plugin if not present — five playbooks depend on it."
echo "     See $CLAUDE_DIR/playbooks/prereqs.md for details."
echo
echo "To refresh:"
echo "  - Delete the file you want replaced, re-run this script, and it reinstalls."
echo "  - Or set CLAUDE_DIR=/tmp/preview to do a dry run against a scratch dir."
echo
