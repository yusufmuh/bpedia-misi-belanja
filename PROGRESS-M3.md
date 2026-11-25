# PROGRESS-M3 · Misi Belanja v3

Agen: M3. Repo: `bpedia-misi-belanja` (paket `misi_belanja`). Mulai 26 Nov 2026.

## Tonggak

- [x] T0 Baca RENCANA, BRIEF §2 §5, SPEC §2.4 §6 §6.3 §7 §8 §10 §11, ARSITEKTUR §0 §1.3 §1.5, KEPUTUSAN, README kit, PROGRESS-R, rujukan owner (REF-ECOM-A/B, 3 gambar: 15.28.08 (2), 15.25.00 (2), 15.18.33 (2))
- [x] T1 Dasar: `pubspec.yaml` 3.0.0 + aset, `analysis_options.yaml`, `mission_assets.dart`, `mission_view.dart` (data tampilan, ViewState, Controller), `local_mission_controller.dart` + tes unit
- [x] T2 Widget v3: `MissionLadder`, `VoucherCard`, `StatusPill`, `MissionProgressTrack`, `MissionProductCard`, `MissionHowTo`, `LivelyPose` + 25 kasus widget v2 dibawa (lolos 26 Nov)
- [x] T3 Halaman `MissionsPage` (hero, tahap, progres, grid produk, voucher, bar bawah, perayaan, tamu, kurangi gerak) + tes alur (186 tes lolos 26 Nov)
- [x] T4 Tangkap layar terang + gelap, strip animasi, putaran lihat-perbaiki 1 (font tombol hilang karena `textStyle` tanpa keluarga font, bar bawah membungkus, judul hero/harga/tombol pada teks 200%, pesan menunggu, tautan pesanan ganda)
- [ ] T5 Putaran lihat-perbaiki 2, pilihan ke `docs/shots/`
- [ ] T6 `example/` (app + panel uji: hari, status, tema)
- [ ] T7 Dokumen: README, PRD v3, CHANGELOG 3.0.0
- [ ] T8 `flutter analyze` 0 isu, `flutter test --concurrency=3` penuh, commit lokal

## Keputusan

- Kit (`lib/src/kit/`) tidak diubah dan dikecualikan dari analyzer (sama seperti M1); kit dianalisis di stagingnya.
- Urutan halaman: hero, kartu tahap aktif (target, kupon hadiah, bar progres + Bipy), grid produk misi, tangga tahap dan hadiah, voucher, cara main. SPEC §6.3 menaruh tangga sebelum progres; di sini tangga lengkap turun ke bawah grid supaya produk misi terlihat di layar pertama (pola rujukan Tokopedia 15.28.08 (2)); kartu tahap aktif tetap memuat isi "kartu tahap aktif" SPEC.
- Perayaan tahap tuntas dipicu `MissionViewState.celebration`; halaman memanggil `acknowledgeCelebration()` saat lembar tampil supaya tidak berulang.
- Tamu: progres disembunyikan (KEPUTUSAN §5: progres misi wajib masuk), tambah ke keranjang tetap boleh, bar bawah "Masuk untuk ikut misi".
- `dart format` hanya untuk berkas milik M3 (jangan `dart format lib test`: kit dan `shot.dart` ikut terformat; sudah dipulihkan dengan git checkout).
- Produk contoh (16 foto) disalin dari `bpedia-app/assets/catalog/img/` ke `example/assets/products/` (data harga dari `catalog.json` potret 25 Nov 2026). Tahap 1 = 8 produk Animate, tahap 2 = 8 produk Pinkflash/Focallure.

## Cara melanjutkan

1. `git log --oneline` dan daftar tonggak di atas.
2. Iterasi: `flutter test --concurrency=3 test/<berkas>`; tangkap layar: `flutter test --concurrency=3 test/shots`; lihat PNG di `build/shots/`.
3. Tes penuh hanya di tonggak: `flutter analyze` lalu `flutter test --concurrency=3`.
