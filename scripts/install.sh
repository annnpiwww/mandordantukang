#!/usr/bin/env bash
# scripts/install.sh — Installer for Mandor dan Tukang (Orca Dual-Engine Architecture)
# Usage: scripts/install.sh [--force] | --uninstall
#   --force      overwrite skill files you customized (a backup is kept)
#   --uninstall  remove installed binaries/lib (restores the newest backup of each binary)
set -Eeuo pipefail

INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-${HOME}/.local/bin}"
SKILLS_DIR="${SKILLS_DIR:-${HOME}/.agents/skills/mandordantukang}"
SHARE_DIR="${SHARE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mandordantukang}"
MARKER="mandordantukang"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
NEW_VERSION="$(cat "$ROOT_DIR/VERSION")"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$SHARE_DIR/backups/$TS"

mode=install force=0
for a in "$@"; do
  case "$a" in
    --force) force=1 ;;
    --uninstall) mode=uninstall ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

say() { echo "🪐 [mandordantukang] $*"; }
sum_of() { cksum < "$1" | cut -d' ' -f1; }

# ---------- uninstall ----------
if [[ "$mode" == uninstall ]]; then
  for b in orca-bridge orca-pair; do
    dest="$INSTALL_BIN_DIR/$b"
    if [[ -f "$dest" && ! -L "$dest" ]] && grep -q "$MARKER" "$dest"; then
      rm -f "$dest"; say "removed $dest"
      last="$(ls -1d "$SHARE_DIR"/backups/*/bin/"$b" 2>/dev/null | sort | tail -n 1 || true)"
      if [[ -n "$last" ]]; then cp -P "$last" "$dest"; say "restored previous $b from $last"; fi
    else
      say "skip $dest (not installed by $MARKER)"
    fi
  done
  rm -f "$SHARE_DIR/mandor-lib.js" "$SHARE_DIR/VERSION" "$SHARE_DIR/manifest.tsv"
  say "uninstalled. Kept: $SKILLS_DIR (your skill files), $SHARE_DIR/backups, task state in ~/.local/state/mandordantukang"
  exit 0
fi

# ---------- dependency checks ----------
missing=()
for c in git node cksum; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
[[ ${#missing[@]} -eq 0 ]] || { echo "❌ missing dependencies: ${missing[*]}" >&2; exit 1; }
node -e 'process.exit(+process.versions.node.split(".")[0] >= 16 ? 0 : 1)' || { echo "❌ node >= 16 required" >&2; exit 1; }
command -v orca >/dev/null 2>&1 || echo "⚠️  'orca' CLI not on PATH: orca-bridge/orca-pair need Orca IDE at runtime." >&2
command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1 || echo "⚠️  no timeout(1): verify commands will run without a time limit." >&2

old_version="$(cat "$SHARE_DIR/VERSION" 2>/dev/null || echo none)"
say "installing v$NEW_VERSION (installed: $old_version)"

# ---------- stage + validate before touching anything ----------
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp "$SCRIPT_DIR/orca-bridge.sh" "$STAGE/orca-bridge"
cp "$SCRIPT_DIR/orca-pair.sh" "$STAGE/orca-pair"
cp "$SCRIPT_DIR/mandor-lib.js" "$STAGE/mandor-lib.js"
bash -n "$STAGE/orca-bridge" && bash -n "$STAGE/orca-pair" && node --check "$STAGE/mandor-lib.js" \
  || { echo "❌ staged files failed syntax check; nothing installed" >&2; exit 1; }

# ---------- transactional install with rollback ----------
DONE_DESTS=()   # "dest<TAB>backup-or-empty"
rollback() {
  local entry dest bak
  echo "❌ install failed; rolling back" >&2
  for entry in ${DONE_DESTS[@]+"${DONE_DESTS[@]}"}; do
    dest="${entry%%$'\t'*}"; bak="${entry#*$'\t'}"
    rm -f "$dest"
    [[ -n "$bak" ]] && cp -P "$bak" "$dest"
  done
  rm -rf "$STAGE"
}
trap 'rollback' ERR

# place <src> <dest> <backup-subpath>: back up whatever is at dest (a symlink is kept as a symlink,
# never followed, so a linked copy elsewhere is not overwritten), then install a regular file.
place() {
  local src="$1" dest="$2" bak=""
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ ! -L "$dest" ]] && cmp -s "$src" "$dest"; then return 0; fi
    bak="$BACKUP_DIR/$3"; mkdir -p "$(dirname "$bak")"; cp -P "$dest" "$bak"
    rm -f "$dest"
  fi
  DONE_DESTS+=("$dest"$'\t'"$bak")
  cp "$src" "$dest"
}

mkdir -p "$INSTALL_BIN_DIR" "$SHARE_DIR"
say "installing tools to $INSTALL_BIN_DIR..."
place "$STAGE/orca-bridge" "$INSTALL_BIN_DIR/orca-bridge" bin/orca-bridge
place "$STAGE/orca-pair" "$INSTALL_BIN_DIR/orca-pair" bin/orca-pair
chmod +x "$INSTALL_BIN_DIR/orca-bridge" "$INSTALL_BIN_DIR/orca-pair"
place "$STAGE/mandor-lib.js" "$SHARE_DIR/mandor-lib.js" share/mandor-lib.js

# Skill files: overwrite only files we installed and the user has not edited since (manifest),
# unless --force. Edited files get the new version alongside as <file>.new.
MANIFEST="$SHARE_DIR/manifest.tsv"
NEW_MANIFEST="$STAGE/manifest.tsv"; : > "$NEW_MANIFEST"
if [[ "$ROOT_DIR" == "$(cd "$SKILLS_DIR" 2>/dev/null && pwd -P || true)" ]]; then
  say "repo is the skill dir ($SKILLS_DIR); skill files already in place"
else
  say "installing skill to $SKILLS_DIR..."
  while IFS= read -r rel; do
    src="$ROOT_DIR/$rel"; dest="$SKILLS_DIR/$rel"
    [[ -f "$src" ]] || continue
    printf '%s\t%s\n' "$rel" "$(sum_of "$src")" >> "$NEW_MANIFEST"
    if [[ -f "$dest" ]] && ! cmp -s "$src" "$dest"; then
      prev="$(awk -F'\t' -v k="$rel" '$1==k {print $2}' "$MANIFEST" 2>/dev/null || true)"
      if [[ "$force" != 1 && "$prev" != "$(sum_of "$dest")" ]]; then
        mkdir -p "$(dirname "$dest")"; cp "$src" "$dest.new"
        echo "⚠️  kept your edited $dest; new version saved as $dest.new (--force to overwrite)" >&2
        continue
      fi
    fi
    place "$src" "$dest" "skill/$rel"
  done < <(cd "$ROOT_DIR" && { git ls-files --cached --others --exclude-standard 2>/dev/null || find . -type f ! -path './.git/*' | sed 's|^\./||'; })
  cp "$NEW_MANIFEST" "$MANIFEST"
fi
cp "$ROOT_DIR/VERSION" "$SHARE_DIR/VERSION"

# ---------- post-install validation ----------
got="$("$INSTALL_BIN_DIR/orca-bridge" version)"
[[ "$got" == "orca-bridge $NEW_VERSION" ]] || { echo "❌ validation failed: '$got'" >&2; false; }
trap - ERR

say "✅ installed v$NEW_VERSION$([[ -d "$BACKUP_DIR" ]] && echo " (backups: $BACKUP_DIR)" || true)"
case ":$PATH:" in *":$INSTALL_BIN_DIR:"*) ;; *) echo "⚠️  $INSTALL_BIN_DIR is not on PATH" >&2 ;; esac
echo "• Run 'orca-pair [project_dir]' to start a dual-agent session in Orca IDE."
echo "• Pane 1: Mandor (Claude Opus / Sonnet)"
echo "• Pane 2: Tukang Kerja (Gemini Flash / Haiku)"
echo "• Uninstall: $SCRIPT_DIR/install.sh --uninstall"
