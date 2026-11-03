---
name: mandordantukang
description: "Dual-Engine Multi-Agent Architecture for AI Pair Programming: Expensive Frontier Model as Mandor (Architect/Planner/Reviewer) + Cheap Fast Model as Tukang Kerja (Heavy Hands-on Executor) orchestrated via Orca IDE with strict Anti-Handoff-Leak contract."
---

# 🏗️ Mandor dan Tukang (Dual-Engine AI Pair Programming)

Sistem arsitektur kolaborasi multi-agent untuk AI coding yang memecah peran menjadi 2 tier model. Target: total token per task yang berhasil serendah mungkin tanpa menurunkan kualitas arsitektur. Penghematan belum dibenchmark; ukur sendiri pakai `orca-bridge usage compare` (lihat `bench/README.md`), jangan pakai angka persen tanpa data.
1. **Mandor (Pane 1 / Tier Pintar & Mahal)**: Claude Opus 5.5 / Sonnet / GPT-4o.
   - Peran: Arsitek, Strategist, Product & UI/UX Reviewer, System Planner, Review Gate, Quick-Fixer (≤ 15 baris).
   - Metodologi on-demand: `skills/principal-workflow.md`, `skills/product-intelligence.md`, `skills/uiux-intelligence.md`.
   - Menjaga batas allowlist dan memegang verifikasi akhir.
2. **Tukang Kerja (Pane 2 / Tier Cepat & Murah)**: Gemini 3.8 Flash High / 2.5 Flash / Haiku.
   - Peran: Heavy Hands-on Executor. Koding multi-file, migrasi database, test runner (Verify Command dari Mandor), dan visual browser audit.
   - Dilarang membaca file di luar allowlist dan dilarang self-approve.
3. **Orca IDE Orchestration**:
   - Berjalan berdampingan di 2 panel terminal Orca IDE dan berkomunikasi via `orca-bridge`.

---

## 🔒 Anti-Handoff-Leak Contract

Kebocoran token terbesar pada sistem multi-agent terjadi saat handoff tugas. Jika Mandor memberikan spesifikasi tanpa batasan file, Tukang akan mengeksplorasi sendiri seisi repo dan membakar ribuan token context. 

Pola **Mandor dan Tukang** mengunci kontrak handoff dengan 3 aturan:
1. **File Allowlist**: Mandor wajib melampirkan daftar file yang boleh disentuh. Tukang **HARAM** membaca atau mengedit file di luar allowlist ini.
2. **Single Verification Command**: Mandor wajib menyertakan 1 perintah pasti untuk membuktikan hasil (`npm test`, `pnpm test`, `pytest`, `cargo test`, `go test ./...`). Kosong = dideteksi otomatis dari project; tidak terdeteksi = spec ditolak.
3. **Mandor Holds Final Verification**: Tukang tidak boleh menilai atau meng-approve kerjaannya sendiri. Tukang hanya menyetor laporan; bridge menjalankan verify sendiri (exit code asli) dan mengecek diff vs allowlist + file sensitif, lalu Mandor yang ketok palu approve.

Enforcement ada di `orca-bridge` (bukan cuma prompt): `task approve` menolak kalau scope dilanggar, verify gagal, atau ada file berubah setelah verify. Task `isolate: true` dikerjakan di git worktree terpisah dan baru masuk tree utama saat approve.

---

## ⚡ Role Contract & Aturan Main

| Aspek | Mandor (Opus / Sonnet) | Tukang Kerja (Gemini Flash / Haiku) |
| :--- | :--- | :--- |
| **Beban Koding** | **Pragmatis**: Jika task kecil (≤ 15 baris, typo, CSS/regex), **langsung edit sendiri**. Hanya delegasikan task berat ke Tukang. | **Full Hands-on**: Koding multi-file, refactoring besar, migrasi database, unit test runner, visual audit. |
| **Handoff Scope** | **Wajib sertakan**: `Allowed Files` + `Verify Command`. | **Strict Bound**: Dilarang jelajah/baca file di luar `Allowed Files`. |
| **Review Gate** | **Verifikasi Akhir**: Mandor yang menilai kelayakan dari baris `CHECK` bridge. Jika `approvable: true` dan kriteria terpenuhi, **WAJIB LANGSUNG APPROVE** (Strict Max 1 Pass Gate, retry default maks 1). | **No Self-Approve**: Cuma setor laporan 1 baris (`orca-bridge report DONE --task <id> ...`); bukti diff & test dilampirkan bridge. |
| **Gaya Output** | **Caveman Ultra & Anti-Essay**: Maksimal 3-4 bullet points (< 50 kata) ke user. Delegasi teknis ke Tukang maksimal 15 baris bullet. | Ultra-ringkas, fokus bukti konkret eksekusi. |
| **Pencarian Kode** | **Zero-Grep Policy**: Dilarang blind scan. Gunakan `semantex --refs`, `xerj def`, `serena`, dan `gitnexus`. | Targeted read & minimal blast radius. |

---

## 🚀 Alur Kerja di Orca IDE

1. **Inisialisasi Project**:
   ```bash
   orca-pair [path-project]
   ```
   Membuka 2 pane terminal otomatis:
   - Pane 1: `omp` (Claude Opus - Mandor)
   - Pane 2: `agy` (Gemini Flash - Tukang)

2. **Delegasi Task (Mandor -> Tukang)**, terstruktur & divalidasi:
   ```bash
   orca-bridge delegate --spec task.json
   ```
   Format lama tetap jalan (wajib `Allowed Files:` + `Verify Command:`):
   ```bash
   orca-bridge delegate "Judul Task" "- Allowed Files: [lib/auth.js, test/auth_test.js]\n- Logika: Implementasi refresh token\n- Verify Command: npm test test/auth_test.js"
   ```

3. **Laporan Selesai (Tukang -> Mandor)**:
   ```bash
   orca-bridge report DONE --task <id> "Refresh token jalan, lib/auth.js + test"
   ```
   Bridge menjalankan verify + cek scope, lalu mengirim `CHECK {...}` ke Mandor.

4. **Approval & Selesai**:
   `orca-bridge task approve <id>` (atau `task reject <id> "<fix spesifik>"`). Jika `approvable: true`, langsung approve tanpa ronde review tambahan.

5. **Token tracker**: `orca-bridge usage report` (actual vs estimated dibedakan), `orca-bridge usage compare` untuk benchmark single vs pair.

---

## 🛡️ Aturan Wajib (Always-On)
1. **`rtk` prefix**: Semua perintah bash wajib diawali `rtk`.
2. **`caveman ultra`**: Output ke user maks 3-4 bullet points (< 50 kata).
3. **`ponytail`**: The Ladder (YAGNI -> reuse helper -> stdlib -> native -> minimal diff).
4. **`karpathy principles`**: Think before coding, tolak over-engineering, bersihkan sampah sendiri, strict verification.
5. **`humanizer-indonesia`**: Bahasa santai, bebas frasa kaku AI generik.
6. **`anti-slop`**: Bersihkan pola generik AI pada UI, copy, dan komentar kode.
7. **`7-point OWASP guards`**: Input validation, parameterized SQL, XSS escaping, credential hygiene (`.env`).
