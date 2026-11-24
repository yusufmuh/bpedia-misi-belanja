# AGENTS.md · bpedia-misi-belanja

Berlaku untuk Codex, Antigravity, Claude, dan agen lain. Bahasa kerja: Indonesia.

1. Baca spesifikasi v2 dulu (menang bila ada perbedaan):
   - `../bpedia-kelopak-hub/docs/SPEC-CONTRACT.md`: §1 aturan bisnis, §2 API modul `misi_belanja`
   - `../bpedia-kelopak-hub/docs/SPEC-UIUX.md`: §3.8 Misi Belanja, §4 umpan balik, §6 copy
   - `../bpedia-kelopak-hub/docs/research/RISET-2026-11-24.md`: audit, katalog demo, versi paket
2. Lalu `PRD.md` (v2.0) di repo ini untuk aturan rinci dan uji penerimaan, serta `README.md` untuk pemakaian paket.
3. Aturan kerja, kualitas, dan larangan mengikuti `../bpedia-kelopak-hub/AGENTS.md`. PRD pusat: `../bpedia-kelopak-hub/PRD.md`.

Repo ini berisi paket Flutter `misi_belanja` dan server referensi `server/missions.php`. API publik hanya diekspor lewat `lib/misi_belanja.dart`; implementasi ada di `lib/src/`. Signature publik mengikuti SPEC-CONTRACT §2. Ubah aturan lintas fitur di hub, bukan di sini.

Sebelum selesai: `flutter analyze` menghasilkan "No issues found!", `flutter test` hijau, dan `php -l server/missions.php` bersih. Perbarui bagian Riwayat di `PRD.md`.
