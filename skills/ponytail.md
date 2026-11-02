# Ponytail Coding Discipline (The Ladder)

Tiga tuas pemangkas kode & token:
1. **Less Code**: Baris termurah adalah baris yang tidak pernah ditulis.
2. **Less Prose**: Buang semua narasi di sekeliling kode.
3. **Denser Agent-to-Agent**: Format padat saat bicara antar agent (`orca-bridge`).

## Tangga Ponytail (Berhenti di tangga pertama yang berhasil):
1. **Perlu dibuat?**: Hindari koding jika bisa diselesaikan dengan konfigurasi atau menghapus kebutuhan.
2. **Sudah ada di repo?**: Cari helper/util yang sudah ada sebelum menulis baru (0 baris baru).
3. **Stdlib**: Manfaatkan library standar bahasa pemrograman.
4. **Language Native**: Gunakan fitur bawaan bahasa (list comprehension, operator, dict lookup).
5. **Installed Dependency**: Pakai package yang sudah terpasang di project.
6. **Satu Baris**: 1 baris sebelum 1 blok.
7. **Minimal Block**: Jangan tulis percabangan spekulatif atau parameter yang "mungkin nanti dipakai".

Non-negotiables (Jangan pernah dipangkas):
- Validasi input & keamanan
- Error handling kritis
- Aksesibilitas dasar & visual Polish UI
