#!/usr/bin/env bash
# spec-status.sh — Advance spec lifecycle status with transition guards.
source "$(dirname "$0")/../../_lib.sh"

usage_line="spec-status.sh <spec-id|path/to/spec.md> <drafted|planned|implemented|verified|finished> [--from=<status>] [--force]"
for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "spec status" "Advance spec.md status and updated_at safely" \
    "$usage_line" \
    "spec-status.sh checkout-flow planned"
done

INPUT="${1:-}"
TARGET_STATUS="${2:-}"
EXPECTED_FROM=""
FORCE=false

shift $(( $# >= 2 ? 2 : $# ))
for arg in "$@"; do
  case "$arg" in
    --from=*) EXPECTED_FROM="${arg#--from=}" ;;
    --force) FORCE=true ;;
    *) echo "Unknown argument: $arg"; echo "Usage: $usage_line"; exit 1 ;;
  esac
done

resolve_spec_file() {
  local input="$1" abs
  [[ -n "$input" ]] || { echo "Usage: $usage_line"; exit 1; }
  if [[ "$input" == *.md || "$input" == */* ]]; then
    [[ "$input" == /* ]] && abs="$input" || abs="$PROJECT_ROOT/$input"
  else
    abs="$PROJECT_ROOT/lattice/specs/$input/spec.md"
  fi
  [[ -f "$abs" ]] || { echo "Spec file not found: $input"; exit 1; }
  printf '%s' "$abs"
}

rel_path() {
  local path="$1"
  if [[ "$path" == "$PROJECT_ROOT/"* ]]; then
    printf '%s' "${path#$PROJECT_ROOT/}"
  else
    printf '%s' "$path"
  fi
}

frontmatter_value() {
  local key="$1" file="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      gsub(/^["'\''`]+|["'\''`]+$/, "", value)
      print value
      exit
    }
  ' "$file"
}

has_frontmatter() {
  local file="$1"
  [[ "$(head -1 "$file" 2>/dev/null)" == "---" ]]
}

valid_status() {
  case "$1" in
    drafted|planned|implemented|verified|finished) return 0 ;;
    *) return 1 ;;
  esac
}

transition_allowed() {
  local from="$1" to="$2"
  [[ "$from" == "$to" ]] && return 0
  case "$from:$to" in
    drafted:planned|planned:implemented|implemented:verified|verified:finished) return 0 ;;
    *) return 1 ;;
  esac
}

require_file() {
  local file="$1" label="$2"
  [[ -f "$file" ]] || { echo "Missing required artifact for status=$TARGET_STATUS: $label"; exit 1; }
}

plan_has_incomplete_tasks() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  grep -qE '^- \[ \] (T[0-9]+|RED-[0-9]+):' "$file"
}

update_frontmatter() {
  local file="$1" status="$2" updated_at="$3" tmp
  tmp="$(mktemp)"
  awk -v status="$status" -v updated_at="$updated_at" '
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && $0 == "---" {
      if (!saw_status) print "status: " status
      if (!saw_updated_at) print "updated_at: " updated_at
      in_fm = 0
      print
      next
    }
    in_fm && $0 ~ /^status:[ \t]*/ {
      print "status: " status
      saw_status = 1
      next
    }
    in_fm && $0 ~ /^updated_at:[ \t]*/ {
      print "updated_at: " updated_at
      saw_updated_at = 1
      next
    }
    { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

[[ -n "$TARGET_STATUS" ]] || { echo "Usage: $usage_line"; exit 1; }
valid_status "$TARGET_STATUS" || { echo "Invalid target status: $TARGET_STATUS"; exit 1; }

SPEC_FILE="$(resolve_spec_file "$INPUT")"
SPEC_DIR="$(dirname "$SPEC_FILE")"
SPEC_REL="$(rel_path "$SPEC_FILE")"
CURRENT_STATUS="$(frontmatter_value "status" "$SPEC_FILE")"

echo "🔁 Spec Status: $SPEC_REL"
echo ""

has_frontmatter "$SPEC_FILE" || { echo "Spec front matter missing"; exit 1; }
valid_status "$CURRENT_STATUS" || { echo "Invalid current status: ${CURRENT_STATUS:-<empty>}"; exit 1; }

if [[ -n "$EXPECTED_FROM" && "$EXPECTED_FROM" != "$CURRENT_STATUS" ]]; then
  echo "Current status mismatch: expected $EXPECTED_FROM, got $CURRENT_STATUS"
  exit 1
fi

if [[ "$FORCE" != "true" ]] && ! transition_allowed "$CURRENT_STATUS" "$TARGET_STATUS"; then
  echo "Illegal transition: $CURRENT_STATUS -> $TARGET_STATUS"
  echo "Allowed path: drafted -> planned -> implemented -> verified -> finished"
  echo "Use --force only when intentionally repairing spec metadata."
  exit 1
fi

case "$TARGET_STATUS" in
  planned|implemented|verified|finished)
    require_file "$SPEC_DIR/context.md" "context.md"
    require_file "$SPEC_DIR/plan.md" "plan.md"
    ;;
esac
case "$TARGET_STATUS" in
  verified|finished)
    require_file "$SPEC_DIR/verify.md" "verify.md"
    ;;
esac
case "$TARGET_STATUS" in
  finished)
    require_file "$SPEC_DIR/summary.md" "summary.md"
    ;;
esac
case "$TARGET_STATUS" in
  implemented|verified|finished)
    if plan_has_incomplete_tasks "$SPEC_DIR/plan.md"; then
      echo "plan.md has incomplete tasks; complete or split them before status=$TARGET_STATUS"
      exit 1
    fi
    ;;
esac

if [[ "$TARGET_STATUS" == "planned" || "$TARGET_STATUS" == "implemented" || "$TARGET_STATUS" == "verified" || "$TARGET_STATUS" == "finished" ]]; then
  if [[ -x "$KERNEL_DIR/orchestrator/sdd/plan-lint.sh" ]]; then
    bash "$KERNEL_DIR/orchestrator/sdd/plan-lint.sh" "$SPEC_DIR/plan.md" >/dev/null
  fi
fi

if [[ "$TARGET_STATUS" == "implemented" || "$TARGET_STATUS" == "verified" || "$TARGET_STATUS" == "finished" ]]; then
  if [[ -x "$KERNEL_DIR/orchestrator/sdd/task-evidence-lint.sh" ]]; then
    bash "$KERNEL_DIR/orchestrator/sdd/task-evidence-lint.sh" "$SPEC_DIR/plan.md"
  fi
fi

UPDATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
update_frontmatter "$SPEC_FILE" "$TARGET_STATUS" "$UPDATED_AT"

echo "Updated status: $CURRENT_STATUS -> $TARGET_STATUS"
echo "Updated at: $UPDATED_AT"
echo ""

if [[ -x "$KERNEL_DIR/orchestrator/sdd/spec-state-lint.sh" ]]; then
  bash "$KERNEL_DIR/orchestrator/sdd/spec-state-lint.sh" "$SPEC_FILE"
fi
