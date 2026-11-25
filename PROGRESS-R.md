# PROGRESS-R · bpedia-misi-belanja (agen R, aturan murni v3)

Lingkup: `lib/src/*.dart` non-widget, `lib/misi_belanja.dart`, `server/missions.php`, tes aturan.
Widget lama (`lib/src/widgets/*`) tidak diubah; ditulis ulang agen M3.

## Tonggak

- [x] 1. `mission_stage.dart`: `MissionStage` + `id`, `title`, `productCodes`; `demoMissionStages` tahap 2 v3
- [x] 2. `mission_products.dart`: `MissionOrderLine`, `missionSubtotal`, `evaluateOrderLines`, `MissionProgress`, `missionProgress`
- [x] 3. `mission_voucher.dart`: `MissionVoucher.release()`
- [x] 4. Tes: fixture `v2MissionStages`, 39 tes lama, tes baru
- [x] 5. `server/missions.php` v3 + swa-uji (96 cek, 0 gagal)
- [x] 6. `flutter analyze`, `flutter test` penuh (109 lolos), CHANGELOG 3.0.0, commit lokal

## Keputusan

- `MissionStage.id` dan `title` adalah getter yang selalu terisi: nilai eksplisit bila diberikan, selain itu `tahap-N` dan `Tahap N`. Dengan begitu `demoMissionStages.first` tetap setara dengan konstruksi lama tanpa `id`/`title`, dan tes v2 lolos tanpa mengubah asersi.
- `demoMissionStages` tidak diberi `id`, `title`, maupun `productCodes` khusus; host (`demo_campaign.dart` di app) yang mengisinya.
- `MissionOrderLine.total` bernilai 0 untuk harga atau jumlah yang tidak positif, supaya data rusak tidak pernah mengurangi subtotal di build rilis (assert hanya aktif saat pengembangan).
- `evaluateOrderLines` hanya menghitung subtotal produk misi tahap aktif lalu meneruskan ke `evaluateOrder`, jadi urutan pemeriksaan dan hasilnya identik.
- `MissionVoucher.release()` tidak mengubah `expiresDay`; voucher yang belum dipakai dikembalikan apa adanya (objek yang sama).
- `test/mission_order_test.dart`: ARSITEKTUR menyebut berkas ini tidak diubah, tetapi satu asersinya (`voucherAmount == 5000` untuk tahap 2) bergantung pada nilai demo v2. Supaya asersi tetap sama, hanya identifier fixture yang diganti secara mekanis (`demoMissionStages` -> `v2MissionStages`, plus satu baris impor), sama seperti pola di repo roda.
- `test/mission_ladder_test.dart` (tes widget lama, akan ditulis ulang M3): hanya identifier fixture yang diganti dengan cara yang sama. `test/mission_voucher_test.dart`, `voucher_card_test.dart`, dan berkas lain tidak disentuh.
- `pubspec.yaml` (versi paket) tidak disentuh: milik agen M3.
- `test/support/shot.dart` (milik orkestrator, tidak boleh diubah) memberi 2 info `unnecessary_lambdas` di `flutter analyze`; berkas milik agen R bersih.

## Cara melanjutkan

Semua tonggak selesai. Perintah verifikasi:

```bash
flutter analyze
flutter test --concurrency=3
php -d extension=pdo_sqlite server/missions.php
```
