# misi_belanja · Misi Belanja Bertahap

Paket Flutter 2.0.0 untuk **Bpedia Preview**. Isinya:

- aturan Misi Belanja: tahap, penilaian pesanan selesai, voucher, masa berlaku;
- formatter `rupiah`;
- dua widget: `MissionLadder` (tangga tahap) dan `VoucherCard` (kartu voucher berbentuk tiket).

Hub `bpedia-kelopak-hub` memakai paket ini lewat path dependency. Spesifikasi lengkap ada di [PRD.md](PRD.md). Kontrak lintas modul ada di `../bpedia-kelopak-hub/docs/SPEC-CONTRACT.md` §2.

## Aturan singkat

| Tahap | Syarat: 1 pesanan selesai | Hadiah | Pakai voucher |
|---|---|---|---|
| 1 | subtotal min. Rp75.000 | Voucher Rp10.000 | pesanan lain, min. belanja Rp100.000, 30 hari (Demo) |
| 2 (Demo) | subtotal min. Rp100.000 | Voucher Rp5.000 | pesanan lain, min. belanja Rp100.000, 30 hari (Demo) |

- Tahap berikutnya terbuka saat voucher tahap sebelumnya terbit.
- Satu pesanan dihitung sekali dan menyelesaikan paling banyak satu tahap.
- Voucher tidak bisa dipakai di pesanan yang menerbitkannya.

## Pemasangan

```yaml
dependencies:
  misi_belanja:
    path: ../bpedia-misi-belanja
```

Lingkungan: Dart `^3.11.0`, Flutter `>=3.41.0`. Tidak ada dependensi pihak ketiga.

## Pemakaian

```dart
import 'package:misi_belanja/misi_belanja.dart';

// Saat pesanan berubah menjadi Selesai ("Pesanan Diterima").
final MissionDecision decision = evaluateOrder(
  stages: demoMissionStages,
  issuedCount: missionIssuedCount,
  countedOrderIds: countedOrderIds,
  orderId: order.id,
  eligibleSubtotal: order.eligibleSubtotal,
  completed: true,
);
countedOrderIds.add(order.id); // satu pesanan dihitung sekali, apa pun hasilnya
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

// Checkout: alasan voucher belum bisa dipakai (null = boleh).
final RedeemProblem? problem = redeemProblem(
  voucher: voucher,
  orderId: checkoutOrderId,
  subtotal: eligibleSubtotal,
  today: today,
);

// UI
MissionLadder(
  stages: demoMissionStages,
  issuedCount: missionIssuedCount,
  pendingNote: 'Pesanan BP-1002 (Rp120.000) sedang dikirim. Tekan Pesanan Diterima setelah barang sampai.',
);
VoucherCard(voucher: voucher, today: today, onUse: () => applyVoucher(voucher));
```

`MissionVoucher.toJson()` / `MissionVoucher.fromJson()` dipakai untuk penyimpanan. Data rusak melempar `FormatException`.

## API

| Simbol | Fungsi |
|---|---|
| `MissionStage`, `demoMissionStages` | konfigurasi tahap (nominal rupiah, masa berlaku hari) |
| `StageStatus`, `stageStatus()`, `allStagesDone()` | status Selesai / Aktif / Terkunci |
| `OrderRejection`, `MissionDecision`, `evaluateOrder()` | penilaian pesanan selesai |
| `MissionVoucher` (`issue`, `fromJson`, `toJson`, `markUsed`, `isUsed`, `isExpiredOn`, `isActiveOn`) | data voucher |
| `RedeemProblem`, `redeemProblem()` | syarat pakai voucher |
| `rupiah()` | `Rp0`, `Rp1.000`, `Rp1.250.000`, `-Rp25.000` |
| `MissionLadder` | timeline tahap + baris "Tahap berikutnya menunggu kampanye" |
| `VoucherCard` | tiket voucher Aktif / Terpakai / Kedaluwarsa + tombol "Pakai" |

Urutan pemeriksaan, definisi subtotal eligible, dan copy hasil ada di PRD §4 dan §5.

## Tema dan aksesibilitas

- Warna dan gaya teks hanya dari `Theme.of(context)` (ColorScheme + TextTheme host). Mode gelap ikut otomatis.
- Teks bisa diperbesar sampai 200% tanpa overflow. `VoucherCard` memindahkan stub ke atas bila nominal tidak muat.
- `MergeSemantics` per tahap; satu kalimat ringkasan per voucher; tombol "Pakai" berlabel dan tingginya min. 48 dp.
- Teks UI tanpa glyph `≥ → ✓` (font brand tidak punya); syarat ditulis "min.".

## Pengembangan

```bash
flutter pub get
flutter analyze      # No issues found!
flutter test
php -l server/missions.php
```

Struktur:

```
lib/misi_belanja.dart          satu-satunya pintu API publik
lib/src/mission_stage.dart     MissionStage, StageStatus, demoMissionStages
lib/src/mission_order.dart     evaluateOrder, MissionDecision, OrderRejection
lib/src/mission_voucher.dart   MissionVoucher, redeemProblem, RedeemProblem
lib/src/rupiah.dart            formatter rupiah
lib/src/wib_date.dart          tanggal WIB berbahasa Indonesia (internal)
lib/src/widgets/               MissionLadder, VoucherCard, bentuk tiket, chip status
test/                          uji unit + widget (lihat PRD §10)
server/missions.php            server referensi PHP 8.2+ dengan aturan yang sama
```

Mode Demo: semua data di perangkat, tanpa backend. Prototipe clean-room, tidak memakai kode atau aset APK produksi.
