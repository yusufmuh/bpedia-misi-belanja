# PRD 03 · Misi Belanja v3 (Bpedia Demo)

**Versi 3.0 · 26 November 2026 · Owner: Muhammad Yusuf (Bpedia)**
Paket Dart `misi_belanja` 3.0.0 · repo `bpedia-misi-belanja` · dipakai oleh `bpedia-kelopak-hub` (controller sungguhan) dan `bpedia-app` (kampanye demo).

Acuan (menang bila berbeda): `bpedia-asset-build/v3/KEPUTUSAN-V3.md` §3, `SPEC-V3.md` §6.3, `riset/ARSITEKTUR-V3.md` §1.3. Status: **Mode Demo**; nilai bertanda (demo) belum disetujui bisnis.

## 1. Masalah dan tujuan

Owner menolak v2 karena halaman misi membosankan dan **tidak menunjukkan produk yang harus dibeli** (K4). v3 menjawab tiga pertanyaan di layar pertama: *apa yang harus dibeli*, *berapa lagi*, *apa hadiahnya*, lalu memberi satu aksi berikut yang jelas (tambah ke keranjang, checkout, lihat pesanan, lihat voucher).

Ukuran keberhasilan (angka target ditetapkan owner): porsi pesanan selesai yang menuntaskan tahap 1, porsi voucher misi terpakai sebelum kedaluwarsa, jumlah produk misi per pesanan.

## 2. Aturan (KEPUTUSAN-V3 §3)

| Tahap | Syarat: 1 pesanan Selesai | Hadiah | Pakai voucher | Masa berlaku |
|---|---|---|---|---|
| 1 | subtotal produk misi min. Rp75.000 | Voucher Rp10.000 | min. belanja Rp100.000 | 30 hari (demo) |
| 2 (demo) | subtotal produk misi min. Rp100.000 | Voucher Rp15.000 | min. belanja Rp150.000 | 30 hari (demo) |
| Sesudahnya | — | — | — | "Tahap berikutnya menunggu kampanye" |

- **Subtotal produk misi** = Σ harga × jumlah untuk baris yang kodenya ada di `MissionStage.productCodes` tahap aktif (kosong = semua produk). Harga barang setelah diskon produk, sebelum voucher dan Kelopak, tanpa ongkir.
- Satu pesanan menyelesaikan paling banyak satu tahap; pesanan yang sama tidak dihitung dua kali; pesanan batal tidak dihitung.
- Voucher terpakai di pesanan yang kemudian batal kembali bisa dipakai (`MissionVoucher.release()`), masa berlaku tetap.
- Daftar produk misi demo diisi app (`bpedia-app/lib/config/demo_campaign.dart`): tahap 1 produk Animate skincare, tahap 2 semua produk Pinkflash dan Focallure.

## 3. Pengalaman (SPEC-V3 §6.3)

Urutan halaman `MissionsPage`:

1. **Hero pesta** (±220): chip "Tahap N dari M", judul "Misi Belanja", sub nominal voucher, Bipy berjalan membawa tas (sprite `bipy_jalan`), tas dan kupon 3D melayang, stiker hati/kilau/bunga.
2. **Kartu tahap aktif**: judul tahap + pil fase (*Belum mulai*, *Di keranjang*, *Siap checkout*, *Menunggu pesanan selesai*), target, kupon hadiah emas (nominal, min. belanja, masa berlaku), bar progres tebal dengan Bipy berjalan di ujung isian dan bendera target ("Produk misi di keranjang Rp42.600 / Rp75.000", "Tambah Rp32.400 lagi untuk voucher Rp10.000"). Penuh → hijau + "Siap checkout".
3. **Grid "Produk misi"** 2 kolom (pola marketplace): foto 1:1 berpita "Misi", nama 2 baris, harga, harga coret + diskon bila ada, tombol "+ Keranjang" yang berubah menjadi stepper. Chip kategori bila produk dari ≥ 2 kategori.
4. **Tahapan dan hadiah**: jalur bernomor (selesai = centang hijau, aktif = lingkaran permen, terkunci = gembok, "Segera") + kartu tiap tahap dengan kupon hadiah.
5. **Voucher kamu**: kupon tiket (Aktif/Terpakai/Kedaluwarsa) dengan tombol "Pakai".
6. **Cara main** (3 langkah berseni 3D) + "Syarat & ketentuan".
7. **Bar bawah menempel**: ikon tas + jumlah item, subtotal produk misi (angka naik) + kekurangan, tombol "Lihat keranjang" / "Checkout" (berdenyut). Tamu: "Masuk untuk ikut misi". Menunggu: "Lihat pesanan". Semua selesai: "Belanja lagi".

Gerak: tas terbang ke bar bawah saat tambah, bar berdenyut saat bertambah, konfeti saat target tercapai, lembar "Misi tuntas" (kupon jatuh memantul, konfeti, Bipy berjalan lalu melambai, nominal naik dari nol, "Lihat voucher" + "Lanjut tahap 2"). Suara lewat `GameCue` (`tap`, `bonus`, `missionDone`, `softError`).

Tamu boleh melihat semua dan mengisi keranjang; progres dan voucher butuh masuk (KEPUTUSAN §5).

## 4. Arsitektur (ARSITEKTUR D2)

Aturan murni → `MissionViewState` (tak-berubah) → `MissionController` (abstrak, `ChangeNotifier`) → `MissionsPage`. Halaman tidak tahu sumber data; produk masuk sebagai `MissionProduct` (data tampilan dengan `ImageProvider`), aksi lewat controller. `LocalMissionController` (memori) untuk `example/` dan tes. Hub mengisi controller sungguhan di atas `KelopakController`; perayaan dipicu `state.celebration` dan diakui dengan `acknowledgeCelebration()`.

API lengkap: `README.md` bagian API.

## 5. Aksesibilitas dan kinerja

- Teks tahan skala 200% di lebar 360 tanpa luapan (tes lima keadaan); judul hero dibatasi 1,5×.
- Target sentuh ≥ 48; Semantics: label kartu tahap (kalimat lengkap), nilai progres ("Rp45.000 dari Rp75.000"), tombol tambah/stepper per produk, voucher; pengumuman "Target misi tercapai".
- Kurangi gerak dihormati; animasi berulang berhenti saat tak terlihat (kit).
- Grid memakai sliver; sprite didekode sekali (kit).

## 6. Uji penerimaan

| Kasus | Bukti |
|---|---|
| 39 tes aturan v2 tetap lolos dengan asersi lama | `test/mission_order_test.dart`, `mission_voucher_test.dart`, `rupiah_test.dart`, `wib_date_test.dart`, `ticket_shape_test.dart`, `mission_stage_test.dart` |
| 25 kasus widget v2 dibawa ke widget v3 | `test/mission_ladder_test.dart`, `test/voucher_card_test.dart` |
| ViewState dan pengendali lokal | `test/mission_view_test.dart`, `test/local_mission_controller_test.dart` |
| Widget baru | `test/mission_widgets_test.dart` |
| Alur halaman (tamu, tambah, target, stepper, batas, filter, menunggu, perayaan, voucher, semua selesai, kosong, aturan, suara, 200%, semantics) | `test/missions_page_test.dart` |
| Tangkap layar terang/gelap + strip animasi | `test/shots/`, pilihan di `docs/shots/` |

## 7. Keputusan terbuka (owner)

- Masa berlaku voucher 30 hari dan nilai tahap 2 (demo).
- Daftar produk misi per tahap dan tahap ke-3 dan seterusnya.
- Apakah voucher misi boleh digabung dengan voucher promo lain.

## 8. Riwayat

- 3.0 (26 Nov 2026): produk misi, progres subtotal produk misi, halaman game v3, controller abstrak, `example/`.
- 2.0 (24 Nov 2026): tangga tahap, voucher bermasa berlaku, widget bertema.
- 1.0: satu tahap Rp75.000 → voucher Rp10.000.
