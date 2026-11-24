# PRD 03 · Misi Belanja Bertahap (Bpedia Preview)

**Versi 2.0 · 24 November 2026 · Owner: Muhammad Yusuf (Bpedia)**
Paket Dart `misi_belanja` 2.0.0 · repo `bpedia-misi-belanja` · dipakai oleh `bpedia-kelopak-hub`.

Acuan wajib (menang bila ada perbedaan):
- `../bpedia-kelopak-hub/docs/SPEC-CONTRACT.md`: §1 aturan bisnis, §2 API modul, §3 tema.
- `../bpedia-kelopak-hub/docs/SPEC-UIUX.md`: §3.3 keranjang & checkout, §3.4 transaksi, §3.8 Misi Belanja, §4 umpan balik, §6 copy.
- `../bpedia-kelopak-hub/docs/research/RISET-2026-11-24.md`: audit app lama, katalog demo, versi paket.

Status: **Mode Demo**. Engine berjalan lokal di perangkat. Nilai bertanda *Demo* belum disetujui bisnis.

---

## 1. Tujuan

Mendorong pesanan berulang. Pesanan selesai yang memenuhi syarat memberi voucher untuk pesanan **berikutnya**, lalu tahap berikutnya terbuka. Audit app lama mencatat misi hanya satu tingkat dan tanpa masa berlaku. Versi ini menjadikannya tangga bertahap dengan masa berlaku dan aturan yang bisa dibaca di tempat.

Setiap layar misi menjawab tiga pertanyaan: tahap mana yang aktif, apa syarat dan hadiahnya, dan apa langkah berikutnya.

Ukuran keberhasilan (target angkanya ditetapkan owner; modul ini tidak mengarang angka):
- porsi pesanan selesai yang menyelesaikan tahap 1,
- porsi voucher yang terpakai sebelum kedaluwarsa,
- jarak hari antara pesanan sumber dan pesanan yang memakai voucher.

## 2. Glosarium

| Istilah | Arti |
|---|---|
| Misi Belanja | Program voucher bertahap ini. Nama tunggal di semua UI. |
| Tahap | Satu langkah misi: "Tahap 1", "Tahap 2". |
| Pesanan selesai | Pesanan berstatus **Selesai**. Di demo, pengguna menekan "Pesanan Diterima" pada pesanan berstatus Dikirim. |
| Subtotal eligible | Nilai pesanan yang dinilai misi (lihat §4). |
| Voucher | Potongan rupiah dari tahap yang selesai. Tampil di Hadiahku. |
| Hari WIB | Nomor hari sejak 1 Jan 1970 pada UTC+7 (`wibDay`). |

## 3. Tahap

| Tahap | Syarat: 1 pesanan selesai | Hadiah | Syarat pakai voucher | Masa berlaku |
|---|---|---|---|---|
| 1 | subtotal eligible min. Rp75.000 | Voucher Rp10.000 | pesanan **lain** berikutnya, min. belanja Rp100.000 | 30 hari (Demo) |
| 2 (Demo) | subtotal eligible min. Rp100.000 | Voucher Rp5.000 | pesanan lain, min. belanja Rp100.000 | 30 hari (Demo) |
| Sesudahnya | belum ada | belum ada | belum ada | "Tahap berikutnya menunggu kampanye" |

- Tahap N+1 terbuka tepat saat voucher Tahap N terbit.
- Status tahap: **Selesai** (voucher sudah terbit), **Aktif** (pesanan selesai berikutnya dinilai untuk tahap ini), **Terkunci** (menunggu voucher tahap sebelumnya).
- Konfigurasi demo ada di `demoMissionStages`. Kampanye lain cukup memberi `List<MissionStage>` baru tanpa mengubah widget.

## 4. Definisi subtotal eligible

Subtotal eligible = jumlah (harga final produk × jumlah) **setelah** diskon produk (harga coret sudah berlaku).

- Tidak termasuk ongkir, biaya layanan, asuransi, dan biaya penanganan.
- Dihitung **sebelum** potongan voucher misi dan **sebelum** potongan Kelopak (Demo, lihat §11).
- Definisi yang sama dipakai untuk "min. belanja" saat memakai voucher.

Contoh dengan katalog demo: 2 × Animate Acne Care Serum 20 ml (Rp20.500) + 1 × Azarine Hydrasoothe Sunscreen Gel 50 ml (Rp49.000) = **Rp90.000**. Pesanan ini memenuhi Tahap 1 (min. Rp75.000), tetapi belum cukup untuk memakai voucher (min. belanja Rp100.000, kurang Rp10.000).

## 5. Aturan bisnis

### 5.1 Penilaian pesanan (`evaluateOrder`)

Dipanggil saat pesanan berubah menjadi Selesai. Pemeriksaan berurutan dan berhenti di penolakan pertama:

| Urutan | Kondisi | Hasil | Copy lembar hasil (hub) |
|---|---|---|---|
| 1 | pesanan belum Selesai | `notCompleted` | "Misi dihitung setelah pesanan diterima." |
| 2 | `orderId` sudah ada di `countedOrderIds` | `alreadyCounted` | "Pesanan ini sudah dihitung untuk misi." |
| 3 | semua tahap sudah selesai | `allStagesDone` | "Semua tahap selesai. Tahap berikutnya menunggu kampanye." |
| 4 | subtotal eligible < min. tahap aktif | `belowThreshold` | "Subtotal Rp60.000, belum mencapai min. Rp75.000" |
| lolos | semua syarat terpenuhi | `issued` (tahap aktif) | "Misi tahap 1 selesai! Voucher Rp10.000 masuk ke Hadiahku" |

- **Satu pesanan dihitung sekali.** Setelah pesanan selesai dinilai, host menyimpan `orderId` ke `countedOrderIds`, apa pun hasilnya (kecuali `notCompleted`). Pesanan yang selesai sebelum suatu tahap terbuka tidak bisa dihitung ulang untuk tahap itu.
- **Satu pesanan menyelesaikan paling banyak satu tahap.** Pesanan Rp200.000 hanya menyelesaikan tahap yang aktif saat itu. Tahap berikutnya butuh pesanan lain.
- Pesanan yang batal atau diretur sebelum Selesai tidak pernah dinilai.
- Sesudah tahap terbit, host memberi umpan balik sesuai SPEC-UIUX §4: suara `unlock`, getar ringan, kartu voucher muncul. Penolakan memakai suara `soft_error` dan pesan pemulihan, misalnya tombol "Belanja sekarang".

### 5.2 Voucher

- **Terbit:** `MissionVoucher.issue(id:, stage:, sourceOrderId:, issuedDay: today)`.
- **Masa berlaku:** voucher bisa dipakai sampai akhir hari (23.59 WIB) `expiresDay = issuedDay + voucherValidDays`. Contoh: terbit 24 Nov 2026 → "Berlaku s.d. 24 Des 2026".
- **Pemakaian (`redeemProblem`)**, diperiksa berurutan:

| Urutan | Masalah | Kapan | Copy checkout (hub) |
|---|---|---|---|
| 1 | `alreadyUsed` | voucher sudah dipakai | "Voucher sudah dipakai" |
| 2 | `expired` | hari ini > `expiresDay` | "Voucher sudah kedaluwarsa" |
| 3 | `sameOrder` | pesanan = pesanan sumber voucher | "Berlaku untuk pesanan berikutnya" |
| 4 | `belowMinimum` | subtotal < `minSpend` | "Belanja Rp8.000 lagi" (selisih `minSpend - subtotal`) |
| lolos | `null` | boleh dipakai | tombol "Pakai" aktif |

- Masalah yang permanen (terpakai, kedaluwarsa) diperiksa lebih dulu, supaya pengguna tidak disuruh "belanja lagi" untuk voucher yang tidak akan pernah bisa dipakai.
- Satu voucher misi per pesanan (Demo). Checkout hanya memilih satu voucher.
- Potongan = nominal voucher. Min. belanja (Rp100.000) selalu lebih besar dari nominal, jadi total barang tidak pernah negatif.
- Setelah dipakai: `markUsed(orderId)` mengembalikan instance baru berstatus Terpakai. Instance lama tidak berubah.
- Status kartu: **Aktif**, **Terpakai**, **Kedaluwarsa**. Terpakai didahulukan bila voucher terpakai sekaligus lewat masa berlaku.

### 5.3 Hari dan tanggal

- `wibDay = (utcMillis + 7*3600*1000) ~/ 86400000`. Host memakai `AppClock` (`wibDayOf(now) + demoOffsetDays`).
- Tanggal kalender: `DateTime.utc(1970, 1, 1).add(Duration(days: wibDay))`. Bulan singkat: Jan Feb Mar Apr Mei Jun Jul Agu Sep Okt Nov Des. Pembaca layar mendengar nama bulan lengkap.

## 6. Antarmuka

Semua widget memakai `Theme.of(context)` saja. Peran warna: `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondaryContainer`, `onSecondaryContainer`, `tertiaryContainer`, `onTertiaryContainer`, `surfaceContainerLowest`, `surfaceContainerLow`, `onSurface`, `onSurfaceVariant`, `outline`, `outlineVariant`. Gaya teks: `titleMedium`, `titleSmall`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `headlineSmall` (nominal w800). Tidak ada warna hardcode. Mode gelap mengikuti ColorScheme host. Widget tidak memiliki animasi, jadi aman untuk preferensi kurangi gerakan.

### 6.1 `MissionLadder`

Timeline vertikal, satu baris per tahap:

| Bagian | Selesai | Aktif | Terkunci |
|---|---|---|---|
| Indikator 32 dp | lingkaran `primary` + ikon centang | cincin `primary` 2 dp + nomor tahap + pendar lembut | lingkaran `outlineVariant` + ikon gembok |
| Garis ke tahap berikutnya | `primary` | `outlineVariant` | `outlineVariant` |
| Chip | "Selesai" | "Aktif" | "Terkunci" |
| Kartu | putih, garis tepi tipis | garis tepi `primary` + bayangan lembut | latar redup, teks `onSurfaceVariant` |

- Isi kartu: "Tahap N" + chip, syarat "Selesaikan 1 pesanan min. Rp75.000", hadiah "Voucher Rp10.000 · min. belanja Rp100.000 · berlaku 30 hari". Tahap terkunci menambah "Terbuka setelah voucher Tahap N-1 terbit".
- `pendingNote` (opsional) tampil hanya di bawah tahap aktif, dalam kotak `tertiaryContainer` dengan ikon truk. Contoh: "Pesanan BP-1002 (Rp120.000) sedang dikirim. Tekan Pesanan Diterima setelah barang sampai."
- Baris akhir yang redup: "Tahap berikutnya menunggu kampanye", atau "Semua tahap selesai. Tahap berikutnya menunggu kampanye." bila semua tahap selesai.
- Aksesibilitas: `MergeSemantics` per tahap, jadi satu tahap dibacakan sebagai satu kalimat. Label pembaca layar memakai "minimal", bukan "min.". Indikator dekoratif dikecualikan dari semantics.
- Teks bisa diperbesar sampai 200% di layar 360 × 740 tanpa terpotong atau overflow. Tidak ada tinggi tetap pada wadah teks.

### 6.2 `VoucherCard`

- Bentuk tiket (CustomClipper) dengan dua takik setengah lingkaran dan garis putus-putus di pembatas.
- Stub: "Voucher" + nominal (`headlineSmall`, `primary`, w800).
- Detail: "Min. belanja Rp100.000", "Berlaku s.d. 24 Des 2026", chip status dengan ikon, dan tombol teks "Pakai" (tinggi min. 48 dp). Tombol hanya muncul bila voucher aktif dan `onUse` diisi.
- Adaptif: bila nominal tidak muat di stub kiri dengan ukuran penuh (teks besar atau layar sempit), stub pindah ke atas. Garis pembatas menjadi mendatar dan takik pindah ke sisi kiri/kanan. Nominal tidak pernah dikecilkan demi tata letak.
- Lebar tak terbatas (mis. carousel horizontal) memakai lebar 340 dp.
- Aksesibilitas: satu kalimat ringkasan, misalnya "Voucher Rp10.000 dari Misi Belanja Tahap 1. Minimal belanja Rp100.000. Berlaku sampai 24 Desember 2026. Status: aktif." Tombol dibacakan "Pakai voucher Rp10.000". Lolos pedoman target sentuh Android dan label target sentuh.

### 6.3 Penempatan di hub (SPEC-UIUX §3)

- **Misi Belanja:** `MissionLadder`, CTA utama "Belanja sekarang", bagian "Voucher saya" berisi `VoucherCard`. Tombol "Cara kerja" membuka aturan §3 sampai §5.
- **Detail produk:** "Belanja min. Rp75.000 untuk voucher Rp10.000".
- **Keranjang:** progres "Tambah Rp12.000 lagi untuk ikut Misi Belanja tahap 1".
- **Checkout:** pilih satu voucher aktif. Voucher yang belum memenuhi syarat tampil abu-abu dengan alasan dari `redeemProblem`.
- **Transaksi:** "Pesanan Diterima" → `evaluateOrder` → lembar hasil (§5.1).
- **Hadiahku:** daftar `VoucherCard` (Aktif / Terpakai / Kedaluwarsa).

## 7. API publik

Satu pintu: `import 'package:misi_belanja/misi_belanja.dart';`. Signature mengikuti SPEC-CONTRACT §2.

```dart
final class MissionStage { const MissionStage({required int number, required int minOrderSubtotal, required int voucherAmount, required int voucherMinSpend, required int voucherValidDays}); }
const List<MissionStage> demoMissionStages; // [1: 75000 -> 10000 min 100000, 2: 100000 -> 5000 min 100000], 30 hari
enum StageStatus { completed, active, locked }
StageStatus stageStatus({required int stageIndex, required int issuedCount});
bool allStagesDone({required List<MissionStage> stages, required int issuedCount});
enum OrderRejection { notCompleted, belowThreshold, alreadyCounted, allStagesDone }
final class MissionDecision { const MissionDecision.issued(MissionStage stage); const MissionDecision.rejected(OrderRejection reason); final MissionStage? issuedStage; final OrderRejection? rejection; bool get issued; }
MissionDecision evaluateOrder({required List<MissionStage> stages, required int issuedCount, required Set<String> countedOrderIds, required String orderId, required int eligibleSubtotal, required bool completed});
final class MissionVoucher {
  const MissionVoucher({required String id, required int stageNumber, required String sourceOrderId, required int amount, required int minSpend, required int issuedDay, required int expiresDay, String? usedOnOrderId});
  factory MissionVoucher.issue({required String id, required MissionStage stage, required String sourceOrderId, required int issuedDay});
  factory MissionVoucher.fromJson(Map<String, Object?> json); // FormatException bila data rusak
  bool get isUsed; bool isExpiredOn(int today); bool isActiveOn(int today);
  MissionVoucher markUsed(String orderId);
  Map<String, Object?> toJson();
}
enum RedeemProblem { belowMinimum, sameOrder, alreadyUsed, expired }
RedeemProblem? redeemProblem({required MissionVoucher voucher, required String orderId, required int subtotal, required int today});
String rupiah(int amount); // Rp0, Rp1.000, Rp1.250.000, -Rp25.000
class MissionLadder extends StatelessWidget { const MissionLadder({Key? key, required List<MissionStage> stages, required int issuedCount, String? pendingNote}); }
class VoucherCard extends StatelessWidget { const VoucherCard({Key? key, required MissionVoucher voucher, required int today, VoidCallback? onUse}); }
```

`MissionStage`, `MissionDecision`, dan `MissionVoucher` immutable dan punya kesetaraan nilai (`==`, `hashCode`).

Contoh alur di hub saat "Pesanan Diterima":

```dart
final MissionDecision decision = evaluateOrder(
  stages: demoMissionStages,
  issuedCount: missionIssuedCount,
  countedOrderIds: countedOrderIds,
  orderId: order.id,
  eligibleSubtotal: order.eligibleSubtotal,
  completed: true,
);
countedOrderIds.add(order.id);
final MissionStage? stage = decision.issuedStage;
if (stage != null) {
  vouchers.add(MissionVoucher.issue(
    id: 'vch-${stage.number}-${order.id}',
    stage: stage,
    sourceOrderId: order.id,
    issuedDay: today,
  ));
  missionIssuedCount += 1;
}
```

## 8. Penyimpanan

Voucher disimpan sebagai JSON di dokumen state host (`bpedia_preview_state_v1`):

```json
{"id":"vch-1-BP-1001","stageNumber":1,"sourceOrderId":"BP-1001","amount":10000,"minSpend":100000,"issuedDay":20781,"expiresDay":20811,"usedOnOrderId":null}
```

`MissionVoucher.fromJson` memeriksa tipe dan nilai: angka harus integer, id tidak kosong, nominal > 0, `expiresDay` tidak sebelum `issuedDay`. Data rusak melempar `FormatException`, sehingga host bisa mulai baru tanpa crash.

## 9. Server referensi (`server/missions.php`)

Cermin aturan Dart untuk backend sungguhan dan simulator PHP hub (PHP 8.2+, `declare(strict_types=1)`):

| Fungsi | Padanan Dart |
|---|---|
| `MISSION_DEMO_STAGES` | `demoMissionStages` |
| `missionEvaluateOrder(...)` | `evaluateOrder` (urutan pemeriksaan sama) |
| `missionStageStatus`, `missionAllStagesDone` | `stageStatus`, `allStagesDone` |
| `missionIssueVoucher(...)` | `MissionVoucher.issue` (kunci JSON sama) |
| `missionRedeemProblem(...)`, `missionVoucherStatus(...)` | `redeemProblem`, status `VoucherCard` |
| `missionRupiah`, `missionWibDay` | `rupiah`, hari WIB |
| `recordDemoOrder(&$state, $subtotal, $order, $completed, ?$today)` | alur §5.1. Mencatat `countedOrders`, menerbitkan voucher. |
| `useDemoVoucher(&$state, $voucherIndex, $subtotal, $order, ?$today)` | alur §5.2 + satu voucher per pesanan |
| `missionSnapshot($state, $today)` | bagian `missions` dan `vouchers` untuk respons `POST /v1/rewards/state` |

Router simulator hub (`../bpedia-kelopak-hub/server/index.php`) memakai berkas ini tanpa diubah dan mengirim `$day` (hari WIB + offset demo) sebagai `$today`, jadi masa berlaku mengikuti kalender demo. Tanpa `$today`, kedua fungsi memakai jam server. Entri voucher format lama (`source`, `minimum`, `spentOn`) tetap terbaca. Backend produksi wajib menambah autentikasi, idempotensi, dan validasi signature webhook sesuai PRD pusat §6.

## 10. Uji penerimaan

| # | Skenario | Bukti |
|---|---|---|
| 1 | Pesanan selesai Rp74.999 → `belowThreshold` | `test/mission_order_test.dart` |
| 2 | Pesanan selesai Rp75.000 → voucher Rp10.000 Tahap 1 | `test/mission_order_test.dart` |
| 3 | Tahap 2: Rp99.999 ditolak, Rp100.000 → voucher Rp5.000 | `test/mission_order_test.dart` |
| 4 | `notCompleted`, `alreadyCounted`, `allStagesDone`, urutan pemeriksaan | `test/mission_order_test.dart` |
| 5 | Pesanan Rp200.000 hanya menyelesaikan satu tahap; dinilai ulang → `alreadyCounted` | `test/mission_order_test.dart` |
| 6 | Tabel `stageStatus` untuk issuedCount 0/1/2 dan `allStagesDone` | `test/mission_stage_test.dart` |
| 7 | `redeemProblem`: sameOrder, belowMinimum di Rp99.999, boleh di Rp100.000 tepat, alreadyUsed, expired bila hari > expiresDay, boleh tepat di expiresDay, urutan pemeriksaan | `test/mission_voucher_test.dart` |
| 8 | JSON pulang-pergi (termasuk `jsonEncode`/`jsonDecode`), data rusak → `FormatException`, `markUsed` mengembalikan instance baru | `test/mission_voucher_test.dart` |
| 9 | `rupiah`: Rp0, Rp1.000, Rp1.250.000, -Rp25.000, dst. | `test/rupiah_test.dart` |
| 10 | Tanggal WIB & bulan Indonesia ("24 Des 2026") | `test/wib_date_test.dart` |
| 11 | Ladder: chip benar untuk issuedCount 0/1/2, warna garis, `pendingNote` hanya di tahap aktif, `MergeSemantics` per tahap, kontras teks | `test/mission_ladder_test.dart` |
| 12 | VoucherCard: Aktif / Terpakai / Kedaluwarsa, "Pakai" hanya saat aktif, target 48 dp, kalimat semantics, layout adaptif | `test/voucher_card_test.dart` |
| 13 | Tanpa overflow pada teks 200% di 360 × 740, juga 320 dp mode gelap | `test/mission_ladder_test.dart`, `test/voucher_card_test.dart` |
| 14 | Takik tiket dan garis pembatas | `test/ticket_shape_test.dart` |
| 15 | Server: `php -l` bersih; alur tahap, voucher, dan format lama sesuai tabel §5 | `server/missions.php` |

Perintah:

```bash
flutter pub get
flutter analyze      # No issues found!
flutter test         # semua lulus
php -l server/missions.php
```

## 11. Keputusan terbuka (perlu persetujuan owner)

1. Nominal, syarat, dan masa berlaku produksi untuk Tahap 2 dan seterusnya. Demo: Rp5.000, min. Rp100.000, 30 hari.
2. Apakah potongan Kelopak mengurangi subtotal eligible. Demo: tidak, dihitung sebelum Kelopak.
3. Voucher yang dipakai lalu pesanannya batal atau diretur: dikembalikan atau hangus.
4. Pesanan sumber voucher yang diretur setelah Selesai: voucher ditarik atau tetap.
5. Boleh atau tidaknya voucher misi digabung dengan promo lain. Demo: satu voucher misi per pesanan.
6. Kampanye lanjutan setelah tahap terakhir dan cara mengumumkannya.

## 12. Riwayat

- **v1.0 (24 Nov 2026):** PRD awal, dua tahap, fungsi `qualifies`/`mayRedeem`, widget `ShoppingMissions`, uji dasar.
- **v2.0 (24 Nov 2026):**
  - API v2 sesuai SPEC-CONTRACT §2: `MissionStage`, `evaluateOrder` + `MissionDecision`, `MissionVoucher` (JSON, `markUsed`), `redeemProblem`, `rupiah`.
  - Urutan pemeriksaan dan definisi subtotal eligible ditetapkan. Masa berlaku 30 hari (Demo).
  - Widget baru `MissionLadder` dan `VoucherCard`: tiket adaptif, aman pada teks 200%, semantics lengkap.
  - Istilah "Tercapai" diganti "Selesai", "Uji voucher" diganti "Pakai".
  - Server referensi diselaraskan: pencatatan pesanan sekali, voucher hanya untuk pesanan lain, snapshot status.
  - Uji penerimaan diperluas.
