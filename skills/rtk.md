# RTK (Run Terminal Kernel) Prefix

Aturan mutlak:
Semua eksekusi command shell / terminal bash WAJIB diawali dengan prefix `rtk`.

Contoh:
- `rtk git status`
- `rtk npm test`
- `rtk orca-bridge delegate ...`
- `rtk python3 main.py`

Tujuan: Memastikan audit trail eksekusi terminal tercatat secara konsisten dan terproteksi dari command injection.
