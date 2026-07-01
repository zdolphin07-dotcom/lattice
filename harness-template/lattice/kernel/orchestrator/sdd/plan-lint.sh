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
      sub(/^[0-9]+[.、][[:space:]]*/, "", title)
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
      sub(/^[0-9]+[.、][[:space:]]*/, "", title)
      title = trim(title)
      if (tolower(title) == tolower(heading)) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}

section_exists_any() {
  local headings="$1" file="$2" heading
  IFS='|' read -r -a heading_list <<< "$headings"
  for heading in "${heading_list[@]}"; do
    if section_exists "$heading" "$file"; then
      return 0
    fi
  done
  return 1
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

require_task_pattern() {
  local task_id="$1" body="$2" pattern="$3" message="$4"
  if grep -qiE "$pattern" <<< "$body"; then
    return 0
  fi
  fail_msg "$task_id $message"
  return 0
}

execution_mode() {
  local spec="$1" plan="$2" value
  value="$(grep -Eim1 '^execution_mode:[[:space:]]*(plan|tdd)' "$spec" 2>/dev/null | sed -E 's/.*execution_mode:[[:space:]]*//; s/[`"]//g' || true)"
  [[ -n "$value" ]] || value="$(grep -Eim1 'Execution mode:[[:space:]]*(plan|tdd)' "$plan" 2>/dev/null | sed -E 's/.*Execution mode:[[:space:]]*//; s/[`"]//g' || true)"
  [[ -n "$value" ]] || value="$(grep -Eim1 '执行模式[[:space:]]*[:：][[:space:]]*(plan|tdd|`plan`|`tdd`)' "$plan" 2>/dev/null | sed -E 's/.*执行模式[[:space:]]*[:：][[:space:]]*//; s/[`"]//g' || true)"
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
for section in "Source|来源" "Global Constraints|全局约束" "Tasks|任务拆解"; do
  if section_exists_any "$section" "$PLAN_FILE"; then
    pass_msg "$section"
  else
    fail_msg "Missing section: $section"
  fi
done
if grep -qiE 'Verification|Evidence|验证方式|证据' "$PLAN_FILE"; then
  pass_msg "Verification or evidence present"
else
  fail_msg "Plan lacks verification/evidence language"
fi
echo ""

echo "── Task contract ──"
TASK_COUNT=0
AC_REFERENCES="$({ grep -oE 'AC-[0-9]+' "$PLAN_FILE" || true; } | sort -u | tr '\n' ' ')"
SPEC_AC_REFERENCES=""
if [[ -n "$SPEC_FILE" && -f "$SPEC_FILE" ]]; then
  SPEC_AC_REFERENCES="$({ grep -oE 'AC-[0-9]+' "$SPEC_FILE" || true; } | sort -u)"
fi
SEEN_TASK_IDS=""
EXPECTED_T=1
EXPECTED_RED=1
FIRST_T_LINE=0
FIRST_RED_LINE=0
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  task_id="$(extract_task_id "$line")"
  body="$(task_body "$task_id" "$PLAN_FILE")"
  TASK_COUNT=$((TASK_COUNT + 1))
  line_number="$(grep -nF -- "$line" "$PLAN_FILE" | head -1 | cut -d: -f1)"
  if grep -qxF "$task_id" <<< "$SEEN_TASK_IDS"; then
    fail_msg "$task_id duplicate task id"
  fi
  SEEN_TASK_IDS="${SEEN_TASK_IDS}${task_id}"$'\n'

  if [[ "$task_id" == RED-* ]]; then
    red_number="${task_id#RED-}"
    if [[ "$red_number" -ne "$EXPECTED_RED" ]]; then
      fail_msg "$task_id should be RED-$EXPECTED_RED"
    fi
    EXPECTED_RED=$((EXPECTED_RED + 1))
    [[ "$FIRST_RED_LINE" -eq 0 ]] && FIRST_RED_LINE="$line_number"
    require_task_pattern "$task_id" "$body" 'AC-[0-9]+' "missing AC reference"
    require_task_pattern "$task_id" "$body" '(Expected failure|预期失败)[[:space:]]*[:：]' "missing Expected failure"
    require_task_pattern "$task_id" "$body" '(Test file|测试文件)[[:space:]]*[:：]' "missing Test file"
    require_task_pattern "$task_id" "$body" '(Verification|验证方式)[[:space:]]*[:：]' "missing Verification"
    require_task_pattern "$task_id" "$body" '(Done when|完成条件)[[:space:]]*[:：]' "missing Done when"
  elif [[ "$task_id" == T* ]]; then
    t_number="${task_id#T}"
    if [[ "$t_number" -ne "$EXPECTED_T" ]]; then
      fail_msg "$task_id should be T$EXPECTED_T"
    fi
    EXPECTED_T=$((EXPECTED_T + 1))
    [[ "$FIRST_T_LINE" -eq 0 ]] && FIRST_T_LINE="$line_number"
    require_task_pattern "$task_id" "$body" 'AC-[0-9]+' "missing AC reference"
    require_task_pattern "$task_id" "$body" '(Mode|模式)[[:space:]]*[:：][[:space:]]*(plan|tdd|`plan`|`tdd`)' "missing Mode"
    require_task_pattern "$task_id" "$body" '(Scope|范围)[[:space:]]*[:：]' "missing Scope"
    require_task_pattern "$task_id" "$body" '(Verification|验证方式)[[:space:]]*[:：]' "missing Verification"
    require_task_pattern "$task_id" "$body" '(Files|Touched files/contracts|涉及文件)[[:space:]]*[:：]' "missing files/contracts boundary"
    require_task_pattern "$task_id" "$body" '(Evidence|证据)[[:space:]]*[:：]' "missing Evidence"
    require_task_pattern "$task_id" "$body" '(Brief|任务简报)[[:space:]]*[:：]' "missing Evidence Brief"
    require_task_pattern "$task_id" "$body" '(Review package|评审包)[[:space:]]*[:：]' "missing Evidence Review package"
    require_task_pattern "$task_id" "$body" '(Done when|完成条件)[[:space:]]*[:：]' "missing Done when"
  fi
  if grep -Eiq '\b(TODO|TBD|FIXME)\b|<[^>]+>|\{[A-Za-z_][A-Za-z0-9_-]*\}' <<< "$body"; then
    fail_msg "$task_id contains unresolved placeholder text"
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
while IFS= read -r ac_id; do
  [[ -n "$ac_id" ]] || continue
  if grep -qw "$ac_id" <<< "$AC_REFERENCES"; then
    pass_msg "$ac_id planned"
  else
    fail_msg "$ac_id from spec.md is not referenced in plan.md"
  fi
done <<< "$SPEC_AC_REFERENCES"
echo ""

echo "── Mode-specific checks ──"
if [[ "$MODE" == "tdd" ]]; then
  RED_COUNT="$({ grep -E '^- \[[ xX]\] RED-[0-9]+:' "$PLAN_FILE" || true; } | wc -l | tr -d ' ')"
  if [[ "$RED_COUNT" -gt 0 ]]; then
    pass_msg "TDD red-test task(s): $RED_COUNT"
  else
    fail_msg "TDD plan requires RED-{n} test-first tasks"
  fi
  if [[ "$FIRST_T_LINE" -gt 0 && "$FIRST_RED_LINE" -gt 0 && "$FIRST_T_LINE" -lt "$FIRST_RED_LINE" ]]; then
    fail_msg "TDD plan must list RED-{n} tasks before implementation T{n} tasks"
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
