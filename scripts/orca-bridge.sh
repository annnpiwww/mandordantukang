#!/usr/bin/env bash
# scripts/orca-bridge.sh — Inter-Agent Relay & Cross-Platform Orchestration Bridge
# Architecture: Claude Opus 5.5 (OTAK / Mandor) <--> Gemini 3.8 Flash High (Antigravity / Tukang Kerja) in Orca IDE

set -euo pipefail

function get_terminals_json() {
  local json
  json=$(orca terminal list --json 2>/dev/null || true)
  if [[ -z "$json" ]]; then
    echo "Error: cannot reach Orca runtime. Is Orca open?" >&2
    exit 1
  fi
  echo "$json"
}

function get_worktree_path() {
  local json
  json=$(get_terminals_json)
  node -e '
    const data = JSON.parse(process.argv[1]);
    const cwd = process.cwd();
    const terminals = data.result?.terminals || [];
    let match = terminals.find(t => t.worktreePath && (cwd === t.worktreePath || cwd.startsWith(t.worktreePath + "/")));
    const p = match ? match.worktreePath : (terminals[0]?.worktreePath || cwd);
    process.stdout.write(p);
  ' "$json"
}

function get_handle() {
  local target="$1"
  local json
  json=$(get_terminals_json)

  if [[ "$target" == "omp" || "$target" == "claude" || "$target" == "otak" ]]; then
    node -e '
      const data = JSON.parse(process.argv[1]);
      const cwd = process.cwd();
      const terminals = data.result?.terminals || [];
      let localTerms = terminals.filter(t => t.worktreePath && (cwd === t.worktreePath || cwd.startsWith(t.worktreePath + "/")));
      let pool = localTerms.length > 0 ? localTerms : terminals;
      let term = pool.find(t => t.title && /omp|(^|\s)pi(\s|$)|claude/i.test(t.title));
      if (!term && pool[0]) {
        const vl = data.result?.visualLayouts?.find(v => v.worktreePath && (cwd === v.worktreePath || cwd.startsWith(v.worktreePath + "/")));
        if (vl?.root?.first?.tabs?.[0]?.panes?.handle) {
          term = terminals.find(t => t.handle === vl.root.first.tabs[0].panes.handle);
        } else if (vl?.root?.tabs?.[0]?.panes?.first?.handle) {
          term = terminals.find(t => t.handle === vl.root.tabs[0].panes.first.handle);
        }
      }
      if (!term) term = pool.find(t => t.title && /omp|claude|pi/i.test(t.title));
      if (!term && pool.length > 0) term = pool[0];
      if (term) process.stdout.write(term.handle);
    ' "$json"
  elif [[ "$target" == "agy" || "$target" == "antigravity" || "$target" == "gemini" || "$target" == "worker" ]]; then
    node -e '
      const data = JSON.parse(process.argv[1]);
      const cwd = process.cwd();
      const terminals = data.result?.terminals || [];
      let localTerms = terminals.filter(t => t.worktreePath && (cwd === t.worktreePath || cwd.startsWith(t.worktreePath + "/")));
      let pool = localTerms.length > 0 ? localTerms : terminals;
      let term = pool.find(t => t.title && /antigravity|(^|[\s:])agy(\s|$)|gemini/i.test(t.title));
      if (!term && pool[0]) {
        const vl = data.result?.visualLayouts?.find(v => v.worktreePath && (cwd === v.worktreePath || cwd.startsWith(v.worktreePath + "/")));
        if (vl?.root?.second?.tabs?.[0]?.panes?.handle) {
          term = terminals.find(t => t.handle === vl.root.second.tabs[0].panes.handle);
        } else if (vl?.root?.tabs?.[0]?.panes?.second?.handle) {
          term = terminals.find(t => t.handle === vl.root.tabs[0].panes.second.handle);
        }
      }
      if (!term) term = pool.find(t => t.title && /agy|antigravity|gemini/i.test(t.title));
      if (!term && pool.length > 1) term = pool[1];
      if (term) process.stdout.write(term.handle);
    ' "$json"
  else
    echo "Unknown target: $target. Use 'omp' or 'agy'." >&2
    exit 1
  fi
}

command="${1:-status}"

case "$command" in
  # 1. CORE RELAY: Send message
  send)
    target="${2:-}"
    shift 2 || true
    message="$*"
    if [[ -z "$target" || -z "$message" ]]; then
      echo "Usage: orca-bridge send <omp|agy> <message>" >&2
      exit 1
    fi
    handle=$(get_handle "$target")
    if [[ -z "$handle" ]]; then
      echo "Target terminal '$target' not found in Orca!" >&2
      exit 1
    fi
    echo "[orca-bridge] Sending to $target ($handle)..."
    orca terminal send --terminal "$handle" --text "$message" --enter --json >/dev/null
    if [[ "$target" == "agy" || "$target" == "antigravity" || "$target" == "gemini" || "$target" == "worker" ]]; then
      sleep 0.15
      orca terminal send --terminal "$handle" --text "$(printf '\033m')" --json >/dev/null 2>&1 || true
    fi
    echo "[orca-bridge] Sent successfully!"
    ;;

  # 2. CORE RELAY: Read terminal
  read)
    target="${2:-}"
    limit="${3:-40}"
    if [[ -z "$target" ]]; then
      echo "Usage: orca-bridge read <omp|agy> [lines]" >&2
      exit 1
    fi
    handle=$(get_handle "$target")
    if [[ -z "$handle" ]]; then
      echo "Target terminal '$target' not found in Orca!" >&2
      exit 1
    fi
    orca terminal read --terminal "$handle" --limit "$limit" 2>/dev/null || orca terminal show --terminal "$handle"
    ;;

  # 3. CORE RELAY: Wait for idle
  wait)
    target="${2:-}"
    timeout_ms="${3:-60000}"
    if [[ -z "$target" ]]; then
      echo "Usage: orca-bridge wait <omp|agy> [timeout_ms]" >&2
      exit 1
    fi
    handle=$(get_handle "$target")
    echo "[orca-bridge] Waiting for $target ($handle) to become idle (timeout: ${timeout_ms}ms)..."
    orca terminal wait --terminal "$handle" --for tui-idle --timeout-ms "$timeout_ms" --json 2>/dev/null || true
    echo "[orca-bridge] $target is ready / idle!"
    ;;

  # 4. DELEGATE TASK: Mandor (Opus) -> Worker (Antigravity)
  delegate)
    shift || true
    title="${1:-}"
    shift || true
    details="$*"
    if [[ -z "$title" ]]; then
      echo "Usage: orca-bridge delegate <task_title> [detailed instructions...]" >&2
      exit 1
    fi
    formatted="[TASK DARI MANDOR (Opus 5.5)]
📌 Title: $title
📋 Detail & Instruksi:
$details

⚡ Catatan Eksekusi:
- Kerjakan langsung di codebase (hands-on).
- Verifikasi dengan 'npm test' dan cek console 0 error.
- Laporkan balik jika sudah selesai dengan 'orca-bridge report DONE ...'."
    handle=$(get_handle "agy")
    echo "[orca-bridge] Delegating task '$title' to Antigravity ($handle)..."
    orca terminal send --terminal "$handle" --text "$formatted" --enter --json >/dev/null
    sleep 0.15
    orca terminal send --terminal "$handle" --text "$(printf '\033m')" --json >/dev/null 2>&1 || true
    echo "[orca-bridge] Task delegated successfully!"
    ;;

  # 5. REPORT TASK: Worker (Antigravity) -> Mandor (Opus / Reviewer)
  report)
    shift || true
    status="${1:-DONE}"
    shift || true
    summary="$*"
    if [[ -z "$summary" ]]; then
      echo "Usage: orca-bridge report <DONE|NEEDS_REVISION|BLOCKED> <summary...>" >&2
      exit 1
    fi
    formatted="[@OTAK & Reviewer] Laporan Hasil Eksekusi Antigravity:
Status : $status
Rincian:
$summary

Silakan review git diff / jalankan gate approval."
    handle=$(get_handle "omp")
    echo "[orca-bridge] Sending report to OTAK/Opus ($handle)..."
    orca terminal send --terminal "$handle" --text "$formatted" --enter --json >/dev/null
    echo "[orca-bridge] Report sent to OTAK!"
    ;;

  # 6. BROWSER INSPECTION: Shared Orca Browser
  browser)
    subcmd="${2:-snapshot}"
    wt=$(get_worktree_path)
    wt_arg=()
    if [[ -n "$wt" ]]; then
      wt_arg=(--worktree "path:$wt")
    fi

    case "$subcmd" in
      snapshot)
        echo "[orca-bridge] Taking accessibility DOM tree snapshot in $wt..."
        orca snapshot "${wt_arg[@]}"
        ;;
      screenshot)
        out="${3:-/tmp/orca-screenshot.png}"
        mkdir -p "$(dirname "$out")"
        echo "[orca-bridge] Capturing screenshot to $out..."
        orca screenshot "${wt_arg[@]}" --json 2>/dev/null | node -e '
          let buf = "";
          process.stdin.on("data", c => buf += c);
          process.stdin.on("end", () => {
            try {
              const d = JSON.parse(buf);
              if (d.result?.data) {
                const b = Buffer.from(d.result.data, "base64");
                require("fs").writeFileSync(process.argv[1], b);
                console.log("[orca-bridge] Screenshot saved: " + process.argv[1] + " (" + b.length + " bytes)");
              } else {
                console.error("[orca-bridge] Screenshot failed: " + (d.error?.message || "No data"));
              }
            } catch (e) {
              console.error("[orca-bridge] Screenshot error: " + e.message);
            }
          });
        ' "$out"
        ;;
      errors|console)
        echo "[orca-bridge] Checking browser console entries in $wt..."
        orca console --limit 50 "${wt_arg[@]}" --json 2>/dev/null | node -e '
          const data = JSON.parse(require("fs").readFileSync(0, "utf-8"));
          const msgs = data.result?.messages || [];
          if (msgs.length === 0) { console.log("No console errors/warnings recorded."); process.exit(0); }
          for (const m of msgs) {
            console.log(`[${m.type.toUpperCase()}] ${m.text}`);
          }
        '
        ;;
      network)
        echo "[orca-bridge] Checking recent browser network requests in $wt..."
        orca network --limit 50 "${wt_arg[@]}" --json 2>/dev/null | node -e '
          const data = JSON.parse(require("fs").readFileSync(0, "utf-8"));
          const reqs = data.result?.requests || [];
          if (reqs.length === 0) { console.log("No network logs recorded."); process.exit(0); }
          for (const r of reqs.slice(-20)) {
            console.log(`${r.status || "---"} ${r.method || "GET"} ${r.url}`);
          }
        '
        ;;
      open|goto)
        url="${3:-http://localhost:3999}"
        echo "[orca-bridge] Navigating browser to $url..."
        orca goto --url "$url" "${wt_arg[@]}" 2>/dev/null || orca tab create --url "$url" "${wt_arg[@]}"
        ;;
      *)
        echo "Usage: orca-bridge browser <snapshot|screenshot|errors|network|goto <url>>" >&2
        exit 1
        ;;
    esac
    ;;

  # 7. WORKTREE HELPER: Git worktree management
  worktree)
    subcmd="${2:-list}"
    case "$subcmd" in
      list)
        orca worktree list
        ;;
      create)
        wt_name="${3:-}"
        if [[ -z "$wt_name" ]]; then
          echo "Usage: orca-bridge worktree create <name>" >&2
          exit 1
        fi
        echo "[orca-bridge] Creating isolated worktree '$wt_name'..."
        orca worktree create --name "$wt_name"
        ;;
      current)
        orca worktree current
        ;;
      *)
        echo "Usage: orca-bridge worktree <list|create <name>|current>" >&2
        exit 1
        ;;
    esac
    ;;

  # 8. STATUS OVERVIEW
  status)
    omp_handle=$(get_handle "omp" || echo "not found")
    agy_handle=$(get_handle "agy" || echo "not found")
    wt=$(get_worktree_path)
    echo "=========================================================="
    echo " 🪐 Orca Dual-Engine Multi-Agent Bridge Status"
    echo "=========================================================="
    echo " [PANE 1] OMP / Claude Opus 5.5  (Mandor) : $omp_handle"
    echo " [PANE 2] Antigravity / Gemini 3.8 (Worker) : $agy_handle"
    echo " [WORKTREE] $wt"
    echo "----------------------------------------------------------"
    echo " Perintah Cepat:"
    echo " • orca-bridge delegate <title> <instruksi> (Opus -> Agy)"
    echo " • orca-bridge report <DONE|BLOCKED> <text>  (Agy -> Opus)"
    echo " • orca-bridge browser <snapshot|screenshot|errors|network>"
    echo " • orca-bridge worktree <list|create <name>>"
    echo "=========================================================="
    ;;

  *)
    echo "Usage: orca-bridge <send|read|wait|delegate|report|browser|worktree|status> [args...]"
    exit 1
    ;;
esac
