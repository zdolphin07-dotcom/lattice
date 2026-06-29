#!/usr/bin/env bash
# review-package.sh - Build a read-only diff package for task/branch review.
# Usage: review-package.sh <spec-id> [task-id] [output-file]
source "$(dirname "$0")/../../_lib.sh"

SPEC_ID="${1:-}"
TASK_ID="${2:-branch}"
OUT="${3:-}"

if [[ -z "$SPEC_ID" ]]; then
  echo "Usage: review-package.sh <spec-id> [task-id] [output-file]"
  exit 1
fi

SPEC_DIR="$PROJECT_ROOT/lattice/specs/$SPEC_ID"
SPEC_FILE="$SPEC_DIR/spec.md"
PLAN_FILE="$SPEC_DIR/plan.md"

[[ -f "$SPEC_FILE" ]] || { echo "Spec not found: $SPEC_FILE"; exit 1; }
[[ -f "$PLAN_FILE" ]] || { echo "Plan not found: $PLAN_FILE"; exit 1; }

TASK_DIR="$PROJECT_ROOT/.lattice/sdd/$SPEC_ID/$TASK_ID"
mkdir -p "$TASK_DIR"
OUT="${OUT:-$TASK_DIR/review-package.md}"

git_cmd() {
  git -C "$PROJECT_ROOT" "$@" 2>/dev/null || true
}

{
  echo "# Review Package: $SPEC_ID / $TASK_ID"
  echo ""
  echo "## Read-only Review Contract"
  echo ""
  echo "Reviewer must not modify the working tree. Return both verdicts:"
  echo ""
  echo "- Spec compliance: pass | fail | cannot_verify"
  echo "- Code quality: pass | fail | cannot_verify"
  echo ""
  echo "Use \`cannot_verify\` when the diff does not contain enough evidence."
  echo "Ground every fail in file/line evidence or a missing test/gate."
  echo ""
  echo "## Sources"
  echo ""
  echo "- Spec: \`lattice/specs/$SPEC_ID/spec.md\`"
  echo "- Plan: \`lattice/specs/$SPEC_ID/plan.md\`"
  echo "- Task: \`$TASK_ID\`"
  echo ""
  echo "## Git Status"
  echo ""
  echo '```text'
  git_cmd status --short
  echo '```'
  echo ""
  echo "## Diff Stat"
  echo ""
  echo '```text'
  git_cmd diff --stat
  echo '```'
  echo ""
  echo "## Diff"
  echo ""
  echo '```diff'
  git_cmd diff -- .
  echo '```'
  echo ""
  echo "## Expected Review Output"
  echo ""
  echo '```markdown'
  echo "## Verdict"
  echo ""
  echo "- Spec compliance: pass | fail | cannot_verify"
  echo "- Code quality: pass | fail | cannot_verify"
  echo ""
  echo "## Findings"
  echo ""
  echo "- [severity] file:line - issue"
  echo ""
  echo "## Evidence Checked"
  echo ""
  echo "- ..."
  echo '```'
} > "$OUT"

echo "$OUT"
