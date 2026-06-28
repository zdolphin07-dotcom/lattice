#!/usr/bin/env bash
# lint.sh — PrismSpec artifact lint.
# Validates the minimum contract for spec.md, plan.md, and evidence files.
set -euo pipefail

TARGET="${1:-}"
CHECK="${2:-all}"

usage() {
  cat <<'EOF'
PrismSpec lint

Usage:
  bash prismspec/bin/lint.sh <spec-dir|spec.md> [all|spec|plan|evidence]

Checks:
  spec      spec.md has ACs, execution mode, risk, and verification plan
  plan      plan.md references AC ids and includes verification
  evidence  verify.md or summary.md records commands/results
  all       run all available checks
EOF
}

if [[ -z "$TARGET" || "$TARGET" == "--help" || "$TARGET" == "-h" ]]; then
  usage
  [[ -z "$TARGET" ]] && exit 1 || exit 0
fi

case "$CHECK" in
  all|spec|plan|evidence) ;;
  *) echo "Invalid check: $CHECK" >&2; usage; exit 1 ;;
esac

if [[ -d "$TARGET" ]]; then
  SPEC_DIR="${TARGET%/}"
  SPEC_FILE="$SPEC_DIR/spec.md"
elif [[ -f "$TARGET" ]]; then
  SPEC_FILE="$TARGET"
  SPEC_DIR="$(dirname "$TARGET")"
else
  echo "Target not found: $TARGET" >&2
  exit 1
fi

PLAN_FILE="$SPEC_DIR/plan.md"
VERIFY_FILE="$SPEC_DIR/verify.md"
SUMMARY_FILE="$SPEC_DIR/summary.md"
FAIL=0

ok() { printf "PASS %s\n" "$*"; }
bad() { printf "FAIL %s\n" "$*" >&2; FAIL=1; }

contains_heading() {
  local file="$1" pattern="$2"
  grep -qiE "^#{1,3}[[:space:]]+.*($pattern)" "$file"
}

check_spec() {
  [[ -f "$SPEC_FILE" ]] || { bad "spec.md missing: $SPEC_FILE"; return; }

  grep -qE 'AC-[0-9]+' "$SPEC_FILE" || bad "spec.md has no AC-{n} acceptance criteria"
  grep -qiE 'execution[_ -]?mode|Mode:[[:space:]]*`?(plan|tdd)|mode:[[:space:]]*`?(plan|tdd)' "$SPEC_FILE" || bad "spec.md has no execution mode"
  grep -qiE '\b(plan|tdd)\b' "$SPEC_FILE" || bad "spec.md execution mode must be plan or tdd"
  contains_heading "$SPEC_FILE" 'Intent|Objective|Goal|Background' || bad "spec.md missing intent/objective section"
  contains_heading "$SPEC_FILE" 'Scope' || bad "spec.md missing scope section"
  contains_heading "$SPEC_FILE" 'Risk|风险' || bad "spec.md missing risk section"
  contains_heading "$SPEC_FILE" 'Verification|Test Strategy|验证|测试' || bad "spec.md missing verification/test section"

  if [[ $FAIL -eq 0 ]]; then ok "spec contract"; fi
}

check_plan() {
  [[ -f "$PLAN_FILE" ]] || { bad "plan.md missing: $PLAN_FILE"; return; }

  grep -qE 'AC-[0-9]+' "$PLAN_FILE" || bad "plan.md has no AC references"
  grep -qiE 'verify|verification|test|lint|build|验证|测试' "$PLAN_FILE" || bad "plan.md has no verification steps"
  grep -qE '(^|[[:space:]])(T[0-9]+|RED-[0-9]+)[:.) -]' "$PLAN_FILE" || bad "plan.md has no stable task ids"

  if grep -qiE 'execution[_ -]?mode:[[:space:]]*tdd|Mode:[[:space:]]*`?tdd' "$SPEC_FILE" 2>/dev/null; then
    grep -qE 'RED-[0-9]+|red test|failing test|红灯|失败测试' "$PLAN_FILE" || bad "tdd spec requires red-test tasks in plan.md"
  fi

  if [[ $FAIL -eq 0 ]]; then ok "plan contract"; fi
}

check_evidence() {
  if [[ -f "$VERIFY_FILE" ]]; then
    grep -qiE 'command|exit|pass|fail|pipeline|test|build|lint|命令|通过|失败' "$VERIFY_FILE" || bad "verify.md lacks command/result evidence"
  elif [[ -f "$SUMMARY_FILE" ]]; then
    grep -qiE 'verification|command|pass|fail|pipeline|test|build|lint|验证|通过|失败' "$SUMMARY_FILE" || bad "summary.md lacks verification evidence"
  else
    bad "verification evidence missing: verify.md or summary.md"
  fi

  if [[ $FAIL -eq 0 ]]; then ok "evidence contract"; fi
}

case "$CHECK" in
  spec) check_spec ;;
  plan) check_plan ;;
  evidence) check_evidence ;;
  all)
    check_spec
    check_plan
    check_evidence
    ;;
esac

exit "$FAIL"
