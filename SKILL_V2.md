---
name: mandortukangv2
description: "Multi-Agent Squad Architecture (v2): 1 Mandor (Claude Opus 5.5 / Sonnet - Architect & Review Gate) + 3-4 Specialized Tukang Workers (Gemini Flash - UI/UX, Coder Logic, Security/QA) with Bilingual Token Optimization and Strict Anti-Handoff-Leak contract in Orca IDE."
---

# 🏗️ Mandor dan Tukang v2 (Multi-Agent Squad Architecture)

Sistem orkestrasi multi-agent tingkat lanjut untuk AI coding di Orca IDE. Mandor membagi dan mendelegasikan tugas ke regu Tukang Spesialis secara deterministik dengan batas allowlist ketat dan optimasi token bilingual.

## 👥 Roster & Spesialisasi Squad (4 Terminal Orca)

1. **Mandor (Pane 1 / Tier Pintar & Mahal)**: Claude Opus 5.5 / Sonnet via `omp`.
   - **Peran**: Lead Architect, System Planner, Review Gate. NOL EKSEKUSI: tidak edit kode, tidak build, tidak operasi DB; semua kerja (termasuk SIMPLE via `--force`) didelegasikan.
   - **Bilingual Protocol**:
     - **Ke Tukang**: Spesifikasi teknis wajib **Bahasa Inggris (English)** untuk memangkas konsumsi token hingga 30–40% (Ponytail Lever 3).
     - **Ke User (Aan)**: Output **Bahasa Indonesia gaul Gen-Z ultra-ringkas (Caveman Ultra)**, maks 3-4 bullet points (< 50 kata).
2. **Tukang UI/UX (Pane 2 / Tier Cepat & Murah)**: Gemini 3.8 Flash High via `agy`.
   - **Spesialisasi**: Layouts, Tailwind CSS, micro-motion, responsivitas mobile-to-desktop, WCAG AA accessibility, dan anti-slop UI suite.
3. **Tukang Coder (Pane 3 / Tier Cepat & Murah)**: Gemini 3.8 Flash High via `agy`.
   - **Spesialisasi**: Core business logic, backend APIs, migrasi & query database, clean architecture, minimal diff, and zero-grep navigation.
4. **Tukang Security & QA (Pane 4 / Tier Cepat & Murah)**: Gemini 3.8 Flash High via `agy`.
   - **Spesialisasi**: 7 OWASP mandatory guards, unit & integration test suites, fuzzing edge cases, dan regression testing.

---

## ⚡ Bilingual Token Optimization Protocol

Kebocoran token terbesar terjadi saat handoff prompt multibahasa yang bertele-tele. Mandor v2 menerapkan isolasi bahasa:

| Arah Komunikasi | Bahasa | Alasan & Aturan |
| :--- | :--- | :--- |
| **Mandor $\rightarrow$ Tukang** | **English (US)** | Istilah teknis, skema JSON, dan instruksi kode 30–40% lebih ringkas dan presisi dalam Bahasa Inggris (Ponytail Lever 3). |
| **Tukang $\rightarrow$ Mandor** | **English (US)** | Laporan ringkas 1 baris (`orca-bridge report DONE --task <id> "<summary>"`). |
| **Mandor $\rightarrow$ Human User** | **Indo Gaul Gen-Z** | Ultra-ringkas (Caveman Ultra), ceiling max 3–4 bullet points (< 50 kata), tanpa filler/esai. |

---

## 📜 Constitution Rules (dimuat otomatis)

| Pembaca | File di `rules/` | Cara dimuat |
| :--- | :--- | :--- |
| Mandor | `common.md`, `mandor-v2.md` | blok `mandortukangv2` di `AGENTS.md` project |
| `ui` / `coder` / `sec` | `common.md` + `tukang-<role>.md` | baris `ROLE` di handoff bridge saat spec punya `target_worker` |

`common.md` = GLOBAL rules (satu sumber, tidak diduplikasi di file peran).

---

## 🔒 Strict Anti-Handoff-Leak Contract

1. **File Allowlist**: Mandor wajib menentukan daftar file yang boleh disentuh. Tukang **HARAM** membaca atau mengedit file di luar allowlist.
2. **Targeted Worker Routing**: Mandor mengarahkan tugas ke worker spesialis melalui flag `--to <ui|coder|sec>`.
3. **Single Verification Command**: Mandor menyertakan 1 perintah verifikasi pasti (`npm test`, `pytest`, `cargo test`). Bridge menjalankan verifikasi secara otomatis saat laporan `DONE` masuk.
4. **No Self-Approve**: Tukang dilarang menilai kerjaannya sendiri; Mandor memegang hak mutlak verifikasi akhir.

---

## 🚀 Alur Kerja di Orca IDE

### 1. Inisialisasi Squad
Jalankan launcher squad untuk membuka 4 terminal terikat di Orca IDE:
```bash
orca-squad [path-project]
```

Terminal otomatis terikat:
- Pane 1: `OMP Mandor` $\rightarrow$ `mandor`
- Pane 2: `AGY Tukang UI` $\rightarrow$ `tukang-ui`
- Pane 3: `AGY Tukang Coder` $\rightarrow$ `tukang-coder` (default `tukang`)
- Pane 4: `AGY Tukang Security` $\rightarrow$ `tukang-sec`

### 2. Delegasi Tugas Terarah
Mandor mendelegasikan tugas ke spesialis tertentu:

```bash
# Delegasi ke Tukang UI
orca-bridge delegate --to ui --spec - <<'EOF'
{
  "task_type": "MEDIUM",
  "target_worker": "ui",
  "objective": "Build responsive pricing table with toggle and WCAG contrast",
  "allowed_files": ["src/components/Pricing.tsx", "src/styles/pricing.css"],
  "required_changes": [
    "Create 3-tier card layout with flex/grid",
    "Add monthly/yearly toggle switch with keyboard support",
    "Ensure contrast ratio >= 4.5:1"
  ],
  "acceptance_criteria": [
    "Layout aligns cleanly on 375px and 1280px viewports",
    "Toggle animates with smooth CSS transition",
    "pnpm test:ui passes"
  ],
  "verification_command": "pnpm test:ui",
  "constraints": ["No inline styles", "Touch only allowed files"]
}
EOF
```

```bash
# Delegasi ke Tukang Coder
orca-bridge delegate --to coder --spec task_logic.json

# Delegasi ke Tukang Security
orca-bridge delegate --to sec --spec task_auth_audit.json
```

### 3. Eksekusi & Laporan Tukang
Tukang menerima notifikasi prompt via Orca bridge, mengeksekusi file yang diizinkan, menjalankan verify command, lalu melapor:
```bash
orca-bridge report DONE --task <id> "Pricing table responsive and accessible, pnpm test:ui passes"
```

### 4. Mandor Review Gate
Bridge memvalidasi diff vs allowlist dan menjalankan ulang verifikasi command.
Jika `approvable: true`, Mandor langsung ketok palu:
```bash
orca-bridge task approve <id>
```
Jika butuh koreksi:
```bash
orca-bridge task reject <id> "<targeted 1-line English correction>"
```

### 5. Squad Board & Standby
Tiap delegasi/antrean, Mandor menampilkan status semua Tukang ke Aan: `BEKERJA` (task id), `STANDBY` (nunggu apa + tugas berikutnya), atau `TIDAK DIPAKAI` (alasan). Pane yang STANDBY dikirimi:
```bash
orca-bridge send ui "STANDBY: waiting for <task id>. Next for you: <job>. Do not read or edit files. Reply exactly: STANDBY ok"
```
Detail: `rules/mandor-v2.md` bagian 3b, perilaku worker: `rules/common.md` bagian 5.

---

## 🛠️ Perintah Cepat Bridge
- `orca-bridge status`: Menampilkan status koneksi Mandor dan seluruh squad.
- `orca-bridge pair bind <mandor|tukang|ui|coder|sec> <handle>`: Binding manual handle terminal.
- `orca-bridge usage report`: Melacak konsumsi token aktual dan estimasi per peran.
