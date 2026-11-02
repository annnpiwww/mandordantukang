# 🏗️ Mandor dan Tukang: Dual-Engine Multi-Agent Coding in Orca IDE

> **Arsitektur AI Pair Programming 2-Tier: Model Frontier Mahal sebagai Mandor (Arsitek & Planner) + Model Cepat & Murah sebagai Tukang Kerja (Heavy Hands-on Executor) dengan Anti-Handoff-Leak Contract. Target: total token per task yang berhasil serendah mungkin tanpa mengorbankan kualitas arsitektur software. Penghematan belum dibenchmark; ukur pakai `orca-bridge usage compare` ([bench/README.md](bench/README.md)).**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Orca%20IDE%20%7C%20Linux%20%7C%20macOS-cyan.svg)](#)
[![Multi-Model](https://img.shields.io/badge/Models-Claude%20Opus%20%2B%20Gemini%20Flash-orange.svg)](#)

---

## 💥 The Problem: Kenapa AI Coding Agent Sering Bikin Tekor?

1. **Pakai Model Mahal (Claude Opus / GPT-4o / Sonnet) untuk Semua Hal**:
   - Mengetik ratusan baris kode, running test berulang kali (`npm test`), migrasi DB, dan fixing error syntax receh menggunakan model tier atas bikin kuota mingguan ludes dalam 2-3 hari.
2. **Pakai Model Murah (Gemini Flash / Claude Haiku) untuk Semua Hal**:
   - Koding cepat dan murah, tapi arsitektur berantakan, sering halusinasi API, dan gampang terjebak loop refactoring tanpa arah.
3. **Kebocoran di Handoff (The Handoff Leak)**:
   - Saat tugas didelegasikan ke model pelaksana (Tukang) tanpa batasan file yang jelas, si Tukang bakal mengeksplorasi sendiri seisi repo, membaca puluhan file yang baru saja dihemat, dan membakar token context window secara sia-sia.
4. **Penyakit "Ronde Review Berulang" (Review Loops)**:
   - Agen saling melempar review 2, ronde 3, fix2, fix3 tanpa batasan tegas, membakar jutaan token hanya untuk perdebatan kosmetik.

---

## 💡 The Solution: Pola "Mandor dan Tukang"

Sistem ini membagi pekerjaan AI coding menjadi dua peran terpisah yang terkoordinasi di **Orca IDE**:

```mermaid
flowchart TD
    subgraph Orca IDE Dual-Pane Architecture
        direction TB
        subgraph Pane 1: Mandor [Pane 1: Mandor (Claude Opus 5.5 / Sonnet)]
            M1[Arsitek, Strategist & Planner]
            M2[Quick Fix ≤ 15 baris langsung edit]
            M3[Strict Max 1-Pass Review Gate]
            M4[Pegang Verifikasi Akhir]
        end
        
        subgraph Pane 2: Tukang [Pane 2: Tukang Kerja (Gemini 3.8 Flash High)]
            T1[Heavy Hands-on Code Editing]
            T2[Migrasi & Seeding Database]
            T3[Test Runner & Verification]
            T4[Browser Visual UI Audit]
            T5[Strict Boundary: No Out-of-Allowlist Read]
        end
    end

    User([Developer / User]) -->|Goal / Requirement| Pane 1
    Pane 1 -->|"orca-bridge delegate (File Allowlist + Single Verify Command)"| Pane 2
    Pane 2 -->|"orca-bridge report DONE (Diff + Test Pass Evidence)"| Pane 1
    Pane 1 -->|Caveman Ultra Approval| User
```

---

## 🔒 The Anti-Handoff-Leak Contract (Kunci Anti-Bocor)

Agar token tidak bocor saat estafet tugas dari Mandor ke Tukang, sistem ini mewajibkan **3 Kontrak Handoff**:

1. **File Allowlist (`Allowed Files`)**:
   - Mandor wajib menyebutkan daftar file spesifik yang boleh disentuh.
   - Tukang **HARAM** membaca, mencari, atau mengedit file di luar allowlist ini (dilarang blind scan repo).
2. **Single Verification Command (`Verify Command`)**:
   - Mandor wajib menyertakan 1 perintah pasti untuk memvalidasi hasil kerja (`npm test <target>`, build check).
3. **Mandor Holds Final Verification (No Self-Approval)**:
   - Tukang tidak boleh menilai atau meng-approve kerjaannya sendiri.
   - Tukang hanya menyetor bukti konkret: commit hash, diff ringkas, dan output pass test. Mandor yang memvalidasi dan ketok palu approve.

---

## 👥 Spesifikasi Peran

### 1. Mandor (Pane 1 — Claude Opus 5.5 / Sonnet / GPT-4o)
- **Fokus**: Arsitektur, verifikasi ground truth data, menyusun spec/PRD, dan review gate.
- **Pragmatic Quick-Fix**: Jika ada task kecil (≤ 15 baris, typo, 1-2 baris CSS/regex), **langsung edit sendiri**. Jangan buang token untuk nulis instruksi delegasi panjang.
- **Strict Anti-Ronde-Loop (Max 1 Pass Gate)**: Begitu test hijau dan tugas selesai, **WAJIB LANGSUNG APPROVE**. Dilarang buka ronde review tambahan untuk nitpick kosmetik sepele.

### 2. Tukang Kerja (Pane 2 — Gemini 3.8 Flash High / 2.5 Flash / Claude Haiku)
- **Fokus**: Koding hands-on multi-file, refactoring besar, migrasi database, eksekusi test runner (`npm test`), dan visual browser audit.
- Bekerja cepat, berbiaya sangat rendah, dan memiliki context window besar tanpa risiko kehabisan kuota akun frontier.

### 3. Jembatan Koordinasi: `orca-bridge`
Komunikasi antar-pane di Orca IDE berlangsung lewat command CLI ringkas tanpa spam buffer:
- `orca-bridge delegate --spec task.json` (Mandor ➡️ Tukang, spec JSON divalidasi, task punya ID & state)
- `orca-bridge delegate <title> <instruksi>` (format lama; wajib `Allowed Files:` + `Verify Command:`)
- `orca-bridge report DONE --task <id> <summary>` (Tukang ➡️ Mandor; bridge menjalankan verify + cek scope sendiri)
- `orca-bridge task approve|reject|resume|revert|amend|diff|list <id>` (gate & recovery Mandor)
- `orca-bridge usage report|compare` (token tracker, actual vs estimated dibedakan)
- `orca-bridge pair bind <mandor|tukang> <handle>` (routing terminal deterministik)
- `orca-bridge browser <snapshot|screenshot|errors|network|goto>` (Shared Orca Browser Audit)

### 4. Alur task & enforcement
```mermaid
stateDiagram-v2
    [*] --> PENDING: task new / delegate --spec (spec divalidasi)
    PENDING --> ASSIGNED: task assign (baseline diff + opsional worktree)
    ASSIGNED --> EXECUTING: handoff terkirim
    ASSIGNED --> FAILED: Tukang tidak bisa dihubungi
    EXECUTING --> VERIFYING: report DONE
    VERIFYING --> REVIEWING: bridge jalankan verify + cek scope
    EXECUTING --> REVIEWING: report BLOCKED
    REVIEWING --> APPROVED: task approve (scope ok, exit 0, tidak berubah sejak verify)
    REVIEWING --> EXECUTING: task reject "<fix>" (retry ≤ max_retries)
    REVIEWING --> REJECTED: retry habis / --final
    FAILED --> EXECUTING: task resume
```
- State task disimpan di `~/.local/state/mandordantukang/` (di luar repo, tidak mengotori `git status`), satu folder per task: `task.json`, `state.json`, `events.log`, `verify.log`, `usage.jsonl`.
- Lock per task (mkdir atomik, lock basi dibersihkan otomatis) mencegah eksekusi ganda; dua task non-isolated aktif di tree yang sama ditolak karena diff-nya bakal campur.
- Batasan: tanpa `isolate`, perubahan Tukang langsung ada di tree utama; approve menolak, tapi undo-nya eksplisit (`task revert`). Bridge tidak men-sandbox proses agent; Tukang yang nakal tetap bisa menulis file apa pun, hanya saja ketahuan dan tidak bisa di-approve.

---

## 🛡️ Suite Skill & Guardrails Terintegrasi

Paket ini sudah mengikutsertakan konfigurasi bawaan:
- **`rtk` Terminal Prefix**: Standardisasi audit trail eksekusi bash.
- **`caveman-ultra`**: Output ke user maksimal 3-4 bullet points (< 50 kata), bebas esai naratif panjang.
- **`ponytail` Ladder**: YAGNI ekstrem, selalu prioritaskan reuse kode/helper yang sudah ada sebelum menulis kode baru.
- **`zero-grep-rules`**: Larangan scan grep 1-per-1. Gunakan pencarian semantik (`semantex`), instant symbol definition (`xerj def`), dan call graph (`gitnexus`).
- **`humanizer-indonesia`**: Bahasa santai, luwes, dan natural tanpa pola klise AI.
- **`4 Karpathy Principles`**: Think before coding, Simplicity first, Surgical blast radius, dan Strict verification.
- **`7 OWASP Guards`**: Input validation, parameterized SQL query, XSS escaping, credential hygiene (`.env`).

---

## ⚡ Quickstart & Instalasi

### 1. Clone & Pasang Global Tooling
```bash
git clone git@github.com:annnpiwww/mandordantukang.git ~/.agents/skills/mandordantukang
cd ~/.agents/skills/mandordantukang
./scripts/install.sh
```

Perintah ini akan memasang binary `orca-bridge` dan `orca-pair` ke `~/.local/bin/` dan `mandor-lib.js` ke `~/.local/share/mandordantukang/`. Aman diulang (upgrade): file lama di-backup, symlink tidak ditimpa lewat target-nya, skill yang sudah kamu edit tidak ditimpa (versi baru disimpan sebagai `.new`, `--force` untuk menimpa), gagal di tengah = rollback. Uninstall: `./scripts/install.sh --uninstall`.

Aktifkan flow untuk semua project (omp + agy), sekali jalan:
```bash
./scripts/install.sh --global-rules
```
Menulis blok `<!-- mandordantukang:start/end -->` dari `rules/mandor.md` ke `~/.omp/agent/RULES.md` (omp, Mandor) dan `rules/tukang.md` ke `~/.gemini/GEMINI.md` (agy, Tukang), plus link skill untuk agy di `~/.gemini/config/skills/`. Isi file di luar blok tidak disentuh, file lama di-backup, diulang tidak dobel, `--uninstall` menghapus blok. Override path: `OMP_RULES`, `AGY_RULES`, `AGY_SKILLS`.

Butuh: `bash`, `git`, `node >= 16`, Orca IDE (`orca` CLI). Opsional: `timeout` (coreutils) untuk batas waktu verify.

### 2. Jalankan Dual-Engine di Proyek Manapun
Buka terminal dan arahkan ke proyek Anda:
```bash
orca-pair /path/ke/proyek-anda
```

Skrip `orca-pair` otomatis:
1. Membuka Orca IDE.
2. Membuka 2 pane berdampingan (Pane 1: `omp` Mandor, Pane 2: `agy` Tukang Kerja).
3. Mengonfigurasi `AGENTS.md`, `CLAUDE.md`, dan `GEMINI.md` secara otomatis.
4. Menghubungkan bridge koordinasi `orca-bridge`.

---

## 📁 Struktur Repositori

```
mandordantukang/
├── SKILL.md                  # Definisi format Skill standar untuk AI Agent
├── CLAUDE.md                 # Prompt & konfigurasi spesifik untuk Mandor (Pane 1)
├── GEMINI.md                 # Prompt & konfigurasi spesifik untuk Tukang (Pane 2)
├── AGENTS.md                 # Aturan bersama (OWASP, Karpathy, Zero-Grep, Handoff-Lock)
├── VERSION                   # Versi terpasang dicek installer & `orca-bridge version`
├── scripts/
│   ├── orca-bridge.sh        # Relay antar-terminal + task state, verify, scope check, token tracker
│   ├── mandor-lib.js         # Helper JSON (validasi spec, routing, scope, usage) tanpa dependency
│   ├── orca-pair.sh          # Launcher 2-pane otomatis di Orca IDE + bind handle
│   └── install.sh            # Install/upgrade/uninstall dengan backup & rollback
├── tests/                    # `bash tests/run.sh` (fake Orca CLI, tanpa model)
├── bench/                    # Fixture + skenario benchmark single vs pair
├── docs/AUDIT.md             # Hasil audit, perubahan, catatan instruksi
└── skills/                   # Roster skill modular bawaan
    ├── caveman-ultra.md
    ├── ponytail.md
    ├── rtk.md
    ├── humanizer-indonesia.md
    ├── karpathy-principles.md
    ├── zero-grep-rules.md
    └── antislop.md
```

---

## 📄 License
MIT License © 2026 annnpiwww
