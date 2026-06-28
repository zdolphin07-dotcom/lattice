#!/usr/bin/env bash
# failure-category-lint.sh — Validate failure category configuration.
source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "failure category lint" "Validate failure category config" \
    "failure-category-lint.sh                         Validate configured file" \
    "failure-category-lint.sh <file>                  Validate a specific file"
done

CONFIG_FILE="${1:-}"
if [[ -z "$CONFIG_FILE" ]]; then
  CONFIG_FILE="$(manifest_get '.pipeline.failure_categories_file')"
  [[ -n "$CONFIG_FILE" ]] || CONFIG_FILE="lattice/config/failure-categories.yaml"
fi
[[ "$CONFIG_FILE" == /* ]] || CONFIG_FILE="$PROJECT_ROOT/$CONFIG_FILE"

echo "🔍 Failure Category Lint: ${CONFIG_FILE#$PROJECT_ROOT/}"
echo ""

valid_slug() {
  [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

valid_rule_name() {
  [[ "$1" =~ ^[a-z][a-z0-9_-]*$ ]]
}

valid_regex() {
  local regex="$1"
  grep -Eq "$regex" </dev/null >/dev/null 2>&1
  local code=$?
  [[ "$code" -ne 2 ]]
}

if [[ ! -f "$CONFIG_FILE" ]]; then
  fail "Config file not found: ${CONFIG_FILE#$PROJECT_ROOT/}"
  print_summary "Failure Category Lint"
  exit $?
fi

if yq eval '.' "$CONFIG_FILE" >/dev/null 2>&1; then
  pass "YAML parse"
else
  fail "YAML parse failed"
  print_summary "Failure Category Lint"
  exit $?
fi

SCHEMA_VERSION="$(yq -r '.schema_version // ""' "$CONFIG_FILE")"
if [[ "$SCHEMA_VERSION" == "lattice.failure-categories.v1" ]]; then
  pass "schema_version"
else
  fail "schema_version must be lattice.failure-categories.v1"
fi

DEFAULT_CATEGORY="$(yq -r '.default.category // ""' "$CONFIG_FILE")"
DEFAULT_ACTION="$(yq -r '.default.default_action // ""' "$CONFIG_FILE")"
if valid_slug "$DEFAULT_CATEGORY"; then
  pass "default.category"
else
  fail "default.category must be a lowercase slug"
fi
if valid_slug "$DEFAULT_ACTION"; then
  pass "default.default_action"
else
  fail "default.default_action must be a lowercase slug"
fi

RULE_COUNT="$(yq -r '(.rules // []) | length' "$CONFIG_FILE" 2>/dev/null || echo 0)"
if [[ "$RULE_COUNT" =~ ^[0-9]+$ ]] && [[ "$RULE_COUNT" -gt 0 ]]; then
  pass "rules: $RULE_COUNT"
else
  fail "rules must contain at least one rule"
  RULE_COUNT=0
fi

if [[ "$RULE_COUNT" -gt 0 ]]; then
  for i in $(seq 0 $((RULE_COUNT - 1))); do
    name="$(yq -r ".rules[$i].name // \"\"" "$CONFIG_FILE")"
    step="$(yq -r ".rules[$i].step // \"\"" "$CONFIG_FILE")"
    step_regex="$(yq -r ".rules[$i].step_regex // \"\"" "$CONFIG_FILE")"
    output_regex="$(yq -r ".rules[$i].output_regex // \"\"" "$CONFIG_FILE")"
    category="$(yq -r ".rules[$i].category // \"\"" "$CONFIG_FILE")"
    action="$(yq -r ".rules[$i].default_action // \"\"" "$CONFIG_FILE")"
    label="rules[$i]${name:+ $name}"

    if valid_rule_name "$name"; then
      pass "$label name"
    else
      fail "$label name must be lowercase kebab-case or snake_case"
    fi

    if [[ -n "$step" || -n "$step_regex" || -n "$output_regex" ]]; then
      pass "$label matcher"
    else
      fail "$label must define step, step_regex, or output_regex"
    fi

    if [[ -n "$step_regex" ]]; then
      if valid_regex "$step_regex"; then
        pass "$label step_regex"
      else
        fail "$label step_regex is invalid"
      fi
    fi

    if [[ -n "$output_regex" ]]; then
      if valid_regex "$output_regex"; then
        pass "$label output_regex"
      else
        fail "$label output_regex is invalid"
      fi
    fi

    if valid_slug "$category"; then
      pass "$label category"
    else
      fail "$label category must be a lowercase slug"
    fi

    if valid_slug "$action"; then
      pass "$label default_action"
    else
      fail "$label default_action must be a lowercase slug"
    fi
  done
fi

print_summary "Failure Category Lint"
