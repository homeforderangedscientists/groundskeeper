#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc not found. Install with: brew install pandoc" >&2
  exit 1
fi

ENGINE=""
for candidate in xelatex tectonic wkhtmltopdf pdflatex; do
  if command -v "$candidate" >/dev/null 2>&1; then
    ENGINE="$candidate"
    break
  fi
done

if [[ -z "$ENGINE" ]]; then
  echo "No PDF engine found. Install one of: tectonic, xelatex, wkhtmltopdf" >&2
  echo "  brew install tectonic   # simplest" >&2
  exit 1
fi

FILTER_ARGS=()
if command -v mermaid-filter >/dev/null 2>&1; then
  FILTER_ARGS+=(--filter mermaid-filter)
else
  echo "note: mermaid-filter not found; mermaid blocks will render as code." >&2
  echo "      install with: npm install -g mermaid-filter" >&2
fi

# Replace emoji/symbols that LaTeX text fonts cannot render with bracketed labels.
preprocess() {
  python3 -c '
import sys
replacements = {
    "\u26A0\uFE0F": "[WARNING]",
    "\u26A0": "[WARNING]",
    "\u2705": "[OK]",
    "\u274C": "[X]",
    "\u2713": "[YES]",
    "\u2717": "[NO]",
    "\U0001F4A1": "[TIP]",
    "\U0001F7E5": "[RED]",
    "\U0001F7E6": "[BLUE]",
    "\U0001F7E7": "[ORANGE]",
    "\U0001F7E8": "[YELLOW]",
    "\U0001F7E9": "[GREEN]",
    "\uFE0F": "",
}
data = sys.stdin.read()
for k, v in replacements.items():
    data = data.replace(k, v)
sys.stdout.write(data)
' < "$1"
}

shopt -s nullglob
files=(*.md)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No markdown files found in $(pwd)" >&2
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for md in "${files[@]}"; do
  pdf="${md%.md}.pdf"
  tmpmd="$tmpdir/${md}"
  echo "→ $md → $pdf"
  preprocess "$md" > "$tmpmd"
  pandoc "$tmpmd" \
    "${FILTER_ARGS[@]}" \
    --pdf-engine="$ENGINE" \
    --from=gfm \
    --standalone \
    --toc \
    --resource-path="$(pwd):$tmpdir" \
    -V geometry:margin=1in \
    -o "$pdf"
done

rm -f mermaid-filter.err

echo "Done. ${#files[@]} file(s) converted."
