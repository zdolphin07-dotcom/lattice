#!/usr/bin/env bash
# loader.sh — Knowledge base loader
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "knowledge load" "Load project knowledge by keyword" \
    "loader.sh <keyword> [keyword2] ...   Match and output knowledge files by keyword" \
    "loader.sh --list                     List all knowledge entries" \
    "loader.sh --all                      Output all knowledge file contents"
done

KNOWLEDGE_DIR="$PROJECT_ROOT/$(manifest_get '.knowledge.local_dir')"
KNOWLEDGE_DIR="${KNOWLEDGE_DIR:-$PROJECT_ROOT/lattice/knowledge}"
INDEX_FILE="$KNOWLEDGE_DIR/index.md"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "⚠️  Knowledge index not found: $INDEX_FILE"
  exit 0
fi

MODE="search"
KEYWORDS=()

for arg in "$@"; do
  case "$arg" in
    --all)  MODE="all" ;;
    --list) MODE="list" ;;
    *)      KEYWORDS+=("$arg") ;;
  esac
done

if [[ "$MODE" == "list" ]]; then
  echo "📚 Knowledge Index:"
  echo ""
  cat "$INDEX_FILE"
  exit 0
fi

if [[ "$MODE" == "all" ]]; then
  echo "📚 Loading all knowledge files:"
  echo ""
  for f in "$KNOWLEDGE_DIR"/*.md; do
    [[ "$(basename "$f")" == "index.md" ]] && continue
    [[ -f "$f" ]] || continue
    echo "────────────────────────────────"
    echo "📄 $(basename "$f")"
    echo "────────────────────────────────"
    cat "$f"
    echo ""
  done
  exit 0
fi

_fuzzy_match() {
  local keyword="$1" text="$2"
  echo "$text" | grep -qi "$keyword" && return 0
  local syn_file="$KNOWLEDGE_DIR/synonyms.txt"
  if [[ -f "$syn_file" ]]; then
    while IFS= read -r syn_line; do
      [[ -z "$syn_line" || "$syn_line" == \#* ]] && continue
      if echo "$syn_line" | grep -qi "$keyword"; then
        for syn_word in $syn_line; do
          echo "$text" | grep -qi "$syn_word" && return 0
        done
      fi
    done < "$syn_file"
  fi
  return 1
}

if [[ ${#KEYWORDS[@]} -eq 0 ]]; then
  echo "Usage: loader.sh <keyword1> [keyword2] ..."
  echo "       loader.sh --all | --list"
  exit 1
fi

echo "🔍 Searching keywords: ${KEYWORDS[*]}"
echo ""

MATCHED=0
while IFS= read -r line; do
  slug=""
  matched_kw=""
  for kw in "${KEYWORDS[@]}"; do
    if _fuzzy_match "$kw" "$line"; then
      slug=$(echo "$line" | sed -n 's/.*`\([^`]*\)`.*/\1/p')
      matched_kw="$kw"
      break
    fi
  done

  if [[ -n "$slug" ]]; then
    local_file="$KNOWLEDGE_DIR/${slug}.md"
    if [[ -f "$local_file" ]]; then
      echo "────────────────────────────────"
      echo "📄 ${slug}.md (matched keyword: $matched_kw)"
      echo "────────────────────────────────"
      cat "$local_file"
      echo ""
      ((MATCHED++))
    fi
  fi
done < "$INDEX_FILE"

if [[ $MATCHED -eq 0 ]]; then
  echo "⏭️  No matching knowledge found (exact + synonym match)"
  echo "💡 Try broader keywords, or run loader.sh --all to see all entries"
else
  echo "📊 Loaded $MATCHED knowledge entries"
fi
