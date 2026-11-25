# Changelog · misi_belanja

## 3.0.0 · halaman game (26 Nov 2026)

Halaman Misi Belanja v3 (K4, SPEC-V3 §6.3) di atas aturan 3.0.0.

### Ditambahkan

- `MissionProduct`, `MissionPendingOrder`, `MissionCelebration`, `MissionPhase`, `MissionViewState` (tak-berubah; progres diturunkan dengan `missionProgress`) dan `MissionController` abstrak.
- `LocalMissionController`: pengendali memori dengan simulasi pesanan (checkout, kirim, selesai, batal), ganti hari, masuk/keluar, catatan navigasi.
- `MissionsPage`: hero pesta dengan Bipy berjalan, kartu tahap aktif + kupon hadiah + bar progres, grid produk misi (pita "Misi", tambah cepat, stepper, chip kategori), tangga tahap, voucher, cara main, aturan, bar bawah menempel, tamu "Masuk untuk ikut misi".
- Animasi: tas terbang ke keranjang, bar progres beranimasi dan berdenyut, konfeti saat target tercapai, lembar "Misi tuntas" (`showMissionCompleteSheet`, `TicketDrop`, `MissionWaveCompanion`).
- Widget: `MissionProgressTrack`, `MissionProductCard`, `QtyStepper`, `MissionHowTo`, `LivelyPose`, `StatusTone`.
- Aset: `assets/bipy/` (jalan, sapa, pose belanja/pesta/semangat), `assets/art/` (bag, ticket, flag, coin), `assets/fx/` (stiker) dengan `MissionArt` dan `MissionSprites`; kit pesta di `lib/src/kit/`.
- `example/`: app contoh dengan panel uji (masuk, status pesanan, hari, tema, kurangi gerak).
- Tangkap layar `docs/shots/`.

### Diubah

- `MissionLadder` ditulis ulang: jalur tahap horizontal + kartu tiap tahap dengan kupon hadiah; teks target "Belanja produk misi min. … dalam 1 pesanan"; label status tahap aktif bisa diganti (`activeStatus`).
- `VoucherCard` ditulis ulang bergaya tiket pesta (stub permen bertitik, tombol "Pakai" pil); perilaku tata letak dan Semantics v2 dipertahankan.
- `StatusPill` memakai `StatusTone` (warna dari tema host + nada status SPEC §2.1.2).
- `analysis_options.yaml`: `lib/src/kit/**` dan `build/**` dikecualikan.

## 3.0.0 · aturan (25 Nov 2026)

Perluasan aturan murni untuk Bpedia Demo v3 (produk misi, K4). Semua
parameter baru opsional: tahap tanpa `productCodes` menghitung semua produk,
persis seperti 2.0.0. `evaluateOrder`, `redeemProblem`, dan JSON
`MissionVoucher` tidak berubah.

### Ditambahkan

- `MissionStage`: parameter opsional `id`, `title`, `productCodes`.
  `id` dan `title` selalu terisi (bawaan `tahap-N` dan `Tahap N`);
  `productCodes` kosong = semua produk dihitung. Getter `countsAllProducts`
  dan metode `countsProduct(productCode)`.
- `lib/src/mission_products.dart`:
  - `MissionOrderLine` (`productCode`, `unitPrice`, `quantity`, `total`);
  - `missionSubtotal(stage, lines)`: subtotal produk misi satu tahap;
  - `evaluateOrderLines(...)`: padanan `evaluateOrder` yang menilai subtotal
    produk misi tahap aktif;
  - `MissionProgress` (`current`, `target`, `remaining`, `reached`,
    `fraction`) dan `missionProgress(stage, lines)`.
- `MissionVoucher.release()`: pesanan pemakai batal, voucher kembali bisa
  dipakai; masa berlaku tidak berubah.
- `server/missions.php`: `productCodes`, `missionStageId`,
  `missionStageTitle`, `missionCountsProduct`, `missionLineTotal`,
  `missionSubtotal`, `missionProgress`, `missionEvaluateOrderLines`,
  `missionReleaseVoucher`, `releaseDemoVoucher`; `recordDemoOrder` dan
  `missionSnapshot` menerima baris pesanan dan kampanye; swa-uji
  (`php server/missions.php`).

### Diubah

- `demoMissionStages` tahap 2 (nilai demo): voucher Rp15.000 dengan min.
  belanja Rp150.000 (sebelumnya Rp5.000, min. belanja Rp100.000). Ambang
  tahap 1 (Rp75.000) dan tahap 2 (Rp100.000) tidak berubah.
- Kesetaraan, `hashCode`, dan `toString` `MissionStage` ikut memperhitungkan
  `id`, `title`, dan `productCodes`.

### Tes

- Nilai kampanye 2.0.0 menjadi fixture `v2MissionStages`
  (`test/support/v2_fixtures.dart`); 39 tes aturan lama lolos dengan asersi
  yang sama.
- Tes baru: produk misi (subtotal, evaluasi baris, progres), kolom tahap
  baru, dan pelepasan voucher.

## 2.0.0 · 24 Nov 2026

Aturan murni (tahap, evaluasi pesanan, voucher), widget tangga misi dan kartu
voucher bertema, PRD v2.
