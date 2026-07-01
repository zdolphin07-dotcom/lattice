#!/usr/bin/env bash
# task-next.sh — Print the next incomplete PrismSpec/Lattice plan task.
source "$(dirname "$0")/../../_lib.sh"

usage_line="task-next.sh <spec-id|path/to/plan.md> [--json]"
for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "task next" "Print the next incomplete plan task" \
    "$usage_line" \
    "task-next.sh modern-feature --json"
done

INPUT="${1:-}"
FORMAT="text"

shift $(( $# >= 1 ? 1 : $# ))
for arg in "$@"; do
  case "$arg" in
    --json) FORMAT="json" ;;
    *) echo "Unknown argument: $arg"; echo "Usage: $usage_line"; exit 1 ;;
  esac
done

resolve_plan_file() {
  local input="$1" abs
  [[ -n "$input" ]] || { echo "Usage: $usage_line"; exit 1; }
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

extract_task_title() {
  local line="$1"
  sed -E 's/^- \[[ xX]\] (T[0-9]+|RED-[0-9]+):[[:space:]]*//' <<< "$line"
}

field_value() {
  local labels="$1" body="$2"
  grep -Eim1 "^[[:space:]]+-[[:space:]]+(${labels})[[:space:]]*[:：]" <<< "$body" \
    | sed -E "s/^[[:space:]]+-[[:space:]]+(${labels})[[:space:]]*[:：][[:space:]]*//; s/^[\`\"]+|[\`\"]+$//g" \
    || true
}

execution_mode() {
  local spec="$1" plan="$2" value
  if [[ -n "$spec" && -f "$spec" ]]; then
    value="$(grep -Eim1 '^execution_mode:[[:space:]]*(plan|tdd)' "$spec" 2>/dev/null | sed -E 's/.*execution_mode:[[:space:]]*//; s/[`"]//g' || true)"
  fi
  [[ -n "$value" ]] || value="$(grep -Eim1 'Execution mode:[[:space:]]*(plan|tdd)' "$plan" 2>/dev/null | sed -E 's/.*Execution mode:[[:space:]]*//; s/[`"]//g' || true)"
  [[ -n "$value" ]] || value="$(grep -Eim1 '执行模式[[:space:]]*[:：][[:space:]]*(plan|tdd|`plan`|`tdd`)' "$plan" 2>/dev/null | sed -E 's/.*执行模式[[:space:]]*[:：][[:space:]]*//; s/[`"]//g' || true)"
  printf '%s' "${value:-unknown}"
}

json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

json_ac_refs() {
  local refs="$1" first=true ac
  printf '['
  while IFS= read -r ac; do
    [[ -n "$ac" ]] || continue
    if [[ "$first" == "true" ]]; then
      first=false
    else
      printf ', '
    fi
    printf '"%s"' "$(json_escape "$ac")"
  done < <(grep -oE 'AC-[0-9]+' <<< "$refs" | sort -u || true)
  printf ']'
}

PLAN_FILE="$(resolve_plan_file "$INPUT")"
SPEC_FILE="$(spec_file_for_plan "$PLAN_FILE")"
PLAN_REL="$(rel_path "$PLAN_FILE")"
SPEC_ID="$(basename "$(dirname "$PLAN_FILE")")"
NEXT_LINE="$(grep -E '^- \[ \] (T[0-9]+|RED-[0-9]+):' "$PLAN_FILE" 2>/dev/null | head -1 || true)"

if [[ -z "$NEXT_LINE" ]]; then
  if [[ "$FORMAT" == "json" ]]; then
    printf '{\n'
    printf '  "schema_version": "lattice.task-next.v1",\n'
    printf '  "kind": "task-next",\n'
    printf '  "status": "complete",\n'
    printf '  "spec_id": "%s",\n' "$(json_escape "$SPEC_ID")"
    printf '  "plan_file": "%s",\n' "$(json_escape "$PLAN_REL")"
    printf '  "next_task": null\n'
    printf '}\n'
  else
    echo "No incomplete tasks found: $PLAN_REL"
  fi
  exit 0
fi

TASK_ID="$(extract_task_id "$NEXT_LINE")"
TITLE="$(extract_task_title "$NEXT_LINE")"
BODY="$(task_body "$TASK_ID" "$PLAN_FILE")"
LINE_NUMBER="$(grep -nF -- "$NEXT_LINE" "$PLAN_FILE" | head -1 | cut -d: -f1)"
TASK_KIND="implementation"
[[ "$TASK_ID" == RED-* ]] && TASK_KIND="red-test"
MODE="$(field_value "Mode|模式" "$BODY")"
[[ -n "$MODE" ]] || MODE="$(execution_mode "$SPEC_FILE" "$PLAN_FILE")"
SCOPE="$(field_value "Scope|范围" "$BODY")"
VERIFICATION="$(field_value "Verification|验证方式" "$BODY")"
AC_REFS="$(grep -oE 'AC-[0-9]+' <<< "$BODY" | sort -u | tr '\n' ' ' || true)"
EVIDENCE_ROOT=".lattice/sdd/$SPEC_ID/$TASK_ID"

if [[ "$FORMAT" == "json" ]]; then
  printf '{\n'
  printf '  "schema_version": "lattice.task-next.v1",\n'
  printf '  "kind": "task-next",\n'
  printf '  "status": "next",\n'
  printf '  "spec_id": "%s",\n' "$(json_escape "$SPEC_ID")"
  printf '  "plan_file": "%s",\n' "$(json_escape "$PLAN_REL")"
  printf '  "task_id": "%s",\n' "$(json_escape "$TASK_ID")"
  printf '  "task_kind": "%s",\n' "$TASK_KIND"
  printf '  "title": "%s",\n' "$(json_escape "$TITLE")"
  printf '  "line": %s,\n' "${LINE_NUMBER:-0}"
  printf '  "mode": "%s",\n' "$(json_escape "$MODE")"
  printf '  "scope": "%s",\n' "$(json_escape "$SCOPE")"
  printf '  "ac_refs": %s,\n' "$(json_ac_refs "$AC_REFS")"
  printf '  "verification": "%s",\n' "$(json_escape "$VERIFICATION")"
  printf '  "evidence_root": "%s"\n' "$(json_escape "$EVIDENCE_ROOT")"
  printf '}\n'
  exit 0
fi

echo "Next task: $TASK_ID"
echo "Kind: $TASK_KIND"
echo "Title: $TITLE"
echo "Mode: $MODE"
echo "AC refs: ${AC_REFS:-none}"
echo "Plan: $PLAN_REL:$LINE_NUMBER"
echo "Evidence root: $EVIDENCE_ROOT"
echo ""
echo "$BODY"
