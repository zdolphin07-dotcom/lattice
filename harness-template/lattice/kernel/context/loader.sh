#!/usr/bin/env bash
# loader.sh — Compatibility wrapper for the context knowledge backend.
#
# Prefer reading lattice/context/README.md for Context Discovery. This script is
# only a deterministic helper for searching curated project knowledge.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "ℹ️  loader.sh is a compatibility wrapper."
echo "   For Context Discovery, read lattice/context/README.md first."
echo "   Delegating to backends/knowledge.sh..."
echo ""

exec "$SCRIPT_DIR/backends/knowledge.sh" "$@"
