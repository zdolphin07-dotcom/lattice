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
chmod +x lattice/kernel/*.sh lattice/kernel/context/*.sh lattice/kernel/context/backends/*.sh lattice/kernel/delivery/*.sh lattice/kernel/delivery/gates/*.sh prismspec/bin/*.sh 2>/dev/null || true

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

echo "── 6. Pipeline Eval JSON ──"
bash lattice/kernel/delivery/pipeline.sh --only=ac-coverage --spec="$SPEC" --json-out=lattice/state/eval-runs/example.json
yq '.metrics, .gates[0].metrics' lattice/state/eval-runs/example.json
echo ""

echo "── 7. Eval Markdown Summary ──"
bash lattice/kernel/delivery/eval-summary.sh lattice/state/eval-runs/example.json --out=lattice/state/eval-runs/example.md
sed -n '1,32p' lattice/state/eval-runs/example.md
echo ""

echo "══════════════════════════════════"
echo "✅ All gates demonstrated"
