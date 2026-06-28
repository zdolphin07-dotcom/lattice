#!/usr/bin/env bash
# pipeline.sh — Delivery pipeline
# Exit codes: 0=all green, 1=failure(retryable), 2=escalation(needs human)
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery pipeline" "Run manifest-driven delivery pipeline" \
    "pipeline.sh                          Run full pipeline" \
    "pipeline.sh --only=<step>            Run specific step (e.g. --only=build)" \
    "pipeline.sh --spec=<file>            Specify spec file" \
    "pipeline.sh --json-out[=<file>]      Write structured eval run JSON" \
    "pipeline.sh --skip-spec              Skip spec-related steps" \
    "pipeline.sh --skip-integration       Skip integration tests" \
    "" \
    "Environment variables:" \
    "  SH_RETRY_COUNT                     Current retry count (set by agent)" \
    "  SH_RETRY_MAX                       Max retries (default 3)"
done

SKIP_SPEC=false
SKIP_INTEGRATION=false
ONLY_STEP=""
USER_SPEC=""
WRITE_JSON=false
JSON_OUT=""
EVAL_JSON_FILE=""

for arg in "$@"; do
  case "$arg" in
    --skip-spec)       SKIP_SPEC=true ;;
    --skip-integration) SKIP_INTEGRATION=true ;;
    --only=*)          ONLY_STEP="${arg#--only=}" ;;
    --spec=*)          USER_SPEC="${arg#--spec=}" ;;
    --json-out)        WRITE_JSON=true ;;
    --json-out=*)      WRITE_JSON=true; JSON_OUT="${arg#--json-out=}" ;;
  esac
done

SH_RETRY_COUNT="${SH_RETRY_COUNT:-0}"
SH_RETRY_MAX="${SH_RETRY_MAX:-3}"
RUN_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_STARTED_SEC="$(date +%s)"
RUN_ID="${RUN_STARTED_AT//:/}"
RUN_ID="${RUN_ID//-/}"
RUN_ID="${RUN_ID}-$$"
GATE_JSON_DIR="$PROJECT_ROOT/lattice/state/eval-runs/${RUN_ID}.gates"
LOOP_JSON_FILE=""
LEARN_DRAFT_FILE=""
gate_json_files=()
process_review_files=()
process_tdd_files=()
FAILED_STEP=""
FAILED_EXIT_CODE=0
FAILED_SUMMARY=""
FAILED_CATEGORY=""
FAILED_DEFAULT_ACTION=""
FAILURE_CATEGORIES_FILE=""
METRIC_AC_TOTAL=0
METRIC_AC_COVERED=0
METRIC_AC_UNCOVERED=0
METRIC_DRIFT_COUNT=0
METRIC_COMPLIANCE_WARNINGS=0
METRIC_REVIEW_TOTAL=0
METRIC_REVIEW_PASSED=0
METRIC_REVIEW_FAILED=0
METRIC_REVIEW_CANNOT_VERIFY=0
METRIC_TDD_TOTAL=0
METRIC_TDD_COMPLETE=0
METRIC_TDD_INVALID=0

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

shell_quote() {
  printf '%q' "$1"
}

hash_file() {
  local file="$1"
  [[ -f "$file" ]] || { echo ""; return 0; }
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print "sha256:" $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print "sha256:" $1}'
  else
    echo ""
  fi
}

json_step_entries=()
record_step() {
  local step_name="$1" status="$2" command="$3" exit_code="$4" duration_ms="$5" summary="$6"
  json_step_entries+=("$(printf '{"name":"%s","status":"%s","command":"%s","exit_code":%s,"duration_ms":%s,"summary":"%s"}' \
    "$(json_escape "$step_name")" \
    "$(json_escape "$status")" \
    "$(json_escape "$command")" \
    "${exit_code:-null}" \
    "${duration_ms:-0}" \
    "$(json_escape "$summary")")")
}

collect_gate_json() {
  local gate_name="$1" file="$2"
  [[ -f "$file" ]] || return 0
  gate_json_files+=("$file")
  case "$gate_name" in
    ac-coverage)
      METRIC_AC_TOTAL=$((METRIC_AC_TOTAL + $(yq -r '.metrics.ac_total // 0' "$file" 2>/dev/null || echo 0)))
      METRIC_AC_COVERED=$((METRIC_AC_COVERED + $(yq -r '.metrics.ac_covered // 0' "$file" 2>/dev/null || echo 0)))
      METRIC_AC_UNCOVERED=$((METRIC_AC_UNCOVERED + $(yq -r '.metrics.ac_uncovered // 0' "$file" 2>/dev/null || echo 0)))
      ;;
    drift-check)
      METRIC_DRIFT_COUNT=$((METRIC_DRIFT_COUNT + $(yq -r '.metrics.drift_count // 0' "$file" 2>/dev/null || echo 0)))
      ;;
    compliance)
      METRIC_COMPLIANCE_WARNINGS=$((METRIC_COMPLIANCE_WARNINGS + $(yq -r '.metrics.warnings // 0' "$file" 2>/dev/null || echo 0)))
      ;;
  esac
}

spec_id_from_spec() {
  local spec="$1" rel
  [[ -n "$spec" ]] || return 1
  if [[ "$spec" == "$PROJECT_ROOT/"* ]]; then
    rel="${spec#$PROJECT_ROOT/}"
  else
    rel="$spec"
  fi
  case "$rel" in
    lattice/specs/*/spec.md)
      rel="${rel#lattice/specs/}"
      echo "${rel%%/*}"
      ;;
    *)
      return 1
      ;;
  esac
}

collect_process_evidence() {
  local spec_id evidence_dir file verdict status
  spec_id="$(spec_id_from_spec "$SPEC_FILE" 2>/dev/null || true)"
  [[ -n "$spec_id" ]] || return 0
  evidence_dir="$PROJECT_ROOT/.lattice/sdd/$spec_id"
  [[ -d "$evidence_dir" ]] || return 0

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    process_review_files+=("$file")
    ((METRIC_REVIEW_TOTAL++)) || true
    verdict="$(yq -r '.verdict // ""' "$file" 2>/dev/null || true)"
    verdict="${verdict//-/_}"
    case "$verdict" in
      pass) ((METRIC_REVIEW_PASSED++)) || true ;;
      fail) ((METRIC_REVIEW_FAILED++)) || true ;;
      cannot_verify) ((METRIC_REVIEW_CANNOT_VERIFY++)) || true ;;
    esac
  done < <(find "$evidence_dir" -type f -name 'review-summary.json' -print 2>/dev/null | sort)

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    process_tdd_files+=("$file")
    ((METRIC_TDD_TOTAL++)) || true
    status="$(yq -r '.status // ""' "$file" 2>/dev/null || true)"
    if [[ "$status" == "pass" ]]; then
      ((METRIC_TDD_COMPLETE++)) || true
    else
      ((METRIC_TDD_INVALID++)) || true
    fi
  done < <(find "$evidence_dir" -type f -name 'tdd-evidence.json' -print 2>/dev/null | sort)
}

resolve_failure_categories_file() {
  local configured
  configured="$(manifest_get '.pipeline.failure_categories_file')"
  [[ -n "$configured" ]] || configured="lattice/config/failure-categories.yaml"
  if [[ "$configured" == /* ]]; then
    FAILURE_CATEGORIES_FILE="$configured"
  else
    FAILURE_CATEGORIES_FILE="$PROJECT_ROOT/$configured"
  fi
}

config_failure_category() {
  local step_name="$1" output="$2" idx count step step_regex output_regex category action
  [[ -f "$FAILURE_CATEGORIES_FILE" ]] || return 1
  count="$(yq -r '(.rules // []) | length' "$FAILURE_CATEGORIES_FILE" 2>/dev/null || echo 0)"
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  [[ "$count" -gt 0 ]] || return 1

  for idx in $(seq 0 $((count - 1))); do
    step="$(yq -r ".rules[$idx].step // \"\"" "$FAILURE_CATEGORIES_FILE" 2>/dev/null || true)"
    step_regex="$(yq -r ".rules[$idx].step_regex // \"\"" "$FAILURE_CATEGORIES_FILE" 2>/dev/null || true)"
    output_regex="$(yq -r ".rules[$idx].output_regex // \"\"" "$FAILURE_CATEGORIES_FILE" 2>/dev/null || true)"

    if [[ -n "$output_regex" ]] && ! printf '%s\n' "$output" | grep -qiE "$output_regex"; then
      continue
    fi
    if [[ -n "$step" && "$step_name" != "$step" ]]; then
      continue
    fi
    if [[ -n "$step_regex" && ! "$step_name" =~ $step_regex ]]; then
      continue
    fi
    if [[ -z "$output_regex" && -z "$step" && -z "$step_regex" ]]; then
      continue
    fi

    category="$(yq -r ".rules[$idx].category // \"unknown\"" "$FAILURE_CATEGORIES_FILE" 2>/dev/null || echo "unknown")"
    action="$(yq -r ".rules[$idx].default_action // \"\"" "$FAILURE_CATEGORIES_FILE" 2>/dev/null || true)"
    [[ -n "$action" ]] || action="$(failure_default_action "$category")"
    printf '%s|%s\n' "$category" "$action"
    return 0
  done

  return 1
}

classify_failure_category() {
  local step_name="$1" output="$2"
  local configured
  configured="$(config_failure_category "$step_name" "$output" 2>/dev/null || true)"
  if [[ -n "$configured" ]]; then
    echo "${configured%%|*}"
    return 0
  fi

  if printf '%s\n' "$output" | grep -qiE 'command not found|missing required tool|cannot find|no such file|permission denied|docker.*not.*running|connection refused'; then
    echo "environment"
    return 0
  fi

  case "$step_name" in
    bootstrap) echo "environment" ;;
    spec-lint|prismspec-lint) echo "spec_structure" ;;
    ac-coverage) echo "ac_gap" ;;
    drift-check) echo "drift" ;;
    compliance) echo "compliance" ;;
    build|lint|test|unit-test|integration-test) echo "implementation" ;;
    deploy) echo "deployment" ;;
    *) echo "unknown" ;;
  esac
}

failure_default_action() {
  case "$1" in
    environment) echo "fix_environment" ;;
    spec_structure) echo "fix_spec" ;;
    ac_gap) echo "add_or_map_tests" ;;
    drift) echo "align_code_or_spec" ;;
    compliance) echo "add_context_or_clarification_evidence" ;;
    implementation) echo "fix_code" ;;
    deployment) echo "fix_deployment" ;;
    *) echo "escalate" ;;
  esac
}

classify_failure_default_action() {
  local step_name="$1" output="$2" category="$3"
  local configured
  configured="$(config_failure_category "$step_name" "$output" 2>/dev/null || true)"
  if [[ -n "$configured" ]]; then
    echo "${configured#*|}"
    return 0
  fi
  failure_default_action "$category"
}

echo "══════════════════════════════════"
echo "Lattice — Delivery Pipeline"
echo "Project: $(manifest_get '.project.name') ($(get_language))"
[[ "$SH_RETRY_COUNT" -gt 0 ]] && echo "Retry: $SH_RETRY_COUNT / $SH_RETRY_MAX"
echo "══════════════════════════════════"
echo ""

resolve_failure_categories_file

HAS_SPEC=false
SPEC_FILE="${USER_SPEC:-}"
if [[ -n "$SPEC_FILE" ]] && [[ -f "$SPEC_FILE" ]]; then
  HAS_SPEC=true
  export SPEC_FILE
elif spec=$(find_spec 2>/dev/null); then
  HAS_SPEC=true
  SPEC_FILE="$spec"
  export SPEC_FILE
else
  SPEC_FILE=""
fi

HAS_CODE=false
LANG=$(get_language)
case "$LANG" in
  go)     [[ -n "$(find "$PROJECT_ROOT" -maxdepth 5 -name '*.go' -not -path '*/vendor/*' 2>/dev/null | head -1)" ]] && HAS_CODE=true || true ;;
  node)   [[ -f "$PROJECT_ROOT/package.json" ]] && HAS_CODE=true ;;
  python) [[ -n "$(find "$PROJECT_ROOT" -maxdepth 5 -name '*.py' 2>/dev/null | head -1)" ]] && HAS_CODE=true || true ;;
  *)      HAS_CODE=true ;;
esac

HAS_INTEGRATION=false
if [[ -d "$PROJECT_ROOT/tests/integration" ]] || [[ -d "$PROJECT_ROOT/test/integration" ]]; then
  HAS_INTEGRATION=true
fi

should_skip() {
  local skip_when="$1"
  case "$skip_when" in
    no_spec)        [[ "$HAS_SPEC" == "false" ]] || [[ "$SKIP_SPEC" == "true" ]] ;;
    no_code)        [[ "$HAS_CODE" == "false" ]] ;;
    no_integration) [[ "$HAS_INTEGRATION" == "false" ]] || [[ "$SKIP_INTEGRATION" == "true" ]] ;;
    never)          return 1 ;;
    *)              return 1 ;;
  esac
}

STEP_COUNT=$(yq '.pipeline.steps | length' "$MANIFEST")
STEP_NUM=0
STEP_PASS=0
STEP_FAIL=0
STEP_SKIP=0

for i in $(seq 0 $((STEP_COUNT - 1))); do
  name=$(yq -r ".pipeline.steps[$i].name" "$MANIFEST")
  run=$(yq -r ".pipeline.steps[$i].run" "$MANIFEST")
  skip_when=$(yq -r ".pipeline.steps[$i].skip_when // \"never\"" "$MANIFEST")

  [[ -z "$name" || "$name" == "null" ]] && continue
  ((STEP_NUM++)) || true

  if [[ -n "$ONLY_STEP" ]] && [[ "$name" != "$ONLY_STEP" ]]; then
    continue
  fi

  if should_skip "$skip_when"; then
    printf "⏭️  [%d] %-20s SKIP (%s)\n" "$STEP_NUM" "$name" "$skip_when"
    ((STEP_SKIP++)) || true
    record_step "$name" "skip" "$run" "0" "0" "$skip_when"
    continue
  fi

  run="${run//\$\{SPEC_FILE\}/$SPEC_FILE}"
  run="${run//\$\{commands.build\}/$(manifest_get_cmd 'commands.build')}"
  run="${run//\$\{commands.lint\}/$(manifest_get_cmd 'commands.lint')}"
  run="${run//\$\{commands.test\}/$(manifest_get_cmd 'commands.test')}"
  run="${run//\$\{commands.integration_test\}/$(manifest_get_cmd 'commands.integration_test')}"

  gate_json_file=""
  if [[ "$WRITE_JSON" == "true" ]]; then
    case "$name" in
      ac-coverage|drift-check|compliance)
        mkdir -p "$GATE_JSON_DIR"
        gate_json_file="$GATE_JSON_DIR/${name}.json"
        run="$run --json-out=$(shell_quote "$gate_json_file")"
        ;;
    esac
  fi

  printf "🔄 [%d] %-20s → %s\n" "$STEP_NUM" "$name" "$run"

  step_started_sec="$(date +%s)"
  if output=$(run_cmd "$run" 2>&1); then
    step_duration_ms=$(( ($(date +%s) - step_started_sec) * 1000 ))
    [[ -n "$output" ]] && printf '%s\n' "$output" | tail -20
    printf "✅ [%d] %-20s PASS\n\n" "$STEP_NUM" "$name"
    ((STEP_PASS++)) || true
    record_step "$name" "pass" "$run" "0" "$step_duration_ms" "$(printf '%s\n' "$output" | tail -20)"
    [[ -n "$gate_json_file" ]] && collect_gate_json "$name" "$gate_json_file"
  else
    step_exit=$?
    step_duration_ms=$(( ($(date +%s) - step_started_sec) * 1000 ))
    printf '%s\n' "$output"
    printf "❌ [%d] %-20s FAIL\n\n" "$STEP_NUM" "$name"
    ((STEP_FAIL++)) || true
    record_step "$name" "fail" "$run" "$step_exit" "$step_duration_ms" "$(printf '%s\n' "$output" | tail -40)"
    FAILED_STEP="$name"
    FAILED_EXIT_CODE="$step_exit"
    FAILED_SUMMARY="$(printf '%s\n' "$output" | tail -40)"
    FAILED_CATEGORY="$(classify_failure_category "$name" "$output")"
    FAILED_DEFAULT_ACTION="$(classify_failure_default_action "$name" "$output" "$FAILED_CATEGORY")"
    [[ -n "$gate_json_file" ]] && collect_gate_json "$name" "$gate_json_file"
    echo "⛔ Pipeline stopped at step $STEP_NUM: $name"
    break
  fi
done

echo ""
echo "══════════════════════════════════"
echo "📊 Pipeline: ✅ $STEP_PASS  ❌ $STEP_FAIL  ⏭️  $STEP_SKIP / $STEP_NUM total steps"

RUN_ENDED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_DURATION_MS=$(( ($(date +%s) - RUN_STARTED_SEC) * 1000 ))
PIPELINE_STATUS="pass"
EXIT_CODE=0
if [[ $STEP_FAIL -gt 0 ]]; then
  PIPELINE_STATUS="fail"
  EXIT_CODE=1
  if [[ "$SH_RETRY_COUNT" -ge "$SH_RETRY_MAX" ]]; then
    PIPELINE_STATUS="escalation"
    EXIT_CODE=2
  fi
fi

loop_next_action() {
  if [[ "$PIPELINE_STATUS" == "pass" ]]; then
    echo "done"
  elif [[ "$PIPELINE_STATUS" == "escalation" ]]; then
    echo "escalate"
  else
    echo "retry"
  fi
}

resolve_eval_json_out() {
  [[ "$WRITE_JSON" == "true" ]] || return 0
  if [[ -n "$EVAL_JSON_FILE" ]]; then
    return 0
  fi
  if [[ -z "$JSON_OUT" ]]; then
    EVAL_JSON_FILE="$PROJECT_ROOT/lattice/state/eval-runs/${RUN_ID}.json"
  elif [[ "$JSON_OUT" == /* ]]; then
    EVAL_JSON_FILE="$JSON_OUT"
  else
    EVAL_JSON_FILE="$PROJECT_ROOT/$JSON_OUT"
  fi
}

write_learn_draft() {
  [[ "$WRITE_JSON" == "true" ]] || return 0
  [[ "$PIPELINE_STATUS" == "escalation" ]] || return 0
  local out loop_out spec_rel eval_rel loop_rel summary_block
  out="$PROJECT_ROOT/lattice/context/drafts/escalation-${RUN_ID}.md"
  loop_out="$PROJECT_ROOT/lattice/state/loops/${RUN_ID}.json"
  mkdir -p "$(dirname "$out")"
  spec_rel="${SPEC_FILE#$PROJECT_ROOT/}"
  eval_rel="${EVAL_JSON_FILE#$PROJECT_ROOT/}"
  loop_rel="${loop_out#$PROJECT_ROOT/}"
  summary_block="${FAILED_SUMMARY:-No failure summary captured.}"

  {
    printf -- '---\n'
    printf 'kind: learn-draft\n'
    printf 'schema_version: lattice.learn-draft.v1\n'
    printf 'status: draft\n'
    printf 'source: pipeline-escalation\n'
    printf 'run_id: "%s"\n' "$(json_escape "$RUN_ID")"
    printf 'created_at: "%s"\n' "$(json_escape "$RUN_ENDED_AT")"
    printf 'spec_file: "%s"\n' "$(json_escape "$spec_rel")"
    printf 'failed_step: "%s"\n' "$(json_escape "$FAILED_STEP")"
    printf 'failure_category: "%s"\n' "$(json_escape "$FAILED_CATEGORY")"
    printf 'default_action: "%s"\n' "$(json_escape "$FAILED_DEFAULT_ACTION")"
    printf -- '---\n\n'
    printf '# Learn Draft: Pipeline Escalation %s\n\n' "$RUN_ID"
    printf '## Why This Exists\n\n'
    printf 'The delivery pipeline exhausted its retry budget and needs human review before any durable knowledge is promoted.\n\n'
    printf '## Source Evidence\n\n'
    printf '| Field | Value |\n'
    printf '|---|---|\n'
    printf '| Run ID | `%s` |\n' "$RUN_ID"
    printf '| Spec | `%s` |\n' "${spec_rel:-none}"
    printf '| Failed Step | `%s` |\n' "${FAILED_STEP:-unknown}"
    printf '| Failure Category | `%s` |\n' "${FAILED_CATEGORY:-unknown}"
    printf '| Default Action | `%s` |\n' "${FAILED_DEFAULT_ACTION:-unknown}"
    printf '| Failed Exit Code | `%s` |\n' "$FAILED_EXIT_CODE"
    printf '| Retries | `%s / %s` |\n' "$SH_RETRY_COUNT" "$SH_RETRY_MAX"
    printf '| Loop State | `%s` |\n' "${loop_rel:-none}"
    printf '| Eval Run | `%s` |\n\n' "${eval_rel:-none}"
    printf '## Failure Summary\n\n'
    printf '```text\n'
    printf '%s\n' "$summary_block"
    printf '```\n\n'
    printf '## Lesson Candidate\n\n'
    printf '%s\n' '- Rule or pitfall:'
    printf '%s\n' '- Applies when:'
    printf '%s\n' '- Guidance:'
    printf '%s\n\n' '- Target knowledge file: `lattice/context/knowledge/`'
    printf '## Promotion Checklist\n\n'
    printf '%s\n' '- [ ] Confirm the lesson is durable and reusable.'
    printf '%s\n' '- [ ] Check existing project knowledge for duplicates or conflicts.'
    printf '%s\n' '- [ ] Remove one-off implementation details.'
    printf '%s\n' '- [ ] Ensure no secrets, private data, or raw production data are included.'
    printf '%s\n' '- [ ] Promote to `lattice/context/knowledge/` or discard this draft.'
  } > "$out"

  LEARN_DRAFT_FILE="$out"
  echo "📝 Learn draft: ${out#$PROJECT_ROOT/}"
}

write_loop_json() {
  [[ "$WRITE_JSON" == "true" ]] || return 0
  local out retry_remaining loop_status next_action spec_rel learn_draft_rel
  out="$PROJECT_ROOT/lattice/state/loops/${RUN_ID}.json"
  mkdir -p "$(dirname "$out")"
  retry_remaining=$((SH_RETRY_MAX - SH_RETRY_COUNT))
  [[ "$retry_remaining" -lt 0 ]] && retry_remaining=0
  loop_status="$PIPELINE_STATUS"
  next_action="$(loop_next_action)"
  spec_rel="${SPEC_FILE#$PROJECT_ROOT/}"
  learn_draft_rel="${LEARN_DRAFT_FILE#$PROJECT_ROOT/}"
  [[ "$learn_draft_rel" == "$LEARN_DRAFT_FILE" ]] && learn_draft_rel=""

  {
    printf '{\n'
    printf '  "schema_version": "lattice.loop-state.v1",\n'
    printf '  "kind": "loop-state",\n'
    printf '  "run_id": "%s",\n' "$(json_escape "$RUN_ID")"
    printf '  "created_at": "%s",\n' "$(json_escape "$RUN_ENDED_AT")"
    printf '  "status": "%s",\n' "$(json_escape "$loop_status")"
    printf '  "next_action": "%s",\n' "$(json_escape "$next_action")"
    printf '  "retry_count": %s,\n' "$SH_RETRY_COUNT"
    printf '  "retry_max": %s,\n' "$SH_RETRY_MAX"
    printf '  "retry_remaining": %s,\n' "$retry_remaining"
    printf '  "failed_step": "%s",\n' "$(json_escape "$FAILED_STEP")"
    printf '  "failed_exit_code": %s,\n' "$FAILED_EXIT_CODE"
    printf '  "failure_category": "%s",\n' "$(json_escape "$FAILED_CATEGORY")"
    printf '  "default_action": "%s",\n' "$(json_escape "$FAILED_DEFAULT_ACTION")"
    printf '  "failure_summary": "%s",\n' "$(json_escape "$FAILED_SUMMARY")"
    printf '  "spec_file": "%s",\n' "$(json_escape "$spec_rel")"
    printf '  "learn_draft": "%s"\n' "$(json_escape "$learn_draft_rel")"
    printf '}\n'
  } > "$out"

  LOOP_JSON_FILE="$out"
  echo "🔁 Loop state: ${out#$PROJECT_ROOT/}"
}

write_eval_json() {
  [[ "$WRITE_JSON" == "true" ]] || return 0
  resolve_eval_json_out
  local out="$EVAL_JSON_FILE"
  mkdir -p "$(dirname "$out")"

  local git_sha kernel_version spec_hash spec_rel agent_name
  git_sha="$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || true)"
  kernel_version=""
  [[ -f "$KERNEL_DIR/VERSION" ]] && kernel_version="$(tr -d '\n' < "$KERNEL_DIR/VERSION")"
  spec_hash="$(hash_file "$SPEC_FILE")"
  spec_rel="${SPEC_FILE#$PROJECT_ROOT/}"
  agent_name="${LATTICE_AGENT:-${AGENT_NAME:-unknown}}"

  {
    printf '{\n'
    printf '  "run_id": "%s",\n' "$(json_escape "$RUN_ID")"
    printf '  "started_at": "%s",\n' "$(json_escape "$RUN_STARTED_AT")"
    printf '  "ended_at": "%s",\n' "$(json_escape "$RUN_ENDED_AT")"
    printf '  "project": "%s",\n' "$(json_escape "$(manifest_get '.project.name')")"
    printf '  "language": "%s",\n' "$(json_escape "$(get_language)")"
    printf '  "git_sha": "%s",\n' "$(json_escape "$git_sha")"
    printf '  "spec_file": "%s",\n' "$(json_escape "$spec_rel")"
    printf '  "spec_hash": "%s",\n' "$(json_escape "$spec_hash")"
    printf '  "agent": "%s",\n' "$(json_escape "$agent_name")"
    printf '  "kernel_version": "%s",\n' "$(json_escape "$kernel_version")"
    printf '  "pipeline": {\n'
    printf '    "status": "%s",\n' "$PIPELINE_STATUS"
    printf '    "duration_ms": %s,\n' "$RUN_DURATION_MS"
    printf '    "retry_count": %s,\n' "$SH_RETRY_COUNT"
    printf '    "retry_max": %s,\n' "$SH_RETRY_MAX"
    printf '    "exit_code": %s\n' "$EXIT_CODE"
    printf '  },\n'
    printf '  "metrics": {\n'
    printf '    "steps_total": %s,\n' "$STEP_NUM"
    printf '    "steps_passed": %s,\n' "$STEP_PASS"
    printf '    "steps_failed": %s,\n' "$STEP_FAIL"
    printf '    "steps_skipped": %s,\n' "$STEP_SKIP"
    printf '    "ac_total": %s,\n' "$METRIC_AC_TOTAL"
    printf '    "ac_covered": %s,\n' "$METRIC_AC_COVERED"
    printf '    "ac_uncovered": %s,\n' "$METRIC_AC_UNCOVERED"
    printf '    "drift_count": %s,\n' "$METRIC_DRIFT_COUNT"
    printf '    "compliance_warnings": %s,\n' "$METRIC_COMPLIANCE_WARNINGS"
    printf '    "review_total": %s,\n' "$METRIC_REVIEW_TOTAL"
    printf '    "review_passed": %s,\n' "$METRIC_REVIEW_PASSED"
    printf '    "review_failed": %s,\n' "$METRIC_REVIEW_FAILED"
    printf '    "review_cannot_verify": %s,\n' "$METRIC_REVIEW_CANNOT_VERIFY"
    printf '    "tdd_total": %s,\n' "$METRIC_TDD_TOTAL"
    printf '    "tdd_complete": %s,\n' "$METRIC_TDD_COMPLETE"
    printf '    "tdd_invalid": %s,\n' "$METRIC_TDD_INVALID"
    printf '    "loop_retry_count": %s,\n' "$SH_RETRY_COUNT"
    printf '    "loop_retry_max": %s,\n' "$SH_RETRY_MAX"
    printf '    "loop_escalated": %s\n' "$([[ "$PIPELINE_STATUS" == "escalation" ]] && echo "true" || echo "false")"
    printf '  },\n'
    printf '  "steps": [\n'
    local idx
    for idx in "${!json_step_entries[@]}"; do
      printf '    %s' "${json_step_entries[$idx]}"
      [[ "$idx" -lt $((${#json_step_entries[@]} - 1)) ]] && printf ','
      printf '\n'
    done
    printf '  ],\n'
    printf '  "gates": [\n'
    local gate_idx
    for gate_idx in "${!gate_json_files[@]}"; do
      sed 's/^/    /' "${gate_json_files[$gate_idx]}"
      [[ "$gate_idx" -lt $((${#gate_json_files[@]} - 1)) ]] && printf ','
      printf '\n'
    done
    printf '  ],\n'
    printf '  "process_evidence": {\n'
    printf '    "review_summaries": [\n'
    local review_idx
    for review_idx in "${!process_review_files[@]}"; do
      sed 's/^/      /' "${process_review_files[$review_idx]}"
      [[ "$review_idx" -lt $((${#process_review_files[@]} - 1)) ]] && printf ','
      printf '\n'
    done
    printf '    ],\n'
    printf '    "tdd_evidence": [\n'
    local tdd_idx
    for tdd_idx in "${!process_tdd_files[@]}"; do
      sed 's/^/      /' "${process_tdd_files[$tdd_idx]}"
      [[ "$tdd_idx" -lt $((${#process_tdd_files[@]} - 1)) ]] && printf ','
      printf '\n'
    done
    printf '    ]\n'
    printf '  },\n'
    printf '  "loop_state": '
    if [[ -n "$LOOP_JSON_FILE" && -f "$LOOP_JSON_FILE" ]]; then
      tr -d '\n' < "$LOOP_JSON_FILE"
      printf '\n'
    else
      printf '{}\n'
    fi
    printf '}\n'
  } > "$out"

  echo "🧾 Eval JSON: ${out#$PROJECT_ROOT/}"
}

resolve_eval_json_out
collect_process_evidence
write_learn_draft
write_loop_json
write_eval_json

if [[ $STEP_FAIL -gt 0 ]]; then
  if [[ "$SH_RETRY_COUNT" -ge "$SH_RETRY_MAX" ]]; then
    echo ""
    echo "⚠️  ESCALATION — $SH_RETRY_COUNT retries exhausted"
    echo "══════════════════════════════════"
    echo "Diagnostics:"
    echo "  Failed step: $name"
    echo "  Project: $(manifest_get '.project.name')"
    echo "  Language: $(get_language)"
    echo "  Retries: $SH_RETRY_COUNT / $SH_RETRY_MAX"
    echo ""
    echo "Suggestions:"
    echo "  1. Review the full output of the failed step"
    echo "  2. Determine if it's a code issue or environment issue"
    echo "  3. Consider reducing spec scope or splitting the task"
    echo "══════════════════════════════════"
    echo "❌ ESCALATION — needs human intervention"
    exit 2
  fi
  echo ""
  echo "Hint: Agent can set SH_RETRY_COUNT=$((SH_RETRY_COUNT + 1)) and re-run"
  echo "❌ FAIL"
  exit 1
else
  echo "✅ ALL PASS"
  exit 0
fi
