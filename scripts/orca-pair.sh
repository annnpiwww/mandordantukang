#!/usr/bin/env bash
# orca-pair — Spawn & Attach Orca Dual-Engine Multi-Agent Pair (Claude Opus + Gemini Antigravity)
# Usage: orca-pair [project_dir]

set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "🪐 [orca-pair] Initializing Dual-Engine Multi-Agent in: $TARGET_DIR"

# 1. Pastikan Orca runtime reachable
if ! orca status --json >/dev/null 2>&1; then
  echo "⚡ Orca runtime belum aktif, mencoba membuka Orca..."
  orca open 2>/dev/null || true
  sleep 2
fi

# 2. Bootstrap AGENTS.md, GEMINI.md, & CLAUDE.md jika belum ada
if [[ ! -f "$TARGET_DIR/AGENTS.md" ]]; then
  echo "📄 Generating template AGENTS.md di $TARGET_DIR..."
  proj_name=$(basename "$TARGET_DIR")
  cat << EOF > "$TARGET_DIR/AGENTS.md"
# $proj_name - Project Guidelines & Dual-Engine Architecture

## Orca Dual-Engine Architecture (OMP + Antigravity)
Platform pengembangan menggunakan 2 engine terkoordinasi di dalam Orca IDE:
1. **OMP / Claude (Pane 1 / Mandor)**:
   - **Claude Opus 5.5 High — ARSITEK & STRATEGIST (PRAGMATIC TOKEN-SAVER)**:
     - **Quick Fix Direct**: Task kecil (≤ 15 baris, typo, CSS/regex quickfix, bug sepele): **langsung edit sendiri**. Dilarang delegasi ke Antigravity untuk task sepele karena menulis instruksi delegasi panjang jauh lebih boros token daripada 1 tool call edit!
     - **Delegasikan ke Antigravity (Pane 2)** hanya untuk task berat: fitur baru multi-file, migrasi DB besar, test runner (\`npm test\` / test suite), dan visual browser testing.
     - **Strict Anti-Ronde-Loop (Max 1 Pass Gate)**: Jika test lolos semua (green): **WAJIB LANGSUNG APPROVE & SELESAI**. Dilarang buka ronde 2/3/fix2 untuk nitpick kosmetik sepele!
     - **DUAL-PERSONA OUTPUT & ANTI-ESSAY**:
       - *Ke User*: Bahasa gaul Gen-Z ultra-singkat (\`caveman ultra\` / bahasa bayi singkat padat jelas), maksimal 3-4 bullet points pendek (< 50 kata). DILARANG nulis esai naratif review ("Yang sudah saya cek sendiri", dsb).
       - *Ke Antigravity (Gemini)*: Full detail teknis terstruktur via \`orca-bridge delegate\` (target files, logic detail, edge cases, test command) biar eksekusi presisi.
     - **Tooling Discipline**: Gunakan \`semantex --refs\`, \`xerj def\`, \`xerj search\`, \`serena\`, \`mgrep\`. Zero-grep policy.
2. **Antigravity CLI (Agy / Gemini 3.8 Flash High) (Pane 2 / Tukang Kerja)**:
   - **Primary Heavy Executor**: Eksekusi seluruh task koding besar, multi-file edits, migrasi & seeding database, eksekusi test (\`npm test\`), dan browser audit via \`orca-bridge browser\`.
   - Dilarang dump Base64 screenshot ke stdout terminal (gunakan \`orca-bridge browser screenshot <path>\`).
   - Selesai test pass, laporkan: \`orca-bridge report DONE "<commit_hash>, <test_pass_count>"\`.
3. **Komunikasi Antar Pane via Orca Bridge (\`orca-bridge\`)**:
   - \`orca-bridge delegate <title> <instruksi>\` (Opus -> Agy)
   - \`orca-bridge report DONE <summary>\` (Agy -> Opus)
   - \`orca-bridge status\`

## SKILLS & TOOLING WAJIB (ALWAYS-ON)
1. **caveman ultra**: Output ultra-ringkas, max 3-4 bullets (< 50 kata).
2. **ponytail full**: The Ladder (YAGNI ekstrem -> reuse util -> stdlib -> native -> deps existing -> 1 baris -> minimal diff).
3. **rtk**: Prefix wajib untuk semua perintah terminal (\`rtk <cmd>\`).
4. **xerj & serena**: \`xerj def\` & \`xerj search\` untuk navigasi cepat; Serena MCP untuk LSP symbol navigation & safe AST edits.
5. **semantex & gitnexus**: \`semantex --refs\` untuk semantic concept search; \`gitnexus context\` & \`gitnexus impact\` untuk call flow & blast radius.
6. **humanizer-indonesia**: Bahasa Indonesia alami, bebas pola kaku AI.
7. **anti-slop suite**: Anti generic AI pattern pada UI, visual styling, copy, dan code comments.

## 7-POINT SECURITY CORE (OWASP MANDATORY GUARDS)
1. **Input Validation**: Validasi tipe, format, dan batasan semua input sebelum diproses.
2. **Zero Trust Output**: Jangan ekspos internal DB error / stack trace ke client.
3. **Credential Hygiene**: DILARANG hardcode API key / secret. Selalu gunakan \`.env\`.
4. **Injection Prevention**: Parameterized query untuk SQL (\`?\`), escape teks user sebelum render ke DOM/HTML (\`esc()\`), dan sanitasi path traversal (\`..\`).
5. **Least Privilege**: Validasi role & permission di backend endpoint.
6. **Data Privacy**: Password wajib di-hash (bcrypt/argon2). Jangan log data sensitif ke terminal.
7. **Dependency Security**: Utamakan package stabil dan teruji. Hindari library tak terverifikasi.

## Orca Embedded Browser Audit Protocol
- Gunakan \`orca-bridge browser <snapshot|screenshot|errors|network|goto>\` untuk verifikasi visual UI dan audit error console.
EOF
fi

if [[ ! -e "$TARGET_DIR/GEMINI.md" ]]; then
  echo "🔗 Symlinking GEMINI.md -> AGENTS.md..."
  ln -sf AGENTS.md "$TARGET_DIR/GEMINI.md"
fi
if [[ ! -e "$TARGET_DIR/CLAUDE.md" ]]; then
  echo "🔗 Symlinking CLAUDE.md -> AGENTS.md..."
  ln -sf AGENTS.md "$TARGET_DIR/CLAUDE.md"
fi

# 3. Setup local helper scripts/orca-bridge.sh
mkdir -p "$TARGET_DIR/scripts"
if [[ ! -e "$TARGET_DIR/scripts/orca-bridge.sh" ]]; then
  local_bridge="$(command -v orca-bridge || echo "${HOME}/.local/bin/orca-bridge")"
  echo "🔗 Linking scripts/orca-bridge.sh -> $local_bridge..."
  ln -sf "$local_bridge" "$TARGET_DIR/scripts/orca-bridge.sh"
fi

# 4. Auto-index Code Intelligence & Dual Knowledge Graph in background
if command -v gitnexus >/dev/null 2>&1 && [[ ! -d "$TARGET_DIR/.gitnexus" ]]; then
  echo "⚡ [gitnexus] Indexing project architecture graph in background..."
  (cd "$TARGET_DIR" && gitnexus analyze . --index-only >/dev/null 2>&1 &) || true
fi

if command -v semantex >/dev/null 2>&1 && [[ ! -d "$TARGET_DIR/.semantex" ]]; then
  echo "⚡ [semantex] Building hybrid semantic index in background..."
  (cd "$TARGET_DIR" && semantex index . >/dev/null 2>&1 &) || true
fi

proj_prefix=$(basename "$TARGET_DIR" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
if command -v xerj >/dev/null 2>&1 && curl -s http://localhost:9200 >/dev/null 2>&1; then
  echo "⚡ [xerj] Autoindexing project codebase ($proj_prefix) in background..."
  (xerj autoindex "$TARGET_DIR" --prefix "$proj_prefix" --yes >/dev/null 2>&1 &) || true
fi

if command -v codegraph >/dev/null 2>&1 && [[ ! -d "$TARGET_DIR/.codegraph" ]]; then
  echo "⚡ [codegraph] Initializing codegraph in background..."
  (cd "$TARGET_DIR" && codegraph init >/dev/null 2>&1 &) || true
fi

if command -v graphify >/dev/null 2>&1 && [[ ! -d "$TARGET_DIR/graphify-out" ]]; then
  echo "⚡ [graphify] Extracting macro architecture graph in background..."
  (cd "$TARGET_DIR" && graphify extract . --code-only && graphify cluster-only . && graphify export html >/dev/null 2>&1 &) || true
fi

# 5. Cek terminal yang aktif di Orca untuk target directory secara spesifik
term_json=$(orca terminal list --json 2>/dev/null || echo '{"result":{"terminals":[]}}')

has_omp=$(node -e '
  const targetDir = process.argv[2];
  const data = JSON.parse(process.argv[1]);
  const terms = (data.result?.terminals || []).filter(t => t.worktreePath && (t.worktreePath === targetDir || targetDir.startsWith(t.worktreePath + "/")));
  const found = terms.some(t => t.title && /omp|(^|\s)pi(\s|$)|claude/i.test(t.title));
  process.stdout.write(found ? "yes" : "no");
' "$term_json" "$TARGET_DIR")

has_agy=$(node -e '
  const targetDir = process.argv[2];
  const data = JSON.parse(process.argv[1]);
  const terms = (data.result?.terminals || []).filter(t => t.worktreePath && (t.worktreePath === targetDir || targetDir.startsWith(t.worktreePath + "/")));
  const found = terms.some(t => t.title && /antigravity|(^|[\s:])agy(\s|$)|gemini/i.test(t.title));
  process.stdout.write(found ? "yes" : "no");
' "$term_json" "$TARGET_DIR")

# 6. Spawn terminal jika belum ada di worktree ini
if [[ "$has_omp" != "yes" ]]; then
  echo "🚀 Membuka Pane 1: OMP / Claude Opus 5.5 (Mandor)..."
  orca terminal create --worktree "path:$TARGET_DIR" --title "OMP ready" --command "omp" --json >/dev/null
  sleep 1
else
  echo "✅ Pane 1 (OMP / Claude) sudah terdeteksi di worktree ini."
fi

if [[ "$has_agy" != "yes" ]]; then
  echo "🚀 Membuka Pane 2: Antigravity / Gemini 3.8 (Worker)..."
  orca terminal create --worktree "path:$TARGET_DIR" --title "Antigravity Worker" --command "agy" --json >/dev/null
  sleep 1
else
  echo "✅ Pane 2 (Antigravity / Gemini) sudah terdeteksi di worktree ini."
fi

# 7. Tampilkan status bridge terkini
echo ""
(cd "$TARGET_DIR" && "${HOME}/.local/bin/orca-bridge" status)
echo ""
echo "✨ Orca Dual-Engine Pair aktif & sepaket di $TARGET_DIR!"
echo "• Claude Opus 5.5 = Mandor / Arsitek (Task kecil ≤ 15 baris langsung edit, task besar delegasi ke Agy)"
echo "• Gemini 3.8 Agy  = Tukang Kerja (Eksekusi koding, test runner, browser audit)"
echo "• Gunakan 'orca-bridge delegate <title> <instruksi>' untuk mulai delegasi."
