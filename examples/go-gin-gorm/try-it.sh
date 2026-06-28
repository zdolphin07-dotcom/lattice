#!/usr/bin/env bash
# try-it.sh — Run Lattice gates on this example project
# Usage: bash examples/go-gin-gorm/try-it.sh  (from repo root)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

for tool in yq git; do
  command -v "$tool" &>/dev/null || { echo "Requires $tool"; exit 1; }
done

SANDBOX=$(mktemp -d)
trap "rm -rf $SANDBOX" EXIT

echo "══════════════════════════════════"
echo "Lattice — Go Example Demo"
echo "Sandbox: $SANDBOX"
echo "══════════════════════════════════"
echo ""

# Set up: copy example + install harness
cp -r "$SCRIPT_DIR"/. "$SANDBOX"/
cd "$SANDBOX"
git init --quiet

# Copy framework pieces used by this standalone demo.
cp -r "$REPO_DIR/harness-template/lattice/kernel" "$SANDBOX/lattice/kernel"
cp -r "$REPO_DIR/prismspec" "$SANDBOX/prismspec"

SPEC="lattice/specs/create-item-api/spec.md"

echo "── 1. Spec Lint ──"
bash lattice/kernel/delivery/gates/spec-lint.sh "$SPEC"
echo ""

echo "── 2. PrismSpec Lint ──"
bash prismspec/bin/lint.sh "$(dirname "$SPEC")" spec
echo ""

echo "── 3. AC Coverage ──"
bash lattice/kernel/delivery/gates/ac-coverage.sh "$SPEC" .
echo ""

echo "── 4. Drift Check ──"
bash lattice/kernel/delivery/gates/drift-check.sh "$SPEC" .
echo ""

echo "── 5. Context Knowledge Backend ──"
bash lattice/kernel/context/backends/knowledge.sh naming
echo ""

echo "══════════════════════════════════"
echo "✅ All gates demonstrated"
