#!/usr/bin/env bash
# outcome-report.sh — Summarize outcome links and attribution signals.
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "outcome report" "Summarize outcome links and attribution signals" \
    "outcome-report.sh                                      Print Markdown report from lattice/state/outcomes" \
    "outcome-report.sh --out=<file>                         Write Markdown report to file" \
    "outcome-report.sh --outcomes-dir=<dir> --eval-dir=<dir> --limit=20"
done

OUTCOME_DIR="$PROJECT_ROOT/lattice/state/outcomes"
EVAL_DIR="$PROJECT_ROOT/lattice/state/eval-runs"
OUT=""
LIMIT=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --outcomes-dir=*) OUTCOME_DIR="${1#--outcomes-dir=}" ;;
    --eval-dir=*) EVAL_DIR="${1#--eval-dir=}" ;;
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
      OUTCOME_DIR="$1"
      ;;
  esac
  shift
done

[[ "$OUTCOME_DIR" == /* ]] || OUTCOME_DIR="$PROJECT_ROOT/$OUTCOME_DIR"
[[ "$EVAL_DIR" == /* ]] || EVAL_DIR="$PROJECT_ROOT/$EVAL_DIR"
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

declare -a OUTCOME_FILES=()
if [[ -d "$OUTCOME_DIR" ]]; then
  while IFS= read -r file; do
    if yq -e '.kind == "outcome-link" and .eval_run.run_id and .outcome.type' "$file" >/dev/null 2>&1; then
      OUTCOME_FILES+=("$file")
    fi
  done < <(find "$OUTCOME_DIR" -maxdepth 1 -type f -name '*.json' -print 2>/dev/null | sort)
fi

OUTCOME_TOTAL="${#OUTCOME_FILES[@]}"
TYPE_REVIEW_FINDING=0
TYPE_REWORK=0
TYPE_ESCAPED_DEFECT=0
TYPE_INCIDENT=0
TYPE_SUCCESS=0
SEV_NONE=0
SEV_LOW=0
SEV_MEDIUM=0
SEV_HIGH=0
SEV_CRITICAL=0
NEGATIVE_TOTAL=0

TMP_REFS="$(mktemp "${TMPDIR:-/tmp}/lattice-outcome-refs.XXXXXX")"
cleanup() {
  rm -f "$TMP_REFS"
}
trap cleanup EXIT

risk_flags() {
  local file="$1" type severity flags context_runs blocking_gaps review_failed review_cannot_verify
  type="$(json_get "$file" '.outcome.type')"
  severity="$(json_get "$file" '.outcome.severity')"
  context_runs="$(json_num "$file" '.eval_metrics.context_run_total')"
  blocking_gaps="$(json_num "$file" '.eval_metrics.context_blocking_gaps')"
  review_failed="$(json_num "$file" '.eval_metrics.review_failed')"
  review_cannot_verify="$(json_num "$file" '.eval_metrics.review_cannot_verify')"
  flags=()

  case "$type" in
    rework|escaped_defect|incident) flags+=("negative-outcome") ;;
  esac
  case "$severity" in
    high|critical) flags+=("severe-outcome") ;;
  esac
  [[ "$context_runs" -eq 0 ]] && flags+=("no-context-run")
  [[ "$blocking_gaps" -gt 0 ]] && flags+=("blocking-context-gap")
  [[ "$review_failed" -gt 0 ]] && flags+=("review-failed")
  [[ "$review_cannot_verify" -gt 0 ]] && flags+=("review-cannot-verify")

  if [[ "${#flags[@]}" -eq 0 ]]; then
    printf 'none'
  else
    local joined="" flag
    for flag in "${flags[@]}"; do
      [[ -n "$joined" ]] && joined+=", "
      joined+="$flag"
    done
    printf '%s' "$joined"
  fi
}

record_context_refs() {
  local file="$1" ref
  while IFS= read -r ref; do
    [[ -n "$ref" ]] || continue
    printf '%s\n' "$ref" >> "$TMP_REFS"
  done < <(yq -r '(.context_refs // [])[]' "$file" 2>/dev/null || true)
}

if [[ "$OUTCOME_TOTAL" -gt 0 ]]; then
  for file in "${OUTCOME_FILES[@]}"; do
    type="$(json_get "$file" '.outcome.type')"
    severity="$(json_get "$file" '.outcome.severity')"
    case "$type" in
      review_finding) TYPE_REVIEW_FINDING=$((TYPE_REVIEW_FINDING + 1)) ;;
      rework) TYPE_REWORK=$((TYPE_REWORK + 1)); NEGATIVE_TOTAL=$((NEGATIVE_TOTAL + 1)) ;;
      escaped_defect) TYPE_ESCAPED_DEFECT=$((TYPE_ESCAPED_DEFECT + 1)); NEGATIVE_TOTAL=$((NEGATIVE_TOTAL + 1)) ;;
      incident) TYPE_INCIDENT=$((TYPE_INCIDENT + 1)); NEGATIVE_TOTAL=$((NEGATIVE_TOTAL + 1)) ;;
      success) TYPE_SUCCESS=$((TYPE_SUCCESS + 1)) ;;
    esac
    case "$severity" in
      none) SEV_NONE=$((SEV_NONE + 1)) ;;
      low) SEV_LOW=$((SEV_LOW + 1)) ;;
      medium) SEV_MEDIUM=$((SEV_MEDIUM + 1)) ;;
      high) SEV_HIGH=$((SEV_HIGH + 1)) ;;
      critical) SEV_CRITICAL=$((SEV_CRITICAL + 1)) ;;
    esac
    record_context_refs "$file"
  done
fi

render_report() {
  echo "# Lattice Outcome Attribution Report"
  echo ""
  echo "> This report surfaces attribution signals. It does not prove causality."
  echo ""
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Outcomes | $OUTCOME_TOTAL |"
  echo "| Negative outcomes | $NEGATIVE_TOTAL |"
  echo "| Review findings | $TYPE_REVIEW_FINDING |"
  echo "| Rework | $TYPE_REWORK |"
  echo "| Escaped defects | $TYPE_ESCAPED_DEFECT |"
  echo "| Incidents | $TYPE_INCIDENT |"
  echo "| Success signals | $TYPE_SUCCESS |"
  echo "| Severity | none=$SEV_NONE, low=$SEV_LOW, medium=$SEV_MEDIUM, high=$SEV_HIGH, critical=$SEV_CRITICAL |"
  echo ""
  echo "## Context Ref Signals"
  echo ""
  if [[ -s "$TMP_REFS" ]]; then
    echo "| Context Ref | Outcome Count |"
    echo "|---|---|"
    sort "$TMP_REFS" | uniq -c | sort -rn | head -"$LIMIT" | awk '{
      count=$1
      $1=""
      sub(/^ /, "", $0)
      gsub(/\|/, "\\\\|", $0)
      printf "| %s | %s |\n", $0, count
    }'
  else
    echo "_No context refs recorded in outcome links._"
  fi

  echo ""
  echo "## Runs Needing Review"
  echo ""
  if [[ "$OUTCOME_TOTAL" -eq 0 ]]; then
    echo "_No outcome links found._"
    return 0
  fi

  echo "| Run | Spec | Type | Severity | Source | Signals | Context Refs | Summary |"
  echo "|---|---|---|---|---|---|---|---|"

  local start_index=0
  if [[ "$OUTCOME_TOTAL" -gt "$LIMIT" ]]; then
    start_index=$((OUTCOME_TOTAL - LIMIT))
  fi

  local i file run_id spec type severity source summary refs flags
  for ((i = OUTCOME_TOTAL - 1; i >= start_index; i--)); do
    file="${OUTCOME_FILES[$i]}"
    run_id="$(json_get "$file" '.eval_run.run_id')"
    spec="$(json_get "$file" '.eval_run.spec_file')"
    type="$(json_get "$file" '.outcome.type')"
    severity="$(json_get "$file" '.outcome.severity')"
    source="$(json_get "$file" '.outcome.source')"
    summary="$(json_get "$file" '.outcome.summary')"
    refs="$(yq -r '(.context_refs // []) | join(", ")' "$file" 2>/dev/null || true)"
    flags="$(risk_flags "$file")"
    echo "| $(md_escape "${run_id:-unknown}") | $(md_escape "${spec:-none}") | $(md_escape "${type:-unknown}") | $(md_escape "${severity:-unknown}") | $(md_escape "${source:-unknown}") | $(md_escape "$flags") | $(md_escape "$refs") | $(md_escape "$summary") |"
  done
}

if [[ -n "$OUT" ]]; then
  mkdir -p "$(dirname "$OUT")"
  render_report > "$OUT"
  echo "Outcome attribution report: ${OUT#$PROJECT_ROOT/}"
else
  render_report
fi
