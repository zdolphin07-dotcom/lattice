#!/usr/bin/env bash
# sync.sh — Central context knowledge sync
#
# Usage:
#   sync.sh pull          — Pull shared knowledge from central repo
#   sync.sh push          — Push project knowledge to central repo
#   sync.sh status        — View sync status
#
# Config: manifest.yaml context.central

source "$(dirname "$0")/../_lib.sh"

knowledge_dir=$(manifest_get '.context.knowledge.dir')
central_cache_dir=$(manifest_get '.context.central.cache_dir')
PROJECT_KNOWLEDGE_DIR="${PROJECT_ROOT}/${knowledge_dir:-lattice/context/knowledge}"
CENTRAL_CACHE_DIR="${PROJECT_ROOT}/${central_cache_dir:-lattice/context/.central}"
REMOTE_DIR="$CENTRAL_CACHE_DIR/.remote"

CENTRAL_REPO=$(manifest_get '.context.central.repo')
SYNC_MODE=$(manifest_get '.context.central.mode')
SYNC_MODE="${SYNC_MODE:-read-only}"
CONFLICT_POLICY=$(manifest_get '.context.central.conflict')
CONFLICT_POLICY="${CONFLICT_POLICY:-project-wins}"

ACTION="${1:-status}"

if [[ -z "$CENTRAL_REPO" ]]; then
  echo "⚠️  Central context repo not configured"
  echo "   Add to manifest.yaml:"
  echo "   context:"
  echo "     central:"
  echo "       repo: https://github.com/your-org/context-knowledge.git"
  exit 0
fi

case "$ACTION" in
  pull)
    echo "📥 Pulling central context knowledge..."
    echo "   Repo: $CENTRAL_REPO"

    if [[ -d "$REMOTE_DIR/.git" ]]; then
      git -C "$REMOTE_DIR" pull --quiet 2>/dev/null || {
        echo "⚠️  Pull failed, using local cache"
        exit 0
      }
    else
      mkdir -p "$REMOTE_DIR"
      git clone --depth=1 --quiet "$CENTRAL_REPO" "$REMOTE_DIR" 2>/dev/null || {
        echo "⚠️  Clone failed, skipping central context knowledge"
        echo "   Check repo URL and permissions: $CENTRAL_REPO"
        exit 0
      }
    fi

    mkdir -p "$CENTRAL_CACHE_DIR"
    SYNCED=0
    while IFS= read -r -d '' f; do
      fname="$(basename "$f")"
      [[ "$fname" == ".git" ]] && continue
      local_file="$CENTRAL_CACHE_DIR/$fname"

      if [[ -f "$local_file" ]]; then
        case "$CONFLICT_POLICY" in
          project-wins|prefer-local)  echo "  ⏭️  Keeping local central cache: $fname" ;;
          central-wins|prefer-remote) cp "$f" "$local_file"; echo "  🔄 Updated from central: $fname" ;;
          fail)                       echo "  ❌ Conflict: $fname"; exit 1 ;;
          *)                          echo "  ⏭️  Unknown conflict policy, keeping local: $fname" ;;
        esac
      else
        cp "$f" "$local_file"
        echo "  ✅ Added: $fname"
        ((SYNCED++)) || true
      fi
    done < <(find "$REMOTE_DIR" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)

    echo ""
    echo "📊 Sync complete: $SYNCED new entries"
    ;;

  push)
    if [[ "$SYNC_MODE" == "read-only" ]]; then
      echo "❌ Central context repo is read-only, push not supported"
      echo "   Set manifest.yaml context.central.mode: read-write"
      exit 1
    fi

    echo "📤 Pushing project knowledge to central context repo..."
    if [[ ! -d "$REMOTE_DIR/.git" ]]; then
      echo "❌ Run sync.sh pull first to initialize"
      exit 1
    fi

    find "$PROJECT_KNOWLEDGE_DIR" -maxdepth 2 -type f -name "*.md" -exec cp {} "$REMOTE_DIR/" \; 2>/dev/null || true
    git -C "$REMOTE_DIR" add -A
    if git -C "$REMOTE_DIR" diff --cached --quiet; then
      echo "  ⏭️  No changes"
    else
      git -C "$REMOTE_DIR" commit -m "sync: context knowledge from $(manifest_get '.project.name')" --quiet
      git -C "$REMOTE_DIR" push --quiet || { echo "❌ Push failed"; exit 1; }
      echo "  ✅ Push successful"
    fi
    ;;

  status)
    echo "📚 Context Knowledge Status:"
    echo "  Project knowledge dir: $PROJECT_KNOWLEDGE_DIR"
    echo "  Central cache dir: $CENTRAL_CACHE_DIR"
    echo "  Central repo: ${CENTRAL_REPO:-not configured}"
    echo "  Sync mode: $SYNC_MODE"
    echo "  Conflict policy: $CONFLICT_POLICY"
    echo ""

    project_count=$(find "$PROJECT_KNOWLEDGE_DIR" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    central_count=$(find "$CENTRAL_CACHE_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Project entries: $project_count"
    echo "  Central entries: $central_count"

    if [[ -d "$REMOTE_DIR/.git" ]]; then
      remote_count=$(find "$REMOTE_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      echo "  Remote cache: $remote_count"
    else
      echo "  Remote cache: not initialized (run sync.sh pull)"
    fi
    ;;

  *)
    echo "Usage: sync.sh [pull|push|status]"
    exit 1
    ;;
esac
