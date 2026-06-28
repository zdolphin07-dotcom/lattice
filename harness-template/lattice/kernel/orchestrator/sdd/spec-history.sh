#!/usr/bin/env bash
# spec-history.sh — Aggregate spec transition events into a Markdown report.
source "$(dirname "$0")/../../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "spec history" "Aggregate spec transition JSON events into a Markdown report" \
    "spec-history.sh                                      Print history from lattice/state/spec-transitions" \
    "spec-history.sh --out=lattice/state/spec-history.md  Write Markdown report" \
    "spec-history.sh --dir=<dir> --limit=20               Use custom event directory"
done

EVENT_DIR="$PROJECT_ROOT/lattice/state/spec-transitions"
OUT=""
LIMIT=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir=*) EVENT_DIR="${1#--dir=}" ;;
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
      EVENT_DIR="$1"
      ;;
  esac
  shift
done

[[ "$EVENT_DIR" == /* ]] || EVENT_DIR="$PROJECT_ROOT/$EVENT_DIR"
[[ -d "$EVENT_DIR" ]] || { echo "Spec transition directory not found: $EVENT_DIR"; exit 1; }
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

declare -a EVENT_FILES=()
while IFS= read -r file; do
  if yq -e '.kind == "spec-transition" and .spec_id and .to_status and .changed_at' "$file" >/dev/null 2>&1; then
    EVENT_FILES+=("$file")
  fi
done < <(find "$EVENT_DIR" -maxdepth 1 -type f -name '*.json' -print 2>/dev/null | sort)

EVENT_TOTAL="${#EVENT_FILES[@]}"
FORCED_TOTAL=0
NOOP_TOTAL=0
ADVANCE_TOTAL=0
SPEC_LIST=""

for file in "${EVENT_FILES[@]}"; do
  spec_id="$(json_get "$file" '.spec_id')"
  [[ -n "$spec_id" ]] && SPEC_LIST+="$spec_id"$'\n'
  [[ "$(json_get "$file" '.force')" == "true" ]] && ((FORCED_TOTAL++)) || true
  case "$(json_get "$file" '.transition_type')" in
    noop) ((NOOP_TOTAL++)) || true ;;
    *) ((ADVANCE_TOTAL++)) || true ;;
  esac
done

SPEC_TOTAL=0
if [[ -n "$SPEC_LIST" ]]; then
  SPEC_TOTAL="$(printf '%s' "$SPEC_LIST" | sort -u | sed '/^$/d' | wc -l | tr -d ' ')"
fi

latest_event_for_spec() {
  local spec_id="$1" file latest=""
  for file in "${EVENT_FILES[@]}"; do
    if [[ "$(json_get "$file" '.spec_id')" == "$spec_id" ]]; then
      latest="$file"
    fi
  done
  printf '%s' "$latest"
}

first_changed_at_for_spec() {
  local spec_id="$1" file
  for file in "${EVENT_FILES[@]}"; do
    if [[ "$(json_get "$file" '.spec_id')" == "$spec_id" ]]; then
      json_get "$file" '.changed_at'
      return 0
    fi
  done
}

transition_count_for_spec() {
  local spec_id="$1" file total=0 forced=0
  for file in "${EVENT_FILES[@]}"; do
    if [[ "$(json_get "$file" '.spec_id')" == "$spec_id" ]]; then
      total=$((total + 1))
      [[ "$(json_get "$file" '.force')" == "true" ]] && forced=$((forced + 1))
    fi
  done
  printf '%s/%s' "$total" "$forced"
}

render_history() {
  echo "# Lattice Spec History"
  echo ""
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Specs | $SPEC_TOTAL |"
  echo "| Transition Events | $EVENT_TOTAL |"
  echo "| Advances | $ADVANCE_TOTAL |"
  echo "| Noops | $NOOP_TOTAL |"
  echo "| Forced | $FORCED_TOTAL |"
  echo ""

  echo "## Spec Summary"
  echo ""
  if [[ "$SPEC_TOTAL" -eq 0 ]]; then
    echo "_No spec transition events found._"
  else
    echo "| Spec | Current Status | Mode | First Changed | Last Changed | Events / Forced |"
    echo "|---|---|---|---|---|---|"
    while IFS= read -r spec_id; do
      [[ -n "$spec_id" ]] || continue
      latest="$(latest_event_for_spec "$spec_id")"
      current_status="$(json_get "$latest" '.to_status')"
      mode="$(json_get "$latest" '.execution_mode')"
      first_changed="$(first_changed_at_for_spec "$spec_id")"
      last_changed="$(json_get "$latest" '.changed_at')"
      counts="$(transition_count_for_spec "$spec_id")"
      echo "| $(md_escape "$spec_id") | $(md_escape "$current_status") | $(md_escape "$mode") | $(md_escape "$first_changed") | $(md_escape "$last_changed") | $(md_escape "$counts") |"
    done < <(printf '%s' "$SPEC_LIST" | sort -u | sed '/^$/d')
  fi

  echo ""
  echo "## Recent Transitions"
  echo ""
  if [[ "$EVENT_TOTAL" -eq 0 ]]; then
    echo "_No recent transitions._"
    return 0
  fi

  echo "| Changed At | Spec | From | To | Type | Mode | Force | Checks |"
  echo "|---|---|---|---|---|---|---|---|"
  local start_index=0
  if [[ "$EVENT_TOTAL" -gt "$LIMIT" ]]; then
    start_index=$((EVENT_TOTAL - LIMIT))
  fi
  local i file checks
  for ((i = EVENT_TOTAL - 1; i >= start_index; i--)); do
    file="${EVENT_FILES[$i]}"
    checks="plan=$(json_get "$file" '.checks.plan_lint'), task=$(json_get "$file" '.checks.task_evidence_lint'), state=$(json_get "$file" '.checks.spec_state_lint')"
    echo "| $(md_escape "$(json_get "$file" '.changed_at')") | $(md_escape "$(json_get "$file" '.spec_id')") | $(md_escape "$(json_get "$file" '.from_status')") | $(md_escape "$(json_get "$file" '.to_status')") | $(md_escape "$(json_get "$file" '.transition_type')") | $(md_escape "$(json_get "$file" '.execution_mode')") | $(md_escape "$(json_get "$file" '.force')") | $(md_escape "$checks") |"
  done
}

if [[ -n "$OUT" ]]; then
  mkdir -p "$(dirname "$OUT")"
  render_history > "$OUT"
  echo "Spec history: ${OUT#$PROJECT_ROOT/}"
else
  render_history
fi
