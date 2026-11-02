#!/usr/bin/env bash
# scripts/install.sh — Installer for Mandor dan Tukang (Orca Dual-Engine Architecture)
set -euo pipefail

INSTALL_BIN_DIR="${HOME}/.local/bin"
SKILLS_DIR="${HOME}/.agents/skills/mandordantukang"

mkdir -p "$INSTALL_BIN_DIR"
mkdir -p "$SKILLS_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🪐 [mandordantukang] Installing tools to $INSTALL_BIN_DIR..."
cp "$SCRIPT_DIR/orca-bridge.sh" "$INSTALL_BIN_DIR/orca-bridge"
cp "$SCRIPT_DIR/orca-pair.sh" "$INSTALL_BIN_DIR/orca-pair"
chmod +x "$INSTALL_BIN_DIR/orca-bridge" "$INSTALL_BIN_DIR/orca-pair"

echo "📦 [mandordantukang] Installing skill to $SKILLS_DIR..."
cp -r "$ROOT_DIR/"* "$SKILLS_DIR/" 2>/dev/null || true

echo "✅ [mandordantukang] Installation complete!"
echo "• Run 'orca-pair [project_dir]' to start a dual-agent session in Orca IDE."
echo "• Pane 1: Mandor (Claude Opus / Sonnet)"
echo "• Pane 2: Tukang Kerja (Gemini Flash / Haiku)"
