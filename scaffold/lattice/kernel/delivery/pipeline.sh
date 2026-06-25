#!/usr/bin/env bash
# pipeline.sh — Delivery pipeline
# Exit codes: 0=all green, 1=failure(retryable), 2=escalation(needs human)
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery pipeline" "Run manifest-driven delivery pipeline" \
    "pipeline.sh                          Run full pipeline" \
    "pipeline.sh --only=<step>            Run specific step (e.g. --only=build)" \
    "pipeline.sh --spec=<file>            Specify spec file" \
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

for arg in "$@"; do
  case "$arg" in
    --skip-spec)       SKIP_SPEC=true ;;
    --skip-integration) SKIP_INTEGRATION=true ;;
    --only=*)          ONLY_STEP="${arg#--only=}" ;;
    --spec=*)          USER_SPEC="${arg#--spec=}" ;;
  esac
done

SH_RETRY_COUNT="${SH_RETRY_COUNT:-0}"
SH_RETRY_MAX="${SH_RETRY_MAX:-3}"

echo "══════════════════════════════════"
echo "Lattice — Delivery Pipeline"
echo "Project: $(manifest_get '.project.name') ($(get_language))"
[[ "$SH_RETRY_COUNT" -gt 0 ]] && echo "Retry: $SH_RETRY_COUNT / $SH_RETRY_MAX"
echo "══════════════════════════════════"
echo ""

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
  go)     [[ -n "$(find "$PROJECT_ROOT" -name '*.go' -not -path '*/vendor/*' -maxdepth 5 2>/dev/null | head -1)" ]] && HAS_CODE=true ;;
  node)   [[ -f "$PROJECT_ROOT/package.json" ]] && HAS_CODE=true ;;
  python) [[ -n "$(find "$PROJECT_ROOT" -name '*.py' -maxdepth 5 2>/dev/null | head -1)" ]] && HAS_CODE=true ;;
  *)      HAS_CODE=true ;;
esac

HAS_INTEGRATION=false
[[ -d "$PROJECT_ROOT/tests/integration" ]] || [[ -d "$PROJECT_ROOT/test/integration" ]] && HAS_INTEGRATION=true

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
  ((STEP_NUM++))

  if [[ -n "$ONLY_STEP" ]] && [[ "$name" != "$ONLY_STEP" ]]; then
    continue
  fi

  if should_skip "$skip_when"; then
    printf "⏭️  [%d] %-20s SKIP (%s)\n" "$STEP_NUM" "$name" "$skip_when"
    ((STEP_SKIP++))
    continue
  fi

  run="${run//\$\{SPEC_FILE\}/$SPEC_FILE}"
  run="${run//\$\{commands.build\}/$(manifest_get_cmd 'commands.build')}"
  run="${run//\$\{commands.lint\}/$(manifest_get_cmd 'commands.lint')}"
  run="${run//\$\{commands.test\}/$(manifest_get_cmd 'commands.test')}"
  run="${run//\$\{commands.integration_test\}/$(manifest_get_cmd 'commands.integration_test')}"

  printf "🔄 [%d] %-20s → %s\n" "$STEP_NUM" "$name" "$run"

  if output=$(run_cmd "$run" 2>&1); then
    [[ -n "$output" ]] && printf '%s\n' "$output" | tail -20
    printf "✅ [%d] %-20s PASS\n\n" "$STEP_NUM" "$name"
    ((STEP_PASS++))
  else
    printf '%s\n' "$output"
    printf "❌ [%d] %-20s FAIL\n\n" "$STEP_NUM" "$name"
    ((STEP_FAIL++))
    echo "⛔ Pipeline stopped at step $STEP_NUM: $name"
    break
  fi
done

echo ""
echo "══════════════════════════════════"
echo "📊 Pipeline: ✅ $STEP_PASS  ❌ $STEP_FAIL  ⏭️  $STEP_SKIP / $STEP_NUM total steps"

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
