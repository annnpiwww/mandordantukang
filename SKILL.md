---
name: mandordantukang
description: "Dual-Engine Multi-Agent Architecture for AI Pair Programming: Expensive Frontier Model as Mandor (Architect/Planner/Reviewer) + Cheap Fast Model as Tukang Kerja (Heavy Hands-on Executor) orchestrated via Orca IDE with strict Anti-Handoff-Leak contract."
---

# 🏗️ Mandor dan Tukang (Dual-Engine AI Pair Programming)

Sistem arsitektur kolaborasi multi-agent untuk AI coding yang memecah peran menjadi 2 tier model untuk menghemat kuota token hingga >85% tanpa menurunkan kualitas arsitektur:
1. **Mandor (Pane 1 / Tier Pintar & Mahal)**: Claude Opus 5.5 / Sonnet / GPT-4o.
   - Peran: Arsitek, Strategist, System Planner, Review Gate, Quick-Fixer (≤ 15 baris).
   - Menjaga batas allowlist dan memegang verifikasi akhir.
2. **Tukang Kerja (Pane 2 / Tier Cepat & Murah)**: Gemini 3.8 Flash High / 2.5 Flash / Haiku.
   - Peran: Heavy Hands-on Executor. Koding multi-file, migrasi database, test runner (`npm test`), dan visual browser audit.
   - Dilarang membaca file di luar allowlist dan dilarang self-approve.
3. **Orca IDE Orchestration**:
   - Berjalan berdampingan di 2 panel terminal Orca IDE dan berkomunikasi via `orca-bridge`.

---

## 🔒 Anti-Handoff-Leak Contract

Kebocoran token terbesar pada sistem multi-agent terjadi saat handoff tugas. Jika Mandor memberikan spesifikasi tanpa batasan file, Tukang akan mengeksplorasi sendiri seisi repo dan membakar ribuan token context. 

Pola **Mandor dan Tukang** mengunci kontrak handoff dengan 3 aturan:
1. **File Allowlist**: Mandor wajib melampirkan daftar file yang boleh disentuh. Tukang **HARAM** membaca atau mengedit file di luar allowlist ini.
2. **Single Verification Command**: Mandor wajib menyertakan 1 perintah pasti untuk membuktikan hasil (`npm test`, `pytest`, `cargo test`).
3. **Mandor Holds Final Verification**: Tukang tidak boleh menilai atau meng-approve kerjaannya sendiri. Tukang hanya menyetor bukti konkret (diff & pass test count), Mandor yang memverifikasi dan ketok palu approve.

---

## ⚡ Role Contract & Aturan Main

| Aspek | Mandor (Opus / Sonnet) | Tukang Kerja (Gemini Flash / Haiku) |
| :--- | :--- | :--- |
| **Beban Koding** | **Pragmatis**: Jika task kecil (≤ 15 baris, typo, CSS/regex), **langsung edit sendiri**. Hanya delegasikan task berat ke Tukang. | **Full Hands-on**: Koding multi-file, refactoring besar, migrasi database, unit test runner, visual audit. |
| **Handoff Scope** | **Wajib sertakan**: `Allowed Files` + `Verify Command`. | **Strict Bound**: Dilarang jelajah/baca file di luar `Allowed Files`. |
| **Review Gate** | **Verifikasi Akhir**: Mandor yang menilai kelayakan. Jika test lolos semua (green), **WAJIB LANGSUNG APPROVE** (Strict Max 1 Pass Gate). | **No Self-Approve**: Cuma setor commit hash, diff, dan pass test log (`orca-bridge report DONE ...`). |
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

2. **Delegasi Task (Mandor -> Tukang)**:
   ```bash
   orca-bridge delegate "Judul Task" "- Allowed Files: [lib/auth.js, test/auth_test.js]\n- Logika: Implementasi refresh token\n- Verify Command: npm test test/auth_test.js"
   ```

3. **Laporan Selesai (Tukang -> Mandor)**:
   ```bash
   orca-bridge report DONE "Semua 12 test auth pass, diff 24 baris di lib/auth.js"
   ```

4. **Approval & Selesai**:
   Mandor memvalidasi hasil diff & test. Jika test hijau, langsung approve dan claim DONE tanpa ronde review tambahan.

---

## 🛡️ Aturan Wajib (Always-On)
1. **`rtk` prefix**: Semua perintah bash wajib diawali `rtk`.
2. **`caveman ultra`**: Output ke user maks 3-4 bullet points (< 50 kata).
3. **`ponytail`**: The Ladder (YAGNI -> reuse helper -> stdlib -> native -> minimal diff).
4. **`karpathy principles`**: Think before coding, tolak over-engineering, bersihkan sampah sendiri, strict verification.
5. **`humanizer-indonesia`**: Bahasa santai, bebas frasa kaku AI generik.
6. **`anti-slop`**: Bersihkan pola generik AI pada UI, copy, dan komentar kode.
7. **`7-point OWASP guards`**: Input validation, parameterized SQL, XSS escaping, credential hygiene (`.env`).
