#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  convert-post.sh  —  Convert a Word blog post to HTML
#  Usage:  bash convert-post.sh <post.docx> [tags]
#
#  Examples:
#    bash convert-post.sh my-post.docx
#    bash convert-post.sh my-post.docx "Wetlands, Remote Sensing"
#
#  Requirements: pandoc  (install: https://pandoc.org/installing.html)
# ─────────────────────────────────────────────────────────────

set -e

# ── Check pandoc is installed ──────────────────────────────────
if ! command -v pandoc &> /dev/null; then
  echo "X  pandoc not found."
  echo "    Install it from: https://pandoc.org/installing.html"
  echo "    macOS:   brew install pandoc"
  echo "    Ubuntu:  sudo apt install pandoc"
  exit 1
fi

# ── Arguments ─────────────────────────────────────────────────
INPUT="$1"
TAGS="${2:-}"   # optional comma-separated tags e.g. "Wetlands, GEE"

if [ -z "$INPUT" ]; then
  echo "Usage: bash convert-post.sh <post.docx> [\"tag1, tag2\"]"
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "X  File not found: $INPUT"
  exit 1
fi

# ── Derive output filename from input (lowercase, hyphens) ─────
BASENAME=$(basename "$INPUT" .docx)
SLUG=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | tr -cd '[:alnum:]-')
DATE_STR=$(date +"%Y-%m-%d")
OUTPUT_NAME="${DATE_STR}-${SLUG}.html"

# ── Output directory: blog/ next to this script ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOG_DIR="${SCRIPT_DIR}/blog"
mkdir -p "$BLOG_DIR"

OUTPUT="${BLOG_DIR}/${OUTPUT_NAME}"
TEMPLATE="${SCRIPT_DIR}/blog-template.html"

if [ ! -f "$TEMPLATE" ]; then
  echo "X  Template not found: $TEMPLATE"
  echo "    Make sure blog-template.html is in the same folder as this script."
  exit 1
fi

# ── Build tags metadata for pandoc ────────────────────────────
TAG_ARGS=()
if [ -n "$TAGS" ]; then
  IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
  for tag in "${TAG_ARRAY[@]}"; do
    trimmed=$(echo "$tag" | xargs)   # trim whitespace
    TAG_ARGS+=(--metadata "tags=$trimmed")
  done
fi

# ── Run pandoc ─────────────────────────────────────────────────
echo "Converting: $INPUT → $OUTPUT"

pandoc "$INPUT" \
  --template="$TEMPLATE" \
  --metadata "date=$(date +'%-d %B %Y')" \
  "${TAG_ARGS[@]}" \
  --wrap=none \
  --standalone \
  -o "$OUTPUT"

echo ""
echo "Done!  →  $OUTPUT"
echo ""
echo "Next steps:"
echo "  1. Open $OUTPUT in a browser to preview"
echo "  2. Add a card for this post in index.html (Blog section)"
echo "  3. git add blog/$OUTPUT_NAME && git commit -m 'Add blog post: $SLUG' && git push"
echo ""
echo "Blog card snippet to paste into index.html:"
echo "──────────────────────────────────────────────"
cat <<CARD
<div class="news-item fade-in">
  <div class="news-date">
    <span class="month">$(date +'%b')</span>
    <span class="year">$(date +'%Y')</span>
  </div>
  <div class="news-body">
    <span class="news-type paper">Blog</span>
    <div class="news-title">YOUR POST TITLE HERE</div>
    <div class="news-detail">
      <a href="blog/${OUTPUT_NAME}">Read post →</a>
    </div>
  </div>
</div>
CARD
echo "──────────────────────────────────────────────"
