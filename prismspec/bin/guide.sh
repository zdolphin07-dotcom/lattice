#!/usr/bin/env bash
# guide.sh — PrismSpec workflow guide.
# Detects host mode, resolves spec artifacts, and prints the next stage.
set -euo pipefail

SPEC_ID=""
FROM_STAGE=""
MODE_OVERRIDE=""
JSON=false

usage() {
  cat <<'EOF'
PrismSpec guide

Usage:
  prismspec/bin/guide.sh [--spec=<id>] [--from=<stage>] [--mode=auto|plan|tdd] [--json]

Stages:
  brainstorm | plan | implement | verify | finish

Examples:
  bash prismspec/bin/guide.sh
  bash prismspec/bin/guide.sh --spec=checkout-flow
  bash prismspec/bin/guide.sh --spec=checkout-flow --from=verify
EOF
}

for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --spec=*) SPEC_ID="${arg#--spec=}" ;;
    spec=*) SPEC_ID="${arg#spec=}" ;;
    --from=*) FROM_STAGE="${arg#--from=}" ;;
    from=*) FROM_STAGE="${arg#from=}" ;;
    --mode=*) MODE_OVERRIDE="${arg#--mode=}" ;;
    mode=*) MODE_OVERRIDE="${arg#mode=}" ;;
    --json) JSON=true ;;
    *) echo "Unknown argument: $arg" >&2; usage; exit 1 ;;
  esac
done

case "$FROM_STAGE" in
  ""|brainstorm|plan|implement|verify|finish) ;;
  *) echo "Invalid --from stage: $FROM_STAGE" >&2; exit 1 ;;
esac

case "$MODE_OVERRIDE" in
  ""|auto|plan|tdd) ;;
  *) echo "Invalid --mode: $MODE_OVERRIDE" >&2; exit 1 ;;
esac

ROOT="$(pwd)"
HOST="standalone"
SPEC_ROOT="prismspec/specs"
RUN_ROOT=".prismspec/runs"
VERIFY_CMD="detect local build/lint/test commands"
TEMPLATE_ROOT="prismspec/templates"

if [[ -f "$ROOT/lattice/manifest.yaml" ]]; then
  HOST="lattice"
  SPEC_ROOT="lattice/specs"
  RUN_ROOT=".lattice/sdd"
  VERIFY_CMD="bash lattice/kernel/delivery/pipeline.sh"
  TEMPLATE_ROOT="prismspec/templates"
fi

active_from_manifest() {
  [[ "$HOST" == "lattice" ]] || return 1
  command -v yq >/dev/null 2>&1 || return 1
  local active
  active=$(yq -r '.specs.active // ""' lattice/manifest.yaml 2>/dev/null || true)
  [[ -n "$active" && "$active" != "null" ]] || return 1
  if [[ -f "$active" ]]; then
    dirname "$active" | sed "s#^$SPEC_ROOT/##"
    return 0
  fi
  if [[ -f "$SPEC_ROOT/$active/spec.md" ]]; then
    echo "$active"
    return 0
  fi
  return 1
}

latest_spec_id() {
  local latest
  latest=$(find "$SPEC_ROOT" -name spec.md -type f -not -path '*/.locks/*' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1 || true)
  [[ -n "$latest" ]] || return 1
  dirname "$latest" | sed "s#^$SPEC_ROOT/##"
}

if [[ -z "$SPEC_ID" ]]; then
  SPEC_ID="$(active_from_manifest || latest_spec_id || true)"
fi

SPEC_DIR=""
SPEC_FILE=""
CONTEXT_FILE=""
PLAN_FILE=""
VERIFY_FILE=""
SUMMARY_FILE=""
RUN_DIR=""

if [[ -n "$SPEC_ID" ]]; then
  SPEC_DIR="$SPEC_ROOT/$SPEC_ID"
  CONTEXT_FILE="$SPEC_DIR/context.md"
  SPEC_FILE="$SPEC_DIR/spec.md"
  PLAN_FILE="$SPEC_DIR/plan.md"
  VERIFY_FILE="$SPEC_DIR/verify.md"
  SUMMARY_FILE="$SPEC_DIR/summary.md"
  RUN_DIR="$RUN_ROOT/$SPEC_ID"
fi

extract_mode() {
  local file="$1"
  [[ -f "$file" ]] || { echo ""; return 0; }
  awk -F: '
    /^execution_mode:/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $2);
      gsub(/["'\''`]/, "", $2);
      print $2;
      exit;
    }
  ' "$file"
}

has_incomplete_tasks() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  grep -qE '^- \[ \] ' "$file"
}

has_verification_evidence() {
  [[ -n "$VERIFY_FILE" && -f "$VERIFY_FILE" ]] && return 0
  [[ -n "$SUMMARY_FILE" && -f "$SUMMARY_FILE" ]] && grep -qiE 'verification|pipeline|test|pass|fail' "$SUMMARY_FILE" && return 0
  [[ -n "$RUN_DIR" && -d "$RUN_DIR" ]] && find "$RUN_DIR" -type f \( -name 'verify.md' -o -name 'evidence.json' \) | grep -q .
}

stage_from_artifacts() {
  if [[ -n "$FROM_STAGE" ]]; then
    echo "$FROM_STAGE"
  elif [[ -z "$SPEC_ID" || ! -f "$SPEC_FILE" || ! -f "$CONTEXT_FILE" ]]; then
    echo "brainstorm"
  elif [[ ! -f "$PLAN_FILE" ]]; then
    echo "plan"
  elif has_incomplete_tasks "$PLAN_FILE"; then
    echo "implement"
  elif ! has_verification_evidence; then
    echo "verify"
  elif [[ ! -f "$SUMMARY_FILE" ]]; then
    echo "finish"
  else
    echo "done"
  fi
}

MODE="${MODE_OVERRIDE:-}"
[[ -n "$MODE" ]] || MODE="$(extract_mode "${SPEC_FILE:-}")"
[[ -n "$MODE" ]] || MODE="auto"
STAGE="$(stage_from_artifacts)"

template_hint() {
  case "$MODE:$STAGE" in
    tdd:*) echo "$TEMPLATE_ROOT/spec-template-tdd.md" ;;
    *) echo "$TEMPLATE_ROOT/spec-template.md" ;;
  esac
}

context_template_hint() {
  echo "$TEMPLATE_ROOT/context-template.md"
}

skill_for_stage() {
  case "$1" in
    brainstorm) echo "prismspec/skills/brainstorm/SKILL.md" ;;
    plan) echo "prismspec/skills/plan/SKILL.md" ;;
    implement) echo "prismspec/skills/implement/SKILL.md" ;;
    verify) echo "prismspec/skills/verify/SKILL.md" ;;
    finish) echo "prismspec/skills/finish/SKILL.md" ;;
    done) echo "" ;;
  esac
}

next_action() {
  case "$STAGE" in
    brainstorm) echo "Run brainstorming and write context.md + spec.md" ;;
    plan) echo "Read spec.md and write AC-traced plan.md" ;;
    implement) echo "Execute plan.md using $MODE mode" ;;
    verify) echo "Run verification: $VERIFY_CMD" ;;
    finish) echo "Write summary.md and capture durable lessons" ;;
    done) echo "Workflow complete; report status or start a new spec" ;;
  esac
}

if [[ "$JSON" == "true" ]]; then
  printf '{\n'
  printf '  "host": "%s",\n' "$HOST"
  printf '  "spec_id": "%s",\n' "$SPEC_ID"
  printf '  "stage": "%s",\n' "$STAGE"
  printf '  "mode": "%s",\n' "$MODE"
  printf '  "skill": "%s",\n' "$(skill_for_stage "$STAGE")"
  printf '  "spec_dir": "%s",\n' "$SPEC_DIR"
  printf '  "context_file": "%s",\n' "$CONTEXT_FILE"
  printf '  "run_dir": "%s",\n' "$RUN_DIR"
  printf '  "template_hint": "%s",\n' "$(template_hint)"
  printf '  "context_template_hint": "%s",\n' "$(context_template_hint)"
  printf '  "verify_command": "%s"\n' "$VERIFY_CMD"
  printf '}\n'
  exit 0
fi

echo "PrismSpec Guide"
echo ""
echo "Host:        $HOST"
echo "Spec id:     ${SPEC_ID:-<new>}"
echo "Stage:       $STAGE"
echo "Mode:        $MODE"
echo "Skill:       $(skill_for_stage "$STAGE")"
echo "Spec dir:    ${SPEC_DIR:-$SPEC_ROOT/<spec-id>}"
echo "Context:     ${CONTEXT_FILE:-$SPEC_ROOT/<spec-id>/context.md}"
echo "Evidence:    ${RUN_DIR:-$RUN_ROOT/<spec-id>}"
echo "Template:    $(template_hint)"
echo "Context tpl: $(context_template_hint)"
echo ""
echo "Next action: $(next_action)"
