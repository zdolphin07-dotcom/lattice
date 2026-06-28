#!/usr/bin/env bash
# plan-lint.sh — Validate a per-spec plan.md implementation contract.
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "plan lint" "Validate an AC-traced plan.md" \
    "plan-lint.sh <spec-id|path/to/plan.md>" \
    "plan-lint.sh modern-feature"
done

INPUT="${1:-}"

resolve_plan_file() {
  local input="$1" abs
  [[ -n "$input" ]] || { echo "Usage: plan-lint.sh <spec-id|path/to/plan.md>"; exit 1; }
  if [[ "$input" == *.md || "$input" == */* ]]; then
    [[ "$input" == /* ]] && abs="$input" || abs="$PROJECT_ROOT/$input"
  else
    abs="$PROJECT_ROOT/lattice/specs/$input/plan.md"
  fi
  [[ -f "$abs" ]] || { echo "Plan file not found: $input"; exit 1; }
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

spec_file_for_plan() {
  local plan="$1" dir
  dir="$(dirname "$plan")"
  [[ -f "$dir/spec.md" ]] && printf '%s' "$dir/spec.md"
}

extract_section() {
  local heading="$1" file="$2"
  awk -v heading="$heading" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^##[[:space:]]+/ {
      title = $0
      sub(/^##+[[:space:]]+/, "", title)
      title = trim(title)
      if (tolower(title) == tolower(heading)) { in_section = 1; next }
      if (in_section) exit
    }
    in_section { print }
  ' "$file"
}

section_exists() {
  local heading="$1" file="$2"
  awk -v heading="$heading" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^##[[:space:]]+/ {
      title = $0
      sub(/^##+[[:space:]]+/, "", title)
      title = trim(title)
      if (tolower(title) == tolower(heading)) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}

task_lines() {
  local file="$1"
  grep -E '^- \[[ xX]\] (T[0-9]+|RED-[0-9]+):' "$file" 2>/dev/null || true
}

task_body() {
  local task_id="$1" file="$2"
  awk -v task_id="$task_id" '
    $0 ~ "^- \\[[ xX]\\] " task_id ":" { in_task = 1; print; next }
    in_task && /^- \[[ xX]\] (T[0-9]+|RED-[0-9]+):/ { exit }
    in_task && /^##[[:space:]]+/ { exit }
    in_task { print }
  ' "$file"
}

extract_task_id() {
  local line="$1"
  sed -E 's/^- \[[ xX]\] ((T[0-9]+|RED-[0-9]+)):.*/\1/' <<< "$line"
}

execution_mode() {
  local spec="$1" plan="$2" value
  value="$(grep -Eim1 '^execution_mode:[[:space:]]*(plan|tdd)' "$spec" 2>/dev/null | sed -E 's/.*execution_mode:[[:space:]]*//; s/[`"]//g' || true)"
  [[ -n "$value" ]] || value="$(grep -Eim1 'Execution mode:[[:space:]]*(plan|tdd)' "$plan" 2>/dev/null | sed -E 's/.*Execution mode:[[:space:]]*//; s/[`"]//g' || true)"
  printf '%s' "${value:-unknown}"
}

PLAN_FILE="$(resolve_plan_file "$INPUT")"
SPEC_FILE="$(spec_file_for_plan "$PLAN_FILE")"
PLAN_REL="$(rel_path "$PLAN_FILE")"
MODE="unknown"
[[ -n "$SPEC_FILE" ]] && MODE="$(execution_mode "$SPEC_FILE" "$PLAN_FILE")"

FAILS=0
WARNS=0
pass_msg() { pass "$*"; }
fail_msg() { fail "$*"; FAILS=$((FAILS + 1)); }
warn_msg() { warn "$*"; WARNS=$((WARNS + 1)); }

echo "🔍 Plan Lint: $PLAN_REL"
echo ""

echo "── Artifact layout ──"
if [[ "$(basename "$PLAN_FILE")" == "plan.md" ]]; then
  pass_msg "Directory plan layout"
else
  fail_msg "Plan must be named plan.md"
fi
if [[ -n "$SPEC_FILE" && -f "$SPEC_FILE" ]]; then
  pass_msg "Adjacent spec.md found"
else
  fail_msg "Adjacent spec.md missing"
fi
echo ""

echo "── Section completeness ──"
for section in "Source" "Global Constraints" "Tasks"; do
  if section_exists "$section" "$PLAN_FILE"; then
    pass_msg "$section"
  else
    fail_msg "Missing section: $section"
  fi
done
if grep -qiE 'Verification|Evidence' "$PLAN_FILE"; then
  pass_msg "Verification or evidence present"
else
  fail_msg "Plan lacks verification/evidence language"
fi
echo ""

echo "── Task contract ──"
TASK_COUNT=0
BAD_TASKS=0
AC_REFERENCES="$({ grep -oE 'AC-[0-9]+' "$PLAN_FILE" || true; } | sort -u | tr '\n' ' ')"
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  task_id="$(extract_task_id "$line")"
  body="$(task_body "$task_id" "$PLAN_FILE")"
  TASK_COUNT=$((TASK_COUNT + 1))
  if [[ "$task_id" == RED-* ]]; then
    if ! grep -qiE 'Expected failure:' <<< "$body"; then
      fail_msg "$task_id missing Expected failure"
      BAD_TASKS=$((BAD_TASKS + 1))
    fi
    if ! grep -qiE 'Test file:' <<< "$body"; then
      fail_msg "$task_id missing Test file"
      BAD_TASKS=$((BAD_TASKS + 1))
    fi
  elif [[ "$task_id" == T* ]]; then
    if ! grep -qE 'AC-[0-9]+' <<< "$body"; then
      fail_msg "$task_id missing AC reference"
      BAD_TASKS=$((BAD_TASKS + 1))
    fi
    if ! grep -qiE 'Verification:' <<< "$body"; then
      fail_msg "$task_id missing Verification"
      BAD_TASKS=$((BAD_TASKS + 1))
    fi
    if ! grep -qiE 'Files:|Touched files/contracts:' <<< "$body"; then
      fail_msg "$task_id missing files/contracts boundary"
      BAD_TASKS=$((BAD_TASKS + 1))
    fi
  fi
  if ! grep -qiE 'Done when:|Evidence:' <<< "$body"; then
    warn_msg "$task_id has no Done when or Evidence"
  fi
done < <(task_lines "$PLAN_FILE")

if [[ "$TASK_COUNT" -gt 0 ]]; then
  pass_msg "$TASK_COUNT task(s) found"
else
  fail_msg "No stable task ids found"
fi
if [[ -n "$AC_REFERENCES" ]]; then
  pass_msg "AC trace present: $AC_REFERENCES"
else
  fail_msg "No AC references in plan"
fi
echo ""

echo "── Mode-specific checks ──"
if [[ "$MODE" == "tdd" ]]; then
  RED_COUNT="$({ grep -E '^- \[[ xX]\] RED-[0-9]+:' "$PLAN_FILE" || true; } | wc -l | tr -d ' ')"
  if [[ "$RED_COUNT" -gt 0 ]]; then
    pass_msg "TDD red-test task(s): $RED_COUNT"
  else
    fail_msg "TDD plan requires RED-{n} test-first tasks"
  fi
else
  pass_msg "Mode: $MODE"
fi

if grep -Eiq '\b(TODO|TBD|FIXME)\b' "$PLAN_FILE"; then
  fail_msg "Unresolved TODO/TBD/FIXME marker found"
fi

echo ""
echo "══════════════════════════════════"
printf "📊 Plan Lint: %s fail(s), %s warning(s)\n" "$FAILS" "$WARNS"
if [[ "$FAILS" -eq 0 ]]; then
  echo "✅ PASS"
  exit 0
fi
echo "❌ FAIL"
exit 1
