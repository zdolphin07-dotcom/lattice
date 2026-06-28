#!/usr/bin/env bash
# tdd-evidence.sh - Write structured red/green evidence for a TDD task.
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "tdd evidence" "Write tdd-evidence.json for a task" \
    "tdd-evidence.sh <spec-id> <task-id> --ac=AC-1 --test=<name> --red-command=<cmd> --red-exit=<n> --green-command=<cmd> --green-exit=0" \
    "tdd-evidence.sh <spec-id> T1 --test-file=internal/foo_test.go --red-summary='expected failure' --green-summary='pass' --refactor=none"
done

SPEC_ID=""
TASK_ID=""
OUT=""
TEST_NAME=""
TEST_FILE=""
RED_COMMAND=""
RED_EXIT=""
RED_SUMMARY=""
GREEN_COMMAND=""
GREEN_EXIT=""
GREEN_SUMMARY=""
REFACTOR="none"
declare -a AC_IDS=()

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ac=*) AC_IDS+=("${1#--ac=}") ;;
    --test=*) TEST_NAME="${1#--test=}" ;;
    --test-file=*) TEST_FILE="${1#--test-file=}" ;;
    --red-command=*) RED_COMMAND="${1#--red-command=}" ;;
    --red-exit=*) RED_EXIT="${1#--red-exit=}" ;;
    --red-summary=*) RED_SUMMARY="${1#--red-summary=}" ;;
    --green-command=*) GREEN_COMMAND="${1#--green-command=}" ;;
    --green-exit=*) GREEN_EXIT="${1#--green-exit=}" ;;
    --green-summary=*) GREEN_SUMMARY="${1#--green-summary=}" ;;
    --refactor=*) REFACTOR="${1#--refactor=}" ;;
    --out=*) OUT="${1#--out=}" ;;
    --out)
      shift
      OUT="${1:-}"
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      if [[ -z "$SPEC_ID" ]]; then
        SPEC_ID="$1"
      elif [[ -z "$TASK_ID" ]]; then
        TASK_ID="$1"
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$SPEC_ID" || -z "$TASK_ID" ]]; then
  echo "Usage: tdd-evidence.sh <spec-id> <task-id> --ac=AC-1 --test=<name> --red-command=<cmd> --red-exit=<n> --green-command=<cmd> --green-exit=0"
  exit 1
fi

for required in TEST_NAME RED_COMMAND RED_EXIT GREEN_COMMAND GREEN_EXIT; do
  if [[ -z "${!required}" ]]; then
    echo "Missing required option: $required"
    exit 1
  fi
done

if [[ "${#AC_IDS[@]}" -eq 0 ]]; then
  echo "At least one --ac=AC-n is required"
  exit 1
fi

if ! [[ "$RED_EXIT" =~ ^[0-9]+$ && "$GREEN_EXIT" =~ ^[0-9]+$ ]]; then
  echo "red-exit and green-exit must be numeric"
  exit 1
fi

STATUS="pass"
if [[ "$RED_EXIT" -eq 0 || "$GREEN_EXIT" -ne 0 ]]; then
  STATUS="invalid"
fi

TASK_DIR="$PROJECT_ROOT/.lattice/sdd/$SPEC_ID/$TASK_ID"
OUT="${OUT:-$TASK_DIR/tdd-evidence.json}"
[[ "$OUT" == /* ]] || OUT="$PROJECT_ROOT/$OUT"
mkdir -p "$(dirname "$OUT")"
CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{
  printf '{\n'
  printf '  "schema_version": "lattice.tdd-evidence.v1",\n'
  printf '  "kind": "tdd-evidence",\n'
  printf '  "spec_id": "%s",\n' "$(json_escape "$SPEC_ID")"
  printf '  "task_id": "%s",\n' "$(json_escape "$TASK_ID")"
  printf '  "created_at": "%s",\n' "$(json_escape "$CREATED_AT")"
  printf '  "status": "%s",\n' "$STATUS"
  printf '  "ac_ids": [\n'
  local_idx=0
  if [[ "${#AC_IDS[@]}" -gt 0 ]]; then
    for ac_id in "${AC_IDS[@]}"; do
      printf '    "%s"' "$(json_escape "$ac_id")"
      local_idx=$((local_idx + 1))
      [[ "$local_idx" -lt "${#AC_IDS[@]}" ]] && printf ','
      printf '\n'
    done
  fi
  printf '  ],\n'
  printf '  "test": {\n'
  printf '    "file": "%s",\n' "$(json_escape "$TEST_FILE")"
  printf '    "name": "%s"\n' "$(json_escape "$TEST_NAME")"
  printf '  },\n'
  printf '  "red": {\n'
  printf '    "command": "%s",\n' "$(json_escape "$RED_COMMAND")"
  printf '    "exit_code": %s,\n' "$RED_EXIT"
  printf '    "summary": "%s"\n' "$(json_escape "$RED_SUMMARY")"
  printf '  },\n'
  printf '  "green": {\n'
  printf '    "command": "%s",\n' "$(json_escape "$GREEN_COMMAND")"
  printf '    "exit_code": %s,\n' "$GREEN_EXIT"
  printf '    "summary": "%s"\n' "$(json_escape "$GREEN_SUMMARY")"
  printf '  },\n'
  printf '  "refactor": "%s"\n' "$(json_escape "$REFACTOR")"
  printf '}\n'
} > "$OUT"

echo "TDD evidence: ${OUT#$PROJECT_ROOT/}"

if [[ "$STATUS" != "pass" ]]; then
  echo "Invalid TDD evidence: red must fail and green must pass"
  exit 1
fi
