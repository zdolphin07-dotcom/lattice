#!/usr/bin/env bash
# install.sh — One-command install Lattice into a project
#
# Usage:
#   Remote install:
#     bash <(curl -fsSL https://raw.githubusercontent.com/zdolphin07-dotcom/lattice/main/install.sh)
#
#   Local install:
#     ./install.sh                     # Install to current directory
#     ./install.sh /path/to/project    # Install to specific project
#
#   Options:
#     --init       Auto-run init.sh after install (detect + harness-template + manifest)
#     --upgrade    Refresh framework source and upgrade project kernel
#
set -euo pipefail

REPO_URL="${LATTICE_REPO:-https://github.com/zdolphin07-dotcom/lattice.git}"
TARGET=""
AUTO_INIT=false
FORCE_UPGRADE=false

for arg in "$@"; do
  case "$arg" in
    --init)    AUTO_INIT=true ;;
    --upgrade) FORCE_UPGRADE=true ;;
    -*)        echo "Unknown option: $arg"; exit 1 ;;
    *)         TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-.}"
if [ ! -d "$TARGET" ]; then
  echo "Target directory does not exist: $TARGET"
  exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"
DEST="$TARGET/.lattice/framework"
PROJECT_ALREADY_INITIALIZED=false
if [ -f "$TARGET/lattice/manifest.yaml" ]; then
  PROJECT_ALREADY_INITIALIZED=true
fi

upgrade_project_kernel() {
  local src_kernel="$DEST/harness-template/lattice/kernel"
  local target_root="$TARGET/lattice"
  local target_kernel="$target_root/kernel"

  if [ ! -d "$src_kernel" ]; then
    echo "Cannot find kernel source: $src_kernel"
    exit 1
  fi

  if [ ! -f "$target_root/manifest.yaml" ]; then
    echo "ℹ️  Project is not initialized yet; skipping kernel upgrade"
    echo "   Run with --init or execute: (cd $TARGET && bash $DEST/init.sh)"
    return
  fi

  echo ""
  echo "🔄 Upgrading project kernel → $target_kernel"

  if [ -d "$target_kernel" ]; then
    local backup_dir
    backup_dir="$target_root/state/kernel-backups/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$target_kernel" "$backup_dir/kernel"
    echo "  Backup: $backup_dir/kernel"
  fi

  mkdir -p "$target_root"
  cp -R "$src_kernel" "$target_kernel"
  chmod +x "$target_kernel"/_lib.sh "$target_kernel"/context/*.sh "$target_kernel"/context/backends/*.sh "$target_kernel"/delivery/*.sh "$target_kernel"/delivery/gates/*.sh 2>/dev/null || true
  echo "✅ Kernel upgraded"
}

upgrade_project_prismspec() {
  local src_module="$DEST/prismspec"
  local target_module="$TARGET/prismspec"

  if [ ! -d "$src_module" ]; then
    echo "ℹ️  PrismSpec source not found; skipping PrismSpec upgrade"
    return
  fi

  echo ""
  echo "🔄 Upgrading PrismSpec module → $target_module"

  if [ -d "$target_module/skills" ] || [ -d "$target_module/templates" ] || [ -d "$target_module/bin" ] || [ -d "$target_module/references" ] || [ -d "$target_module/agents" ] || [ -d "$target_module/commands" ]; then
    local backup_dir
    backup_dir="$TARGET/lattice/state/prismspec-backups/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    [ -d "$target_module/skills" ] && mv "$target_module/skills" "$backup_dir/skills"
    [ -d "$target_module/templates" ] && mv "$target_module/templates" "$backup_dir/templates"
    [ -d "$target_module/bin" ] && mv "$target_module/bin" "$backup_dir/bin"
    [ -d "$target_module/references" ] && mv "$target_module/references" "$backup_dir/references"
    [ -d "$target_module/agents" ] && mv "$target_module/agents" "$backup_dir/agents"
    [ -d "$target_module/commands" ] && mv "$target_module/commands" "$backup_dir/commands"
    echo "  Backup: $backup_dir"
  fi

  mkdir -p "$target_module"
  cp -R "$src_module/skills" "$target_module/skills"
  cp -R "$src_module/templates" "$target_module/templates"
  cp -R "$src_module/bin" "$target_module/bin"
  [ -d "$src_module/references" ] && cp -R "$src_module/references" "$target_module/references"
  [ -d "$src_module/agents" ] && cp -R "$src_module/agents" "$target_module/agents"
  [ -d "$src_module/commands" ] && cp -R "$src_module/commands" "$target_module/commands"
  cp "$src_module/README.md" "$target_module/README.md"
  [ -f "$src_module/README.en.md" ] && cp "$src_module/README.en.md" "$target_module/README.en.md"
  chmod +x "$target_module"/bin/*.sh 2>/dev/null || true
  echo "✅ PrismSpec upgraded"
}

if [ -d "$DEST" ]; then
  if [ "$FORCE_UPGRADE" = true ]; then
    echo "🔄 Upgrade mode: removing old version at $DEST"
    rm -rf "$DEST"
  else
    echo "⚠️  Already installed: $DEST"
    echo "   To upgrade, add --upgrade flag, or set LATTICE_REPO=<url> to override repo"
    exit 0
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$SCRIPT_DIR/harness-template" ]; then
  echo "📦 Local install Lattice → $DEST"
  mkdir -p "$DEST"
  cp -r "$SCRIPT_DIR"/. "$DEST"/
  rm -rf "$DEST/.git"
else
  echo "📦 Remote install Lattice → $DEST"
  echo "   Repo: $REPO_URL"
  mkdir -p "$(dirname "$DEST")"
  git clone --depth=1 "$REPO_URL" "$DEST" 2>/dev/null || {
    echo "Clone failed. Check the repo URL and SSH/HTTPS permissions."
    echo "   Repo: $REPO_URL"
    echo "   Override with LATTICE_REPO=<url>"
    exit 1
  }
  rm -rf "$DEST/.git"
fi

echo ""
echo "✅ Installation complete: $DEST"

if [ "$AUTO_INIT" = true ]; then
  echo ""
  echo "🚀 Running init..."
  (cd "$TARGET" && bash "$DEST/init.sh")
  if [ "$FORCE_UPGRADE" = true ] && [ "$PROJECT_ALREADY_INITIALIZED" = true ]; then
    upgrade_project_kernel
    upgrade_project_prismspec
  fi
elif [ "$FORCE_UPGRADE" = true ]; then
  upgrade_project_kernel
  upgrade_project_prismspec
else
  echo ""
  echo "Next steps:"
  echo "  Option 1 (recommended): Tell your AI agent 'lattice init'"
  echo "  Option 2: cd $TARGET && bash $DEST/init.sh"
fi
