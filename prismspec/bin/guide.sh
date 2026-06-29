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
  specification | planning | implementation | review | verification

Legacy stage aliases:
  brainstorm -> specification
  plan       -> planning
  implement  -> implementation
  verify     -> verification
  finish     -> verification

Examples:
  bash prismspec/bin/guide.sh
  bash prismspec/bin/guide.sh --spec=checkout-flow
  bash prismspec/bin/guide.sh --spec=checkout-flow --from=verification
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

normalize_stage() {
  case "$1" in
    "" ) echo "" ;;
    spec|specification|brainstorm) echo "specification" ;;
    plan|planning) echo "planning" ;;
    implement|implementation) echo "implementation" ;;
    review) echo "review" ;;
    verify|verification|finish) echo "verification" ;;
    done) echo "done" ;;
    *) return 1 ;;
  esac
}

if [[ -n "$FROM_STAGE" ]]; then
  FROM_STAGE="$(normalize_stage "$FROM_STAGE")" || {
    echo "Invalid --from stage: $FROM_STAGE" >&2
    exit 1
  }
fi

case "$FROM_STAGE" in
  ""|specification|planning|implementation|review|verification|done) ;;
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

extract_status() {
  local file="$1"
  [[ -f "$file" ]] || { echo ""; return 0; }
  awk '
    /^status:/ {
      value = substr($0, index($0, ":") + 1);
      gsub(/^[ \t]+|[ \t]+$/, "", value);
      gsub(/["'\''`]/, "", value);
      print value;
      exit;
    }
  ' "$file"
}

extract_scaffolded() {
  local file="$1"
  [[ -f "$file" ]] || { echo "false"; return 0; }
  awk '
    /^scaffolded:/ {
      value = substr($0, index($0, ":") + 1);
      gsub(/^[ \t]+|[ \t]+$/, "", value);
      gsub(/["'\''`]/, "", value);
      print tolower(value);
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

has_review_evidence() {
  [[ -n "$RUN_DIR" && -f "$RUN_DIR/branch/review-summary.json" ]] && return 0
  [[ -n "$RUN_DIR" && -f "$RUN_DIR/review-summary.json" ]] && return 0
  [[ -n "$RUN_DIR" && -d "$RUN_DIR" ]] && find "$RUN_DIR" -type f \( -name 'review-summary.json' -o -name 'review-summary.md' \) | grep -q .
}

stage_from_artifacts() {
  if [[ -n "$FROM_STAGE" ]]; then
    echo "$FROM_STAGE"
  elif [[ -z "$SPEC_ID" || ! -f "$SPEC_FILE" || ! -f "$CONTEXT_FILE" ]]; then
    echo "specification"
  elif [[ "$SCAFFOLDED" == "true" ]]; then
    echo "specification"
  elif [[ ! -f "$PLAN_FILE" ]]; then
    echo "planning"
  elif has_incomplete_tasks "$PLAN_FILE"; then
    echo "implementation"
  elif ! has_review_evidence; then
    echo "review"
  elif ! has_verification_evidence; then
    echo "verification"
  else
    echo "done"
  fi
}

route_reason_from_artifacts() {
  if [[ -n "$FROM_STAGE" ]]; then
    echo "from_override"
  elif [[ -z "$SPEC_ID" ]]; then
    echo "no_spec"
  elif [[ ! -f "$SPEC_FILE" || ! -f "$CONTEXT_FILE" ]]; then
    echo "missing_specification_artifacts"
  elif [[ "$SCAFFOLDED" == "true" ]]; then
    echo "scaffolded_spec"
  elif [[ ! -f "$PLAN_FILE" ]]; then
    echo "missing_plan"
  elif has_incomplete_tasks "$PLAN_FILE"; then
    echo "incomplete_plan"
  elif ! has_review_evidence; then
    echo "missing_review_evidence"
  elif ! has_verification_evidence; then
    echo "missing_verification_evidence"
  else
    echo "complete"
  fi
}

MODE="${MODE_OVERRIDE:-}"
[[ -n "$MODE" ]] || MODE="$(extract_mode "${SPEC_FILE:-}")"
[[ -n "$MODE" ]] || MODE="auto"
STATUS="$(extract_status "${SPEC_FILE:-}")"
[[ -n "$STATUS" ]] || STATUS="none"
SCAFFOLDED="$(extract_scaffolded "${SPEC_FILE:-}")"
[[ -n "$SCAFFOLDED" ]] || SCAFFOLDED="false"
[[ "$SCAFFOLDED" == "true" ]] || SCAFFOLDED="false"
STAGE="$(stage_from_artifacts)"
ROUTE_REASON="$(route_reason_from_artifacts)"

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
    specification) echo "prismspec/skills/brainstorm/SKILL.md" ;;
    planning) echo "prismspec/skills/plan/SKILL.md" ;;
    implementation) echo "prismspec/skills/implement/SKILL.md" ;;
    review) echo "prismspec/skills/review/SKILL.md" ;;
    verification) echo "prismspec/skills/verify/SKILL.md" ;;
    done) echo "" ;;
  esac
}

next_action() {
  case "$STAGE" in
    specification)
      if [[ "$SCAFFOLDED" == "true" ]]; then
        echo "Fill scaffolded context.md/spec.md, then set scaffolded: false"
      else
        echo "Run specification and write context.md + spec.md"
      fi
      ;;
    planning) echo "Read spec.md and write AC-traced plan.md" ;;
    implementation) echo "Execute plan.md using $MODE mode" ;;
    review) echo "Review task evidence and write review-summary.json" ;;
    verification) echo "Run verification: $VERIFY_CMD" ;;
    done) echo "Workflow complete; report status or start a new spec" ;;
  esac
}

command_hint() {
  local id="${SPEC_ID:-<spec-id>}"
  case "$STAGE" in
    specification)
      if [[ "$SCAFFOLDED" == "true" ]]; then
        echo "edit $CONTEXT_FILE $SPEC_FILE"
      elif [[ -n "$SPEC_ID" && ( ! -f "$SPEC_FILE" || ! -f "$CONTEXT_FILE" ) ]]; then
        echo "bash prismspec/bin/new.sh $id --template=default --mode=$MODE"
      else
        echo "bash prismspec/bin/new.sh <spec-id> --template=default --mode=$MODE"
      fi
      ;;
    planning) echo "read $(skill_for_stage "$STAGE") and write $PLAN_FILE" ;;
    implementation) echo "read $(skill_for_stage "$STAGE") and execute $PLAN_FILE" ;;
    review) echo "read $(skill_for_stage "$STAGE") and write $RUN_DIR/branch/review-summary.json" ;;
    verification) echo "$VERIFY_CMD" ;;
    done) echo "bash prismspec/bin/guide.sh --spec=$id --json" ;;
  esac
}

missing_artifacts_json() {
  local first=true

  add_item() {
    local item="$1"
    if [[ "$first" == "true" ]]; then
      first=false
    else
      printf ', '
    fi
    printf '"%s"' "$item"
  }

  printf '['
  if [[ -n "$SPEC_ID" ]]; then
    [[ -f "$CONTEXT_FILE" ]] || add_item "$CONTEXT_FILE"
    [[ -f "$SPEC_FILE" ]] || add_item "$SPEC_FILE"
    if [[ "$STAGE" != "specification" ]]; then
      [[ -f "$PLAN_FILE" ]] || add_item "$PLAN_FILE"
    fi
    if [[ "$STAGE" == "review" ]]; then
      [[ -d "$RUN_DIR" ]] || add_item "$RUN_DIR"
    fi
  fi
  printf ']'
}

if [[ "$JSON" == "true" ]]; then
  printf '{\n'
  printf '  "host": "%s",\n' "$HOST"
  printf '  "spec_id": "%s",\n' "$SPEC_ID"
  printf '  "status": "%s",\n' "$STATUS"
  printf '  "scaffolded": %s,\n' "$SCAFFOLDED"
  printf '  "stage": "%s",\n' "$STAGE"
  printf '  "route_reason": "%s",\n' "$ROUTE_REASON"
  printf '  "next_action": "%s",\n' "$(next_action)"
  printf '  "command_hint": "%s",\n' "$(command_hint)"
  printf '  "missing_artifacts": %s,\n' "$(missing_artifacts_json)"
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
echo "Status:      $STATUS"
echo "Scaffolded:  $SCAFFOLDED"
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
