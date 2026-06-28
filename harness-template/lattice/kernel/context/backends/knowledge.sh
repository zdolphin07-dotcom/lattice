#!/usr/bin/env bash
# knowledge.sh — Search curated project context knowledge.
#
# This is a retrieval backend, not the Context Discovery workflow.
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "context knowledge" "Search project context knowledge files" \
    "knowledge.sh <keyword> [keyword2] ...   Search knowledge files" \
    "knowledge.sh --list                     List knowledge files" \
    "knowledge.sh --all                      Output all knowledge files"
done

knowledge_dir=$(manifest_get '.context.knowledge.dir')
KNOWLEDGE_DIR="${PROJECT_ROOT}/${knowledge_dir:-lattice/context/knowledge}"

MODE="search"
KEYWORDS=()

for arg in "$@"; do
  case "$arg" in
    --all)  MODE="all" ;;
    --list) MODE="list" ;;
    *)      KEYWORDS+=("$arg") ;;
  esac
done

knowledge_files() {
  [[ -d "$KNOWLEDGE_DIR" ]] || return 0
  find "$KNOWLEDGE_DIR" -type f -name "*.md" 2>/dev/null | sort
}

print_file() {
  local file="$1"
  local label="${file#$PROJECT_ROOT/}"
  echo "────────────────────────────────"
  echo "📄 $label"
  echo "────────────────────────────────"
  cat "$file"
  echo ""
}

if [[ "$MODE" == "list" ]]; then
  echo "📚 Context Knowledge Files"
  echo ""
  knowledge_files | sed "s#^$PROJECT_ROOT/##"
  exit 0
fi

if [[ "$MODE" == "all" ]]; then
  echo "📚 Loading all context knowledge files"
  echo ""
  while IFS= read -r file; do
    [[ -n "$file" ]] && print_file "$file"
  done < <(knowledge_files)
  exit 0
fi

if [[ ${#KEYWORDS[@]} -eq 0 ]]; then
  echo "Usage: knowledge.sh <keyword1> [keyword2] ..."
  echo "       knowledge.sh --all | --list"
  exit 1
fi

echo "🔍 Searching context knowledge: ${KEYWORDS[*]}"
echo ""

MATCHED=0
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  haystack="$(cat "$file")"
  for kw in "${KEYWORDS[@]}"; do
    if echo "$haystack" | grep -qi -- "$kw"; then
      print_file "$file"
      ((MATCHED++)) || true
      break
    fi
  done
done < <(knowledge_files)

if [[ $MATCHED -eq 0 ]]; then
  echo "⏭️  No matching context knowledge found"
  echo "💡 Try broader keywords, or run knowledge.sh --list to see available files"
else
  echo "📊 Loaded $MATCHED context knowledge files"
fi
