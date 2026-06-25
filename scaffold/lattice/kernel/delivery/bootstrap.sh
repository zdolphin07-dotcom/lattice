#!/usr/bin/env bash
# bootstrap.sh — L0 environment readiness check and service startup
# Reads manifest.yaml; hardcodes nothing project-specific.
#
# Usage:
#   bootstrap.sh check   — Check toolchain readiness
#   bootstrap.sh local   — Start local services
#   bootstrap.sh test    — Verify remote test environment connectivity
#
# Exit codes: 0=ready, 1=missing dependencies
set -euo pipefail

source "$(dirname "$0")/../_lib.sh"

for arg in "$@"; do
  [[ "$arg" == "--help" || "$arg" == "-h" ]] && cli_help "delivery bootstrap" "Environment dependency check and local service startup" \
    "bootstrap.sh check   Check toolchain readiness" \
    "bootstrap.sh local   Start local dependency services" \
    "bootstrap.sh test    Verify test environment connectivity"
done

MODE="${1:?Usage: bootstrap.sh <check|local|test>}"

check_tools() {
  echo "🔧 Required tools"
  echo ""

  local count
  count=$(yq '.tools.required | length' "$MANIFEST")
  for i in $(seq 0 $((count - 1))); do
    local name check_cmd
    name=$(yq -r ".tools.required[$i].name" "$MANIFEST")
    check_cmd=$(yq -r ".tools.required[$i].check // \"\"" "$MANIFEST")
    [[ -z "$name" || "$name" == "null" ]] && continue

    if [[ -z "$check_cmd" ]]; then
      warn "$name — no check command"
      continue
    fi
    if version=$(run_cmd "$check_cmd" 2>/dev/null | head -1); then
      pass "$name — $version"
    else
      fail "$name — not installed"
    fi
  done

  echo ""
  echo "🔧 Optional tools"
  echo ""

  count=$(yq '.tools.optional | length // 0' "$MANIFEST" 2>/dev/null || echo 0)
  for i in $(seq 0 $((count - 1))); do
    local name check_cmd
    name=$(yq -r ".tools.optional[$i].name" "$MANIFEST")
    check_cmd=$(yq -r ".tools.optional[$i].check // \"\"" "$MANIFEST")
    [[ -z "$name" || "$name" == "null" ]] && continue
    [[ -z "$check_cmd" ]] && continue

    if version=$(run_cmd "$check_cmd" 2>/dev/null | head -1); then
      pass "$name — $version"
    else
      skip "$name — not installed (optional)"
    fi
  done
}

operate_services() {
  local env="$1"
  echo ""
  echo "🔌 Services ($env)"
  echo ""

  local count
  count=$(yq ".services.${env} | length // 0" "$MANIFEST" 2>/dev/null || echo 0)
  for i in $(seq 0 $((count - 1))); do
    local svc health_cmd start_cmd
    svc=$(yq -r ".services.${env}[$i].name" "$MANIFEST")
    health_cmd=$(yq -r ".services.${env}[$i].health // \"\"" "$MANIFEST")
    start_cmd=$(yq -r ".services.${env}[$i].start // \"\"" "$MANIFEST")
    [[ -z "$svc" || "$svc" == "null" ]] && continue

    if [[ -z "$health_cmd" ]]; then
      skip "$svc — no $env config"
      continue
    fi

    if run_cmd "$health_cmd" &>/dev/null; then
      pass "$svc — ready"
      continue
    fi

    if [[ "$env" == "local" ]] && [[ -n "$start_cmd" ]]; then
      echo "  → Starting $svc..."
      run_cmd "$start_cmd" 2>/dev/null || true
      sleep 3

      if run_cmd "$health_cmd" &>/dev/null; then
        pass "$svc — started"

        local post_count
        post_count=$(yq ".services.${env}[$i].post_start | length // 0" "$MANIFEST" 2>/dev/null || echo 0)
        for j in $(seq 0 $((post_count - 1))); do
          local cmd
          cmd=$(yq -r ".services.${env}[$i].post_start[$j]" "$MANIFEST")
          [[ -z "$cmd" || "$cmd" == "null" ]] && continue
          if run_cmd "$cmd" &>/dev/null; then
            pass "$svc — post_start complete"
          else
            warn "$svc — post_start failed: $cmd"
          fi
        done
      else
        fail "$svc — failed to start"
      fi
    else
      fail "$svc — $env environment unreachable"
    fi
  done
}

LANG_NAME=$(get_language)
PROJECT_NAME=$(manifest_get ".project.name")

echo "══════════════════════════════════"
echo "Lattice — Bootstrap ($MODE)"
echo "Project: $PROJECT_NAME ($LANG_NAME)"
echo "══════════════════════════════════"
echo ""

case "$MODE" in
  check)
    check_tools
    ;;
  local)
    check_tools
    operate_services local
    ;;
  test)
    check_tools
    operate_services test
    ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Usage: bootstrap.sh <check|local|test>"
    exit 1
    ;;
esac

print_summary "Bootstrap"
