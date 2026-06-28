#!/usr/bin/env bash
# summary-draft.sh — Generate a closeout summary.md draft from spec, plan, verification, and evidence.
source "$(dirname "$0")/../../_lib.sh"

usage_line="summary-draft.sh <spec-id|path/to/spec.md> [--eval-json=<file>] [--out=<file>]"
for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "summary draft" "Generate summary.md from delivery evidence" \
    "$usage_line" \
    "summary-draft.sh modern-feature --eval-json=lattice/state/eval-runs/run.json"
done

INPUT="${1:-}"
EVAL_JSON=""
OUT=""

shift $(( $# >= 1 ? 1 : $# ))
for arg in "$@"; do
  case "$arg" in
    --eval-json=*) EVAL_JSON="${arg#--eval-json=}" ;;
    --out=*) OUT="${arg#--out=}" ;;
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

count_pattern() {
  local pattern="$1" file="$2"
  { grep -E "$pattern" "$file" 2>/dev/null || true; } | wc -l | tr -d ' '
}

json_get() {
  local file="$1" expr="$2" value
  [[ -f "$file" ]] || { printf ''; return 0; }
  value="$(yq -r "$expr // \"\"" "$file" 2>/dev/null || true)"
  [[ "$value" == "null" ]] && value=""
  printf '%s' "$value"
}

md_escape() {
  local value="${1:-}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/<br>}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

SPEC_FILE="$(resolve_spec_file "$INPUT")"
SPEC_DIR="$(dirname "$SPEC_FILE")"
SPEC_ID="$(basename "$SPEC_DIR")"
SPEC_REL="$(rel_path "$SPEC_FILE")"
PLAN_FILE="$SPEC_DIR/plan.md"
VERIFY_FILE="$SPEC_DIR/verify.md"
EVIDENCE_ROOT="$PROJECT_ROOT/.lattice/sdd/$SPEC_ID"
OUT="${OUT:-$SPEC_DIR/summary.md}"
[[ "$OUT" == /* ]] || OUT="$PROJECT_ROOT/$OUT"

if [[ -n "$EVAL_JSON" ]]; then
  [[ "$EVAL_JSON" == /* ]] || EVAL_JSON="$PROJECT_ROOT/$EVAL_JSON"
  [[ -f "$EVAL_JSON" ]] || { echo "Eval JSON not found: $EVAL_JSON"; exit 1; }
fi

STATUS="$(frontmatter_value "status" "$SPEC_FILE")"
MODE="$(frontmatter_value "execution_mode" "$SPEC_FILE")"
AC_IDS="$({ grep -oE 'AC-[0-9]+' "$SPEC_FILE" || true; } | sort -u | tr '\n' ' ')"
TASK_TOTAL=0
TASK_COMPLETE=0
if [[ -f "$PLAN_FILE" ]]; then
  TASK_TOTAL="$(count_pattern '^- \[[ xX]\] (T[0-9]+|RED-[0-9]+):' "$PLAN_FILE")"
  TASK_COMPLETE="$(count_pattern '^- \[[xX]\] (T[0-9]+|RED-[0-9]+):' "$PLAN_FILE")"
fi

BRIEF_COUNT=0
REVIEW_PACKAGE_COUNT=0
REVIEW_SUMMARY_COUNT=0
TDD_COUNT=0
REVIEW_PASS=0
REVIEW_FAIL=0
REVIEW_CANNOT=0
TDD_PASS=0
if [[ -d "$EVIDENCE_ROOT" ]]; then
  BRIEF_COUNT="$(find "$EVIDENCE_ROOT" -type f -name 'brief.md' -print 2>/dev/null | wc -l | tr -d ' ')"
  REVIEW_PACKAGE_COUNT="$(find "$EVIDENCE_ROOT" -type f -name 'review-package.md' -print 2>/dev/null | wc -l | tr -d ' ')"
  REVIEW_SUMMARY_COUNT="$(find "$EVIDENCE_ROOT" -type f -name 'review-summary.json' -print 2>/dev/null | wc -l | tr -d ' ')"
  TDD_COUNT="$(find "$EVIDENCE_ROOT" -type f -name 'tdd-evidence.json' -print 2>/dev/null | wc -l | tr -d ' ')"
  while IFS= read -r file; do
    verdict="$(json_get "$file" '.verdict')"
    verdict="${verdict//-/_}"
    case "$verdict" in
      pass) REVIEW_PASS=$((REVIEW_PASS + 1)) ;;
      fail) REVIEW_FAIL=$((REVIEW_FAIL + 1)) ;;
      cannot_verify) REVIEW_CANNOT=$((REVIEW_CANNOT + 1)) ;;
    esac
  done < <(find "$EVIDENCE_ROOT" -type f -name 'review-summary.json' -print 2>/dev/null | sort)
  while IFS= read -r file; do
    [[ "$(json_get "$file" '.status')" == "pass" ]] && TDD_PASS=$((TDD_PASS + 1))
  done < <(find "$EVIDENCE_ROOT" -type f -name 'tdd-evidence.json' -print 2>/dev/null | sort)
fi

PIPELINE_STATUS=""
AC_TOTAL=""
AC_COVERED=""
AC_UNCOVERED=""
DRIFT_COUNT=""
COMPLIANCE_WARNINGS=""
if [[ -n "$EVAL_JSON" ]]; then
  PIPELINE_STATUS="$(json_get "$EVAL_JSON" '.pipeline.status')"
  AC_TOTAL="$(json_get "$EVAL_JSON" '.metrics.ac_total')"
  AC_COVERED="$(json_get "$EVAL_JSON" '.metrics.ac_covered')"
  AC_UNCOVERED="$(json_get "$EVAL_JSON" '.metrics.ac_uncovered')"
  DRIFT_COUNT="$(json_get "$EVAL_JSON" '.metrics.drift_count')"
  COMPLIANCE_WARNINGS="$(json_get "$EVAL_JSON" '.metrics.compliance_warnings')"
fi

mkdir -p "$(dirname "$OUT")"
{
  echo "# Summary: $SPEC_ID"
  echo ""
  echo "## Evidence Closeout"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Spec | \`$(md_escape "$SPEC_REL")\` |"
  echo "| Status before closeout | $(md_escape "${STATUS:-unknown}") |"
  echo "| Execution mode | $(md_escape "${MODE:-unknown}") |"
  echo "| Acceptance Criteria | $(md_escape "${AC_IDS:-none}") |"
  if [[ -n "$EVAL_JSON" ]]; then
    echo "| Eval JSON | \`$(md_escape "$(rel_path "$EVAL_JSON")")\` |"
    echo "| Pipeline status | $(md_escape "${PIPELINE_STATUS:-unknown}") |"
  else
    echo "| Eval JSON | not provided |"
    echo "| Pipeline status | unknown |"
  fi
  echo ""
  echo "## Task Evidence"
  echo ""
  echo "| Evidence | Count |"
  echo "|---|---:|"
  echo "| Plan tasks complete | $(md_escape "$TASK_COMPLETE") / $(md_escape "$TASK_TOTAL") |"
  echo "| Task briefs | $(md_escape "$BRIEF_COUNT") |"
  echo "| Review packages | $(md_escape "$REVIEW_PACKAGE_COUNT") |"
  echo "| Review summaries | $(md_escape "$REVIEW_SUMMARY_COUNT") |"
  echo "| TDD evidence | $(md_escape "$TDD_PASS") pass / $(md_escape "$TDD_COUNT") total |"
  echo ""
  echo "## Verification Evidence"
  echo ""
  if [[ -f "$VERIFY_FILE" ]]; then
    sed -n '1,120p' "$VERIFY_FILE"
  else
    echo "_No verify.md found._"
  fi
  echo ""
  echo "## Eval Metrics"
  echo ""
  if [[ -n "$EVAL_JSON" ]]; then
    echo "| Metric | Value |"
    echo "|---|---|"
    echo "| AC coverage | $(md_escape "${AC_COVERED:-0}") / $(md_escape "${AC_TOTAL:-0}") covered, $(md_escape "${AC_UNCOVERED:-0}") uncovered |"
    echo "| Drift count | $(md_escape "${DRIFT_COUNT:-0}") |"
    echo "| Compliance warnings | $(md_escape "${COMPLIANCE_WARNINGS:-0}") |"
    echo "| Review verdicts | $(md_escape "$REVIEW_PASS") pass / $(md_escape "$REVIEW_FAIL") fail / $(md_escape "$REVIEW_CANNOT") cannot_verify |"
  else
    echo "_No eval JSON provided. Run delivery pipeline and regenerate if pipeline metrics are required._"
  fi
  echo ""
  echo "## Residual Risks And Follow-ups"
  echo ""
  if [[ -n "$EVAL_JSON" && "${AC_UNCOVERED:-0}" != "0" ]]; then
    echo "- AC coverage is incomplete: ${AC_UNCOVERED:-0} uncovered AC(s)."
  fi
  if [[ -n "$EVAL_JSON" && "${DRIFT_COUNT:-0}" != "0" ]]; then
    echo "- Drift check reported ${DRIFT_COUNT:-0} drift item(s)."
  fi
  if [[ "$REVIEW_FAIL" != "0" || "$REVIEW_CANNOT" != "0" ]]; then
    echo "- Review evidence includes ${REVIEW_FAIL} fail and ${REVIEW_CANNOT} cannot_verify verdict(s)."
  fi
  if [[ "${AC_UNCOVERED:-0}" == "0" && "${DRIFT_COUNT:-0}" == "0" && "$REVIEW_FAIL" == "0" && "$REVIEW_CANNOT" == "0" ]]; then
    echo "- None known from captured evidence."
  fi
  echo ""
  echo "## Knowledge Candidates"
  echo ""
  echo "- No durable lesson selected yet. Promote only reusable, non-secret lessons through the learn workflow."
} > "$OUT"

echo "$(rel_path "$OUT")"
