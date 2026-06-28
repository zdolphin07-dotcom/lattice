#!/usr/bin/env bash
# eval-summary.sh - Render a pipeline eval JSON as human-readable Markdown.
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "eval summary" "Render eval run JSON as Markdown" \
    "eval-summary.sh <eval-json>                 Print Markdown to stdout" \
    "eval-summary.sh <eval-json> --out=<file>    Write Markdown to file"
done

EVAL_JSON=""
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
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
      if [[ -z "$EVAL_JSON" ]]; then
        EVAL_JSON="$1"
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$EVAL_JSON" ]]; then
  echo "Usage: eval-summary.sh <eval-json> [--out=<file>]"
  exit 1
fi

[[ "$EVAL_JSON" == /* ]] || EVAL_JSON="$PROJECT_ROOT/$EVAL_JSON"
[[ -f "$EVAL_JSON" ]] || { echo "Eval JSON not found: $EVAL_JSON"; exit 1; }

if [[ -n "$OUT" && "$OUT" != /* ]]; then
  OUT="$PROJECT_ROOT/$OUT"
fi

json_get() {
  local expr="$1"
  local value
  value=$(yq -r "$expr // \"\"" "$EVAL_JSON" 2>/dev/null || true)
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

metric_value() {
  local key="$1"
  json_get ".metrics.${key}"
}

gate_metric_summary() {
  local idx="$1"
  local gate ac_total ac_covered ac_uncovered drift_count warnings
  gate="$(json_get ".gates[$idx].gate")"
  case "$gate" in
    ac-coverage)
      ac_total="$(json_get ".gates[$idx].metrics.ac_total")"
      ac_covered="$(json_get ".gates[$idx].metrics.ac_covered")"
      ac_uncovered="$(json_get ".gates[$idx].metrics.ac_uncovered")"
      printf 'ac=%s/%s, uncovered=%s' "${ac_covered:-0}" "${ac_total:-0}" "${ac_uncovered:-0}"
      ;;
    drift-check)
      drift_count="$(json_get ".gates[$idx].metrics.drift_count")"
      printf 'drift_count=%s' "${drift_count:-0}"
      ;;
    compliance)
      warnings="$(json_get ".gates[$idx].metrics.warnings")"
      printf 'warnings=%s' "${warnings:-0}"
      ;;
    *)
      printf '%s' "-"
      ;;
  esac
}

render_summary() {
  local status project spec_file git_sha kernel_version duration_ms exit_code
  local steps_total steps_passed steps_failed steps_skipped
  local ac_total ac_covered ac_uncovered drift_count compliance_warnings
  local review_total review_passed review_failed review_cannot_verify
  local tdd_total tdd_complete tdd_invalid
  local loop_retry_count loop_retry_max loop_next_action loop_failed_step loop_learn_draft

  status="$(json_get ".pipeline.status")"
  project="$(json_get ".project")"
  spec_file="$(json_get ".spec_file")"
  git_sha="$(json_get ".git_sha")"
  kernel_version="$(json_get ".kernel_version")"
  duration_ms="$(json_get ".pipeline.duration_ms")"
  exit_code="$(json_get ".pipeline.exit_code")"
  steps_total="$(metric_value "steps_total")"
  steps_passed="$(metric_value "steps_passed")"
  steps_failed="$(metric_value "steps_failed")"
  steps_skipped="$(metric_value "steps_skipped")"
  ac_total="$(metric_value "ac_total")"
  ac_covered="$(metric_value "ac_covered")"
  ac_uncovered="$(metric_value "ac_uncovered")"
  drift_count="$(metric_value "drift_count")"
  compliance_warnings="$(metric_value "compliance_warnings")"
  review_total="$(metric_value "review_total")"
  review_passed="$(metric_value "review_passed")"
  review_failed="$(metric_value "review_failed")"
  review_cannot_verify="$(metric_value "review_cannot_verify")"
  tdd_total="$(metric_value "tdd_total")"
  tdd_complete="$(metric_value "tdd_complete")"
  tdd_invalid="$(metric_value "tdd_invalid")"
  loop_retry_count="$(json_get ".loop_state.retry_count")"
  loop_retry_max="$(json_get ".loop_state.retry_max")"
  loop_next_action="$(json_get ".loop_state.next_action")"
  loop_failed_step="$(json_get ".loop_state.failed_step")"
  loop_learn_draft="$(json_get ".loop_state.learn_draft")"

  echo "# Lattice Eval Summary"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Status | $(md_escape "${status:-unknown}") |"
  echo "| Project | $(md_escape "${project:-unknown}") |"
  echo "| Spec | $(md_escape "${spec_file:-none}") |"
  echo "| Git SHA | $(md_escape "${git_sha:-unknown}") |"
  echo "| Kernel | $(md_escape "${kernel_version:-unknown}") |"
  echo "| Duration | $(md_escape "${duration_ms:-0}") ms |"
  echo "| Exit Code | $(md_escape "${exit_code:-0}") |"
  echo ""
  echo "## Metrics"
  echo ""
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Steps | $(md_escape "${steps_passed:-0}") passed / $(md_escape "${steps_failed:-0}") failed / $(md_escape "${steps_skipped:-0}") skipped / $(md_escape "${steps_total:-0}") total |"
  echo "| AC Coverage | $(md_escape "${ac_covered:-0}") / $(md_escape "${ac_total:-0}") covered, $(md_escape "${ac_uncovered:-0}") uncovered |"
  echo "| Drift Count | $(md_escape "${drift_count:-0}") |"
  echo "| Compliance Warnings | $(md_escape "${compliance_warnings:-0}") |"
  echo "| Review Verdicts | $(md_escape "${review_passed:-0}") pass / $(md_escape "${review_failed:-0}") fail / $(md_escape "${review_cannot_verify:-0}") cannot_verify / $(md_escape "${review_total:-0}") total |"
  echo "| TDD Evidence | $(md_escape "${tdd_complete:-0}") complete / $(md_escape "${tdd_invalid:-0}") invalid / $(md_escape "${tdd_total:-0}") total |"
  echo "| Loop | retry $(md_escape "${loop_retry_count:-0}") / $(md_escape "${loop_retry_max:-0}"), next=$(md_escape "${loop_next_action:-unknown}"), failed_step=$(md_escape "${loop_failed_step:-none}") |"
  [[ -n "$loop_learn_draft" ]] && echo "| Learn Draft | $(md_escape "$loop_learn_draft") |"
  echo ""
  echo "## Gates"
  echo ""

  local gate_count
  gate_count="$(yq -r '(.gates // []) | length' "$EVAL_JSON")"
  if [[ "$gate_count" -eq 0 ]]; then
    echo "_No structured gate JSON captured._"
  else
    echo "| Gate | Status | Key Metrics |"
    echo "|---|---|---|"
    local i gate gate_status metrics
    for i in $(seq 0 $((gate_count - 1))); do
      gate="$(json_get ".gates[$i].gate")"
      gate_status="$(json_get ".gates[$i].status")"
      metrics="$(gate_metric_summary "$i")"
      echo "| $(md_escape "${gate:-unknown}") | $(md_escape "${gate_status:-unknown}") | $(md_escape "$metrics") |"
    done
  fi

  echo ""
  echo "## Review Evidence"
  echo ""

  local review_count
  review_count="$(yq -r '(.process_evidence.review_summaries // []) | length' "$EVAL_JSON")"
  if [[ "$review_count" -eq 0 ]]; then
    echo "_No review-summary.json captured._"
  else
    echo "| Task | Verdict | Axes | Findings |"
    echo "|---|---|---|---|"
    local i task verdict axes findings_count
    for i in $(seq 0 $((review_count - 1))); do
      task="$(json_get ".process_evidence.review_summaries[$i].task_id")"
      verdict="$(json_get ".process_evidence.review_summaries[$i].verdict")"
      axes="spec=$(json_get ".process_evidence.review_summaries[$i].axes.spec_compliance"), code=$(json_get ".process_evidence.review_summaries[$i].axes.code_quality"), test=$(json_get ".process_evidence.review_summaries[$i].axes.test_coverage"), risk=$(json_get ".process_evidence.review_summaries[$i].axes.risk")"
      findings_count="$(yq -r "(.process_evidence.review_summaries[$i].findings // []) | length" "$EVAL_JSON")"
      echo "| $(md_escape "${task:-unknown}") | $(md_escape "${verdict:-unknown}") | $(md_escape "$axes") | $(md_escape "$findings_count") |"
    done
  fi

  echo ""
  echo "## TDD Evidence"
  echo ""

  local tdd_count
  tdd_count="$(yq -r '(.process_evidence.tdd_evidence // []) | length' "$EVAL_JSON")"
  if [[ "$tdd_count" -eq 0 ]]; then
    echo "_No tdd-evidence.json captured._"
  else
    echo "| Task | Status | ACs | Test |"
    echo "|---|---|---|---|"
    local i task status ac_ids test_name
    for i in $(seq 0 $((tdd_count - 1))); do
      task="$(json_get ".process_evidence.tdd_evidence[$i].task_id")"
      status="$(json_get ".process_evidence.tdd_evidence[$i].status")"
      ac_ids="$(yq -r "(.process_evidence.tdd_evidence[$i].ac_ids // []) | join(\", \")" "$EVAL_JSON")"
      test_name="$(json_get ".process_evidence.tdd_evidence[$i].test.name")"
      echo "| $(md_escape "${task:-unknown}") | $(md_escape "${status:-unknown}") | $(md_escape "$ac_ids") | $(md_escape "$test_name") |"
    done
  fi

  echo ""
  echo "## Failed Steps"
  echo ""

  local step_count failed_count
  step_count="$(yq -r '(.steps // []) | length' "$EVAL_JSON")"
  failed_count=0
  if [[ "$step_count" -gt 0 ]]; then
    local i step_name step_exit step_summary
    for i in $(seq 0 $((step_count - 1))); do
      if [[ "$(json_get ".steps[$i].status")" == "fail" ]]; then
        failed_count=$((failed_count + 1))
        step_name="$(json_get ".steps[$i].name")"
        step_exit="$(json_get ".steps[$i].exit_code")"
        step_summary="$(json_get ".steps[$i].summary")"
        echo "- $(md_escape "$step_name") (exit $(md_escape "${step_exit:-1}")): $(md_escape "$step_summary")"
      fi
    done
  fi

  if [[ "$failed_count" -eq 0 ]]; then
    echo "_No failed steps._"
  fi
}

if [[ -n "$OUT" ]]; then
  mkdir -p "$(dirname "$OUT")"
  render_summary > "$OUT"
  echo "Eval summary: ${OUT#$PROJECT_ROOT/}"
else
  render_summary
fi
