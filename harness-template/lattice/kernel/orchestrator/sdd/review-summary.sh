#!/usr/bin/env bash
# review-summary.sh - Write structured review verdict evidence.
# Usage: review-summary.sh <spec-id> [task-id] --spec-compliance=pass --code-quality=pass --test-coverage=pass --risk=pass
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "review summary" "Write review-summary.json evidence" \
    "review-summary.sh <spec-id> [task-id] --spec-compliance=pass|fail|cannot_verify --code-quality=pass|fail|cannot_verify --test-coverage=pass|fail|cannot_verify --risk=pass|fail|cannot_verify" \
    "review-summary.sh <spec-id> T1 ... --finding='medium|file:line|issue' --evidence='go test ./...' --out=<file>"
done

SPEC_ID=""
TASK_ID="branch"
OUT=""
SPEC_COMPLIANCE=""
CODE_QUALITY=""
TEST_COVERAGE=""
RISK=""
declare -a FINDINGS=()
declare -a EVIDENCE=()

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

normalize_verdict() {
  local value="${1:-}"
  value="${value//-/_}"
  case "$value" in
    pass|fail|cannot_verify) printf '%s' "$value" ;;
    *)
      echo "Invalid verdict: ${1:-empty}. Use pass, fail, or cannot_verify."
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec-compliance=*) SPEC_COMPLIANCE="${1#--spec-compliance=}" ;;
    --code-quality=*) CODE_QUALITY="${1#--code-quality=}" ;;
    --test-coverage=*) TEST_COVERAGE="${1#--test-coverage=}" ;;
    --risk=*) RISK="${1#--risk=}" ;;
    --finding=*) FINDINGS+=("${1#--finding=}") ;;
    --evidence=*) EVIDENCE+=("${1#--evidence=}") ;;
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
      elif [[ "$TASK_ID" == "branch" ]]; then
        TASK_ID="$1"
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$SPEC_ID" ]]; then
  echo "Usage: review-summary.sh <spec-id> [task-id] --spec-compliance=... --code-quality=... --test-coverage=... --risk=..."
  exit 1
fi

SPEC_COMPLIANCE="$(normalize_verdict "$SPEC_COMPLIANCE")"
CODE_QUALITY="$(normalize_verdict "$CODE_QUALITY")"
TEST_COVERAGE="$(normalize_verdict "$TEST_COVERAGE")"
RISK="$(normalize_verdict "$RISK")"

VERDICT="pass"
for axis in "$SPEC_COMPLIANCE" "$CODE_QUALITY" "$TEST_COVERAGE" "$RISK"; do
  if [[ "$axis" == "fail" ]]; then
    VERDICT="fail"
    break
  fi
  if [[ "$axis" == "cannot_verify" && "$VERDICT" == "pass" ]]; then
    VERDICT="cannot_verify"
  fi
done

TASK_DIR="$PROJECT_ROOT/.lattice/sdd/$SPEC_ID/$TASK_ID"
OUT="${OUT:-$TASK_DIR/review-summary.json}"
[[ "$OUT" == /* ]] || OUT="$PROJECT_ROOT/$OUT"
mkdir -p "$(dirname "$OUT")"

CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REVIEW_PACKAGE=".lattice/sdd/$SPEC_ID/$TASK_ID/review-package.md"

{
  printf '{\n'
  printf '  "schema_version": "lattice.review-summary.v1",\n'
  printf '  "kind": "review-summary",\n'
  printf '  "spec_id": "%s",\n' "$(json_escape "$SPEC_ID")"
  printf '  "task_id": "%s",\n' "$(json_escape "$TASK_ID")"
  printf '  "created_at": "%s",\n' "$(json_escape "$CREATED_AT")"
  printf '  "verdict": "%s",\n' "$VERDICT"
  printf '  "axes": {\n'
  printf '    "spec_compliance": "%s",\n' "$SPEC_COMPLIANCE"
  printf '    "code_quality": "%s",\n' "$CODE_QUALITY"
  printf '    "test_coverage": "%s",\n' "$TEST_COVERAGE"
  printf '    "risk": "%s"\n' "$RISK"
  printf '  },\n'
  printf '  "findings": [\n'
  local_idx=0
  if [[ "${#FINDINGS[@]}" -gt 0 ]]; then
    for finding in "${FINDINGS[@]}"; do
      IFS='|' read -r severity reference issue <<< "$finding"
      printf '    {"severity":"%s","reference":"%s","issue":"%s"}' \
        "$(json_escape "${severity:-}")" \
        "$(json_escape "${reference:-}")" \
        "$(json_escape "${issue:-}")"
      local_idx=$((local_idx + 1))
      [[ "$local_idx" -lt "${#FINDINGS[@]}" ]] && printf ','
      printf '\n'
    done
  fi
  printf '  ],\n'
  printf '  "evidence_checked": [\n'
  local_idx=0
  if [[ "${#EVIDENCE[@]}" -gt 0 ]]; then
    for item in "${EVIDENCE[@]}"; do
      printf '    "%s"' "$(json_escape "$item")"
      local_idx=$((local_idx + 1))
      [[ "$local_idx" -lt "${#EVIDENCE[@]}" ]] && printf ','
      printf '\n'
    done
  fi
  printf '  ],\n'
  printf '  "source": {\n'
  printf '    "review_package": "%s"\n' "$(json_escape "$REVIEW_PACKAGE")"
  printf '  }\n'
  printf '}\n'
} > "$OUT"

echo "Review summary: ${OUT#$PROJECT_ROOT/}"
