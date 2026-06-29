#!/usr/bin/env bash
# release-check.sh — Maintainer release readiness checks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE_INSTALL_URL="${LATTICE_REMOTE_INSTALL_URL:-https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh}"

cd "$ROOT"

section() {
  printf '\n-- %s --\n' "$1"
}

section "Bash syntax"
shell_scripts=()
while IFS= read -r script; do
  shell_scripts+=("$script")
done < <(find harness-template prismspec/bin -name '*.sh')
bash -n init.sh install.sh tests/smoke-test.sh tests/release-check.sh "${shell_scripts[@]}"

section "PrismSpec skillpack"
bash prismspec/bin/lint.sh prismspec skillpack

section "Smoke test"
bash tests/smoke-test.sh

section "Runnable example"
bash examples/go-gin-gorm/try-it.sh

section "Whitespace"
git diff --check

if [[ "${LATTICE_CHECK_REMOTE_INSTALL:-0}" == "1" ]]; then
  section "Remote install URL"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$REMOTE_INSTALL_URL" -o "$tmp/install.sh"
  mkdir -p "$tmp/target"
  (
    cd "$tmp/target"
    bash "$tmp/install.sh" --init
    bash lattice/kernel/doctor.sh
    bash prismspec/bin/doctor.sh
    bash prismspec/bin/guide.sh --json >/dev/null
  )
else
  section "Remote install URL"
  echo "Skipped. Set LATTICE_CHECK_REMOTE_INSTALL=1 for public release verification."
fi

section "Release check complete"
