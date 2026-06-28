#!/usr/bin/env bash
# eval-history.sh - Aggregate eval run JSON files into a Markdown history report.
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "eval history" "Aggregate eval run JSON files into a Markdown report" \
    "eval-history.sh                                      Print history report from lattice/state/eval-runs" \
    "eval-history.sh --out=<file>                         Write Markdown report to file" \
    "eval-history.sh --dir=<dir> --limit=20                Use a custom eval-runs directory"
done

EVAL_DIR="$PROJECT_ROOT/lattice/state/eval-runs"
OUT=""
LIMIT=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir=*) EVAL_DIR="${1#--dir=}" ;;
    --out=*) OUT="${1#--out=}" ;;
    --out)
      shift
      OUT="${1:-}"
      ;;
    --limit=*) LIMIT="${1#--limit=}" ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      EVAL_DIR="$1"
      ;;
  esac
  shift
done

[[ "$EVAL_DIR" == /* ]] || EVAL_DIR="$PROJECT_ROOT/$EVAL_DIR"
[[ -d "$EVAL_DIR" ]] || { echo "Eval runs directory not found: $EVAL_DIR"; exit 1; }
if [[ -n "$OUT" && "$OUT" != /* ]]; then
  OUT="$PROJECT_ROOT/$OUT"
fi
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -eq 0 ]]; then
  echo "limit must be a positive integer"
  exit 1
fi

md_escape() {
  local value="${1:-}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/<br>}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

json_get() {
  local file="$1" expr="$2" value
  value="$(yq -r "$expr // \"\"" "$file" 2>/dev/null || true)"
  [[ "$value" == "null" ]] && value=""
  printf '%s' "$value"
}

json_num() {
  local file="$1" expr="$2" value
  value="$(json_get "$file" "$expr")"
  if [[ "$value" =~ ^-?[0-9]+$ ]]; then
    printf '%s' "$value"
  else
    printf '0'
  fi
}

declare -a EVAL_FILES=()
while IFS= read -r file; do
  if yq -e '.run_id and .pipeline and .metrics' "$file" >/dev/null 2>&1; then
    EVAL_FILES+=("$file")
  fi
done < <(find "$EVAL_DIR" -maxdepth 1 -type f -name '*.json' -print 2>/dev/null | sort)

RUN_TOTAL="${#EVAL_FILES[@]}"
PASS_TOTAL=0
FAIL_TOTAL=0
ESCALATION_TOTAL=0
AC_TOTAL=0
AC_COVERED=0
AC_UNCOVERED=0
DRIFT_TOTAL=0
COMPLIANCE_WARNINGS=0
REVIEW_TOTAL=0
REVIEW_PASSED=0
REVIEW_FAILED=0
REVIEW_CANNOT_VERIFY=0
TDD_TOTAL=0
TDD_COMPLETE=0
TDD_INVALID=0
RETRY_TOTAL=0
RETRY_RUNS=0
LOOP_RETRY_ACTIONS=0
LOOP_ESCALATE_ACTIONS=0
LEARN_DRAFT_TOTAL=0

if [[ "$RUN_TOTAL" -gt 0 ]]; then
  for file in "${EVAL_FILES[@]}"; do
    status="$(json_get "$file" '.pipeline.status')"
    case "$status" in
      pass) ((PASS_TOTAL++)) || true ;;
      fail) ((FAIL_TOTAL++)) || true ;;
      escalation) ((ESCALATION_TOTAL++)) || true ;;
    esac
    AC_TOTAL=$((AC_TOTAL + $(json_num "$file" '.metrics.ac_total')))
    AC_COVERED=$((AC_COVERED + $(json_num "$file" '.metrics.ac_covered')))
    AC_UNCOVERED=$((AC_UNCOVERED + $(json_num "$file" '.metrics.ac_uncovered')))
    DRIFT_TOTAL=$((DRIFT_TOTAL + $(json_num "$file" '.metrics.drift_count')))
    COMPLIANCE_WARNINGS=$((COMPLIANCE_WARNINGS + $(json_num "$file" '.metrics.compliance_warnings')))
    REVIEW_TOTAL=$((REVIEW_TOTAL + $(json_num "$file" '.metrics.review_total')))
    REVIEW_PASSED=$((REVIEW_PASSED + $(json_num "$file" '.metrics.review_passed')))
    REVIEW_FAILED=$((REVIEW_FAILED + $(json_num "$file" '.metrics.review_failed')))
    REVIEW_CANNOT_VERIFY=$((REVIEW_CANNOT_VERIFY + $(json_num "$file" '.metrics.review_cannot_verify')))
    TDD_TOTAL=$((TDD_TOTAL + $(json_num "$file" '.metrics.tdd_total')))
    TDD_COMPLETE=$((TDD_COMPLETE + $(json_num "$file" '.metrics.tdd_complete')))
    TDD_INVALID=$((TDD_INVALID + $(json_num "$file" '.metrics.tdd_invalid')))
    retry_count="$(json_num "$file" '.loop_state.retry_count')"
    RETRY_TOTAL=$((RETRY_TOTAL + retry_count))
    [[ "$retry_count" -gt 0 ]] && ((RETRY_RUNS++)) || true
    next_action="$(json_get "$file" '.loop_state.next_action')"
    [[ "$next_action" == "retry" ]] && ((LOOP_RETRY_ACTIONS++)) || true
    [[ "$next_action" == "escalate" ]] && ((LOOP_ESCALATE_ACTIONS++)) || true
    learn_draft="$(json_get "$file" '.loop_state.learn_draft')"
    [[ -n "$learn_draft" ]] && ((LEARN_DRAFT_TOTAL++)) || true
  done
fi

percent() {
  local numerator="$1" denominator="$2"
  if [[ "$denominator" -eq 0 ]]; then
    printf 'n/a'
  else
    printf '%s%%' $((numerator * 100 / denominator))
  fi
}

render_history() {
  echo "# Lattice Eval History"
  echo ""
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Runs | $RUN_TOTAL |"
  echo "| Pipeline Pass Rate | $(percent "$PASS_TOTAL" "$RUN_TOTAL") ($PASS_TOTAL pass / $FAIL_TOTAL fail / $ESCALATION_TOTAL escalation) |"
  echo "| AC Coverage | $(percent "$AC_COVERED" "$AC_TOTAL") ($AC_COVERED / $AC_TOTAL covered, $AC_UNCOVERED uncovered) |"
  echo "| Drift Count | $DRIFT_TOTAL |"
  echo "| Compliance Warnings | $COMPLIANCE_WARNINGS |"
  echo "| Review Verdicts | $REVIEW_PASSED pass / $REVIEW_FAILED fail / $REVIEW_CANNOT_VERIFY cannot_verify / $REVIEW_TOTAL total |"
  echo "| TDD Evidence | $TDD_COMPLETE complete / $TDD_INVALID invalid / $TDD_TOTAL total |"
  echo "| Loop | $RETRY_TOTAL total retries / $RETRY_RUNS retry runs / $LOOP_RETRY_ACTIONS next retry / $LOOP_ESCALATE_ACTIONS next escalate / $LEARN_DRAFT_TOTAL learn drafts |"
  echo ""
  echo "## Recent Runs"
  echo ""

  if [[ "$RUN_TOTAL" -eq 0 ]]; then
    echo "_No eval run JSON files found._"
    return 0
  fi

  echo "| Run | Status | Spec | Git | AC | Drift | Review | TDD | Loop |"
  echo "|---|---|---|---|---|---|---|---|---|"

  local start_index=0
  if [[ "$RUN_TOTAL" -gt "$LIMIT" ]]; then
    start_index=$((RUN_TOTAL - LIMIT))
  fi

  local i file run_id status spec git ac_total ac_covered drift review_total review_failed review_cannot_verify tdd_total tdd_invalid retry_count next_action failure_category learn_draft learn_flag
  for ((i = RUN_TOTAL - 1; i >= start_index; i--)); do
    file="${EVAL_FILES[$i]}"
    run_id="$(json_get "$file" '.run_id')"
    status="$(json_get "$file" '.pipeline.status')"
    spec="$(json_get "$file" '.spec_file')"
    git="$(json_get "$file" '.git_sha')"
    ac_total="$(json_num "$file" '.metrics.ac_total')"
    ac_covered="$(json_num "$file" '.metrics.ac_covered')"
    drift="$(json_num "$file" '.metrics.drift_count')"
    review_total="$(json_num "$file" '.metrics.review_total')"
    review_failed="$(json_num "$file" '.metrics.review_failed')"
    review_cannot_verify="$(json_num "$file" '.metrics.review_cannot_verify')"
    tdd_total="$(json_num "$file" '.metrics.tdd_total')"
    tdd_invalid="$(json_num "$file" '.metrics.tdd_invalid')"
    retry_count="$(json_num "$file" '.loop_state.retry_count')"
    next_action="$(json_get "$file" '.loop_state.next_action')"
    failure_category="$(json_get "$file" '.loop_state.failure_category')"
    learn_draft="$(json_get "$file" '.loop_state.learn_draft')"
    learn_flag="no"
    [[ -n "$learn_draft" ]] && learn_flag="yes"
    echo "| $(md_escape "${run_id:-unknown}") | $(md_escape "${status:-unknown}") | $(md_escape "${spec:-none}") | $(md_escape "${git:-unknown}") | $ac_covered/$ac_total | $drift | $review_failed fail / $review_cannot_verify cannot_verify / $review_total | $tdd_invalid invalid / $tdd_total | retry=$retry_count, next=$(md_escape "${next_action:-unknown}"), category=$(md_escape "${failure_category:-none}"), learn=$learn_flag |"
  done
}

if [[ -n "$OUT" ]]; then
  mkdir -p "$(dirname "$OUT")"
  render_history > "$OUT"
  echo "Eval history: ${OUT#$PROJECT_ROOT/}"
else
  render_history
fi
