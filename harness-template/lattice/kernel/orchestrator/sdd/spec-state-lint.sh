#!/usr/bin/env bash
# spec-state-lint.sh — Validate spec front matter and artifact readiness.
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "spec state lint" "Validate spec.md state metadata and artifact readiness" \
    "spec-state-lint.sh <spec-id|path/to/spec.md>" \
    "spec-state-lint.sh modern-feature"
done

INPUT="${1:-}"

resolve_spec_file() {
  local input="$1" abs
  [[ -n "$input" ]] || { echo "Usage: spec-state-lint.sh <spec-id|path/to/spec.md>"; exit 1; }
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

placeholder_like() {
  local value="${1:-}"
  [[ -z "$value" ]] && return 0
  [[ "$value" == *"{"* || "$value" == *"}"* || "$value" == *"<"* || "$value" == *">"* ]] && return 0
  [[ "$value" =~ (TODO|TBD|FIXME) ]] && return 0
  return 1
}

FAILS=0
WARNS=0
pass_msg() { pass "$*"; }
fail_msg() { fail "$*"; FAILS=$((FAILS + 1)); }
warn_msg() { warn "$*"; WARNS=$((WARNS + 1)); }

SPEC_FILE="$(resolve_spec_file "$INPUT")"
SPEC_DIR="$(dirname "$SPEC_FILE")"
SPEC_REL="$(rel_path "$SPEC_FILE")"
PLAN_FILE="$SPEC_DIR/plan.md"
VERIFY_FILE="$SPEC_DIR/verify.md"

echo "🔍 Spec State Lint: $SPEC_REL"
echo ""

echo "── Front matter ──"
if has_frontmatter "$SPEC_FILE"; then
  pass_msg "front matter present"
else
  fail_msg "front matter missing"
fi

ID="$(frontmatter_value "id" "$SPEC_FILE")"
STATUS="$(frontmatter_value "status" "$SPEC_FILE")"
EXECUTION_MODE="$(frontmatter_value "execution_mode" "$SPEC_FILE")"
MODE_SOURCE="$(frontmatter_value "mode_source" "$SPEC_FILE")"
APPROVAL="$(frontmatter_value "approval" "$SPEC_FILE")"
OWNER="$(frontmatter_value "owner" "$SPEC_FILE")"
CREATED_AT="$(frontmatter_value "created_at" "$SPEC_FILE")"
UPDATED_AT="$(frontmatter_value "updated_at" "$SPEC_FILE")"

if [[ "$STATUS" == "clarifying" ]]; then
  REQUIRED_FRONTMATTER=(
    "id:$ID"
    "status:$STATUS"
    "owner:$OWNER"
    "created_at:$CREATED_AT"
    "updated_at:$UPDATED_AT"
  )
else
  REQUIRED_FRONTMATTER=(
    "id:$ID"
    "status:$STATUS"
    "execution_mode:$EXECUTION_MODE"
    "mode_source:$MODE_SOURCE"
    "approval:$APPROVAL"
    "owner:$OWNER"
    "created_at:$CREATED_AT"
    "updated_at:$UPDATED_AT"
  )
fi

for pair in "${REQUIRED_FRONTMATTER[@]}"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if placeholder_like "$value"; then
    fail_msg "front matter $key missing or placeholder"
  else
    pass_msg "$key: $value"
  fi
done
if [[ "$STATUS" == "clarifying" ]]; then
  for pair in \
    "execution_mode:$EXECUTION_MODE" \
    "mode_source:$MODE_SOURCE" \
    "approval:$APPROVAL"; do
    key="${pair%%:*}"
    value="${pair#*:}"
    if placeholder_like "$value"; then
      warn_msg "front matter $key unresolved for status=clarifying"
    else
      pass_msg "$key: $value"
    fi
  done
fi
echo ""

echo "── State contract ──"
case "$STATUS" in
  clarifying|drafted|planned|implemented|verified) pass_msg "status is valid: $STATUS" ;;
  *) fail_msg "status must be clarifying, drafted, planned, implemented, or verified" ;;
esac

if [[ "$STATUS" == "clarifying" ]]; then
  case "$EXECUTION_MODE" in
    ""|auto|TBD|tbd) warn_msg "execution_mode may remain unresolved while clarifying" ;;
    plan|tdd) pass_msg "execution_mode is concrete: $EXECUTION_MODE" ;;
    *) fail_msg "execution_mode must be empty, auto, TBD, plan, or tdd while clarifying" ;;
  esac
  case "$MODE_SOURCE" in
    ""|TBD|tbd) warn_msg "mode_source may remain unresolved while clarifying" ;;
    model-selected|project-default|user-override) pass_msg "mode_source is valid: $MODE_SOURCE" ;;
    *) fail_msg "mode_source must be unresolved or model-selected, project-default, or user-override" ;;
  esac
  case "$APPROVAL" in
    ""|TBD|tbd) warn_msg "approval may remain unresolved while clarifying" ;;
    explicit|inferred|skipped-with-reason) pass_msg "approval is valid: $APPROVAL" ;;
    *) fail_msg "approval must be unresolved or explicit, inferred, or skipped-with-reason" ;;
  esac
else
  case "$EXECUTION_MODE" in
    plan|tdd) pass_msg "execution_mode is concrete: $EXECUTION_MODE" ;;
    auto) fail_msg "execution_mode must be resolved to plan or tdd before implementation" ;;
    *) fail_msg "execution_mode must be plan or tdd" ;;
  esac

  case "$MODE_SOURCE" in
    model-selected|project-default|user-override) pass_msg "mode_source is valid: $MODE_SOURCE" ;;
    *) fail_msg "mode_source must be model-selected, project-default, or user-override" ;;
  esac

  case "$APPROVAL" in
    explicit|inferred|skipped-with-reason) pass_msg "approval is valid: $APPROVAL" ;;
    *) fail_msg "approval must be explicit, inferred, or skipped-with-reason" ;;
  esac
fi

if [[ "$CREATED_AT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  pass_msg "created_at format"
else
  fail_msg "created_at must use YYYY-MM-DDTHH:MM:SSZ"
fi
if [[ "$UPDATED_AT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  pass_msg "updated_at format"
else
  fail_msg "updated_at must use YYYY-MM-DDTHH:MM:SSZ"
fi
echo ""

echo "── Artifact readiness ──"
require_artifact() {
  local file="$1" label="$2"
  if [[ -f "$file" ]]; then
    pass_msg "$label present"
  else
    fail_msg "$label required for status=$STATUS"
  fi
}

case "$STATUS" in
  planned|implemented|verified)
    require_artifact "$PLAN_FILE" "plan.md"
    ;;
esac
case "$STATUS" in
  verified)
    require_artifact "$VERIFY_FILE" "verify.md"
    ;;
esac

if [[ "$STATUS" == "implemented" || "$STATUS" == "verified" ]]; then
  if [[ -f "$PLAN_FILE" ]]; then
    if grep -qE '^- \[ \] (T[0-9]+|RED-[0-9]+):' "$PLAN_FILE"; then
      fail_msg "plan.md has incomplete tasks for status=$STATUS"
    else
      pass_msg "plan tasks complete for status=$STATUS"
    fi
  fi
fi

if [[ "$STATUS" == "drafted" && -f "$PLAN_FILE" ]]; then
  warn_msg "plan.md exists but status is still drafted"
fi
if [[ "$STATUS" == "clarifying" && -f "$PLAN_FILE" ]]; then
  warn_msg "plan.md exists but status is still clarifying"
fi
if [[ "$STATUS" == "planned" && -f "$VERIFY_FILE" ]]; then
  warn_msg "verify.md exists but status is still planned"
fi

echo ""
echo "══════════════════════════════════"
printf "📊 Spec State Lint: %s fail(s), %s warning(s)\n" "$FAILS" "$WARNS"
if [[ "$FAILS" -eq 0 ]]; then
  echo "✅ PASS"
  exit 0
fi
echo "❌ FAIL"
exit 1
