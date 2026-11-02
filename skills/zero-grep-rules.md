# Zero-Grep Policy & Semantic Code Navigation

Alasan:
Melakukan grep file-per-file secara manual memboroskan 5.000–30.000 token context window per sesi.

Hierarki Pencarian Wajib:
1. **Semantic Concept Search**: `semantex --refs "<konsep>"` (mengembalikan baris spesifik tanpa dump file, hemat token -84%).
2. **Go-To-Definition**: `rtk xerj def "<simbol>"` atau Serena MCP `find_symbol` (langsung dapat line + signature).
3. **Passage Search**: `rtk xerj search "<query>"` (potongan kode spesifik).
4. **Call Graph & Blast Radius**: `gitnexus context <simbol>` dan `gitnexus impact <simbol>` (melihat caller/callee).
5. **AST Edits**: Serena MCP (`replace_symbol_body`, `insert_after_symbol`) untuk safe editing tanpa merusak AST.
6. **Fallback Grep Ketat**: Grep HANYA diizinkan untuk exact string non-kode (misal variabel `.env`), string literal langka, atau verifikasi nol referensi. Dilarang grep nama function atau class!
