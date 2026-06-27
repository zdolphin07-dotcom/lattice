#!/usr/bin/env bash
# _lib.sh — Lattice shared library
# Sourced by all kernel scripts; not executed directly.
#
# Provides:
#   - Project path resolution (KERNEL_DIR / PROJECT_ROOT / MANIFEST)
#   - Manifest YAML queries (via yq)
#   - Layer enable/disable detection (layer_enabled)
#   - Unified output formatting (pass/fail/warn/skip)
#   - Command execution (run_cmd)

set -euo pipefail

# ── Locate project root and manifest ──
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_find_project_root() {
  local dir="$_LIB_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/manifest.yaml" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo ""
}

_SH_DIR="$(_find_project_root)"
if [[ -z "$_SH_DIR" ]]; then
  _SH_DIR="$(cd "$_LIB_DIR/.." && pwd)"
fi

PROJECT_ROOT="$(cd "$_SH_DIR/.." && pwd)"
MANIFEST="$_SH_DIR/manifest.yaml"
KERNEL_DIR="$_SH_DIR/kernel"

[[ -f "$MANIFEST" ]] || { echo "manifest.yaml not found: $MANIFEST"; exit 1; }

# ── yq check ──
if ! command -v yq &>/dev/null; then
  echo "Missing required tool: yq"
  echo "  Install: brew install yq  |  apt install yq  |  go install github.com/mikefarah/yq/v4@latest"
  exit 1
fi

# ══════════════════════════════════
# Layer management
# ══════════════════════════════════

layer_enabled() {
  local layer="$1"
  local manifest_val
  manifest_val=$(yq -r ".kernel.layers.${layer} // \"auto\"" "$MANIFEST" 2>/dev/null || echo "auto")

  case "$manifest_val" in
    true)  return 0 ;;
    false) return 1 ;;
    auto|"")
      [[ -d "$KERNEL_DIR/$layer" ]] && return 0 || return 1
      ;;
  esac
}

require_layer() {
  local layer="$1"
  if ! layer_enabled "$layer"; then
    echo "Layer '$layer' is not enabled. Set kernel.layers.$layer: true in manifest.yaml"
    exit 1
  fi
}

# ══════════════════════════════════
# Counters + output helpers
# ══════════════════════════════════

_PASS=0; _FAIL=0; _WARN=0; _SKIP=0

pass() { ((_PASS++)) || true; printf "  ✅ %s\n" "$*"; }
fail() { ((_FAIL++)) || true; printf "  ❌ %s\n" "$*"; }
warn() { ((_WARN++)) || true; printf "  ⚠️  %s\n" "$*"; }
skip() { ((_SKIP++)) || true; printf "  ⏭️  %s\n" "$*"; }

# ══════════════════════════════════
# YAML queries (yq wrapper)
# ══════════════════════════════════

manifest_get() {
  local expr="$1"
  local result
  result=$(yq -r "$expr // \"\"" "$MANIFEST")
  [[ "$result" != "null" ]] && echo "$result" || echo ""
}

manifest_get_cmd() {
  local key="$1"
  [[ "$key" != .* ]] && key=".$key"
  manifest_get "$key"
}

manifest_list() {
  local expr="$1"
  yq -r "$expr // empty" "$MANIFEST" 2>/dev/null || true
}

manifest_select() {
  local array_path="$1" name="$2" field="$3"
  yq -r "${array_path}[] | select(.name == \"${name}\") | .${field} // \"\"" "$MANIFEST" 2>/dev/null || true
}

get_language() {
  manifest_get ".project.language"
}

# ══════════════════════════════════
# Command execution
# ══════════════════════════════════

# Security model: manifest.yaml is trusted project configuration (equivalent to source code).
# run_cmd executes commands in a subprocess for output capture, not for sandboxing.
run_cmd() {
  local cmd="$1"
  bash -c "$cmd"
}

# ══════════════════════════════════
# Spec discovery
# ══════════════════════════════════

find_spec() {
  local spec_dir
  spec_dir=$(manifest_get ".specs.dir")
  spec_dir="${spec_dir:-lattice/specs}"
  local spec_file="${SPEC_FILE:-}"
  local active_spec
  active_spec=$(manifest_get ".specs.active")

  if [[ -n "$spec_file" ]] && [[ -f "$spec_file" ]]; then
    echo "$spec_file"
    return 0
  fi

  if [[ -n "$active_spec" ]]; then
    if [[ -f "$PROJECT_ROOT/$active_spec" ]]; then
      echo "$PROJECT_ROOT/$active_spec"
      return 0
    fi
    if [[ -f "$PROJECT_ROOT/$spec_dir/$active_spec/spec.md" ]]; then
      echo "$PROJECT_ROOT/$spec_dir/$active_spec/spec.md"
      return 0
    fi
  fi

  if [[ -d "$PROJECT_ROOT/$spec_dir" ]]; then
    local latest
    latest=$(find "$PROJECT_ROOT/$spec_dir" -name 'spec.md' -type f -not -path '*/.locks/*' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
    if [[ -n "$latest" ]]; then
      echo "$latest"
      return 0
    fi

    latest=$(find "$PROJECT_ROOT/$spec_dir" -name '*.md' -type f -not -path '*/.locks/*' -not -name 'plan.md' -not -name 'summary.md' -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
    if [[ -n "$latest" ]]; then
      echo "$latest"
      return 0
    fi
  fi

  return 1
}

# ══════════════════════════════════
# CLI help
# ══════════════════════════════════

cli_help() {
  local name="$1" desc="$2"
  shift 2
  echo "lattice $name — $desc"
  echo ""
  echo "Usage:"
  for line in "$@"; do
    echo "  $line"
  done
  echo ""
  echo "Exit codes:"
  echo "  0  Success"
  echo "  1  Failure"
  exit 0
}

print_summary() {
  local label="${1:-Summary}"
  echo ""
  echo "══════════════════════════════════"
  echo "📊 $label: ✅ $_PASS  ❌ $_FAIL  ⚠️  $_WARN  ⏭️  $_SKIP"

  if [[ $_FAIL -gt 0 ]]; then
    echo "❌ FAIL"
    return 1
  else
    echo "✅ PASS"
    return 0
  fi
}
