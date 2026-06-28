#!/usr/bin/env bash
# pr-comment.sh - Publish or render a stable Lattice eval PR comment.
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "pr comment" "Publish eval summary as a pull request comment" \
    "pr-comment.sh <summary.md> --pr=<number> --repo=<owner/repo>    Create or update PR comment" \
    "pr-comment.sh <summary.md> --dry-run --out=<file>              Render comment body without calling GitHub"
done

SUMMARY_MD=""
OUT=""
PR_NUMBER="${PR_NUMBER:-}"
REPO="${GITHUB_REPOSITORY:-}"
DRY_RUN=false
MARKER="<!-- lattice-eval-comment -->"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --out=*) OUT="${1#--out=}" ;;
    --out)
      shift
      OUT="${1:-}"
      ;;
    --pr=*) PR_NUMBER="${1#--pr=}" ;;
    --repo=*) REPO="${1#--repo=}" ;;
    --marker=*) MARKER="${1#--marker=}" ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      if [[ -z "$SUMMARY_MD" ]]; then
        SUMMARY_MD="$1"
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$SUMMARY_MD" ]]; then
  echo "Usage: pr-comment.sh <summary.md> [--dry-run] [--out=<file>] [--pr=<number>] [--repo=<owner/repo>]"
  exit 1
fi

[[ "$SUMMARY_MD" == /* ]] || SUMMARY_MD="$PROJECT_ROOT/$SUMMARY_MD"
[[ -f "$SUMMARY_MD" ]] || { echo "Summary markdown not found: $SUMMARY_MD"; exit 1; }

if [[ -n "$OUT" && "$OUT" != /* ]]; then
  OUT="$PROJECT_ROOT/$OUT"
fi

render_body() {
  printf '%s\n\n' "$MARKER"
  cat "$SUMMARY_MD"
}

if [[ "$DRY_RUN" == "true" ]]; then
  if [[ -n "$OUT" ]]; then
    mkdir -p "$(dirname "$OUT")"
    render_body > "$OUT"
    echo "PR comment body: ${OUT#$PROJECT_ROOT/}"
  else
    render_body
  fi
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI not found: gh"
  exit 1
fi

if [[ -z "${GH_TOKEN:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
  export GH_TOKEN="$GITHUB_TOKEN"
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "GH_TOKEN or GITHUB_TOKEN is required"
  exit 1
fi

if [[ -z "$PR_NUMBER" && -n "${GITHUB_EVENT_PATH:-}" && -f "${GITHUB_EVENT_PATH:-}" ]]; then
  PR_NUMBER="$(yq -r '.pull_request.number // ""' "$GITHUB_EVENT_PATH" 2>/dev/null || true)"
fi

[[ -n "$PR_NUMBER" ]] || { echo "Pull request number is required"; exit 1; }
[[ -n "$REPO" ]] || { echo "GitHub repository is required"; exit 1; }

BODY="$(render_body)"
COMMENT_ID="$(gh api "repos/$REPO/issues/$PR_NUMBER/comments" --paginate --jq ".[] | select(.body | contains(\"$MARKER\")) | .id" 2>/dev/null | head -n 1 || true)"

if [[ -n "$COMMENT_ID" ]]; then
  gh api --method PATCH "repos/$REPO/issues/comments/$COMMENT_ID" --raw-field body="$BODY" >/dev/null
  echo "Updated Lattice PR comment: $COMMENT_ID"
else
  gh api --method POST "repos/$REPO/issues/$PR_NUMBER/comments" --raw-field body="$BODY" >/dev/null
  echo "Created Lattice PR comment"
fi
