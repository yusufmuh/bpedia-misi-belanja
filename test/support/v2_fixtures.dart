import 'package:misi_belanja/misi_belanja.dart';

/// Kampanye demo v2 (tahap 2: voucher Rp5.000, min. belanja Rp100.000).
/// Tes aturan v2 memakainya supaya asersi lama tetap berlaku setelah
/// `demoMissionStages` berisi nilai v3.
const List<MissionStage> v2MissionStages = <MissionStage>[
  MissionStage(
    number: 1,
    minOrderSubtotal: 75000,
    voucherAmount: 10000,
    voucherMinSpend: 100000,
    voucherValidDays: 30,
  ),
  MissionStage(
    number: 2,
    minOrderSubtotal: 100000,
    voucherAmount: 5000,
    voucherMinSpend: 100000,
    voucherValidDays: 30,
  ),
];
