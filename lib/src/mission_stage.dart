import 'package:flutter/foundation.dart';

/// One step of the tiered shopping mission.
///
/// All amounts are whole rupiah. A completed order whose eligible subtotal is
/// at least [minOrderSubtotal] issues a voucher of [voucherAmount] that can be
/// used on a later, different order of at least [voucherMinSpend], for
/// [voucherValidDays] WIB days after the day it was issued.
///
/// Bila [productCodes] diisi, yang dihitung hanya subtotal produk misi
/// (lihat `missionSubtotal`); bila kosong, semua produk dihitung.
@immutable
final class MissionStage {
  /// Creates a stage. [number] starts at 1.
  const MissionStage({
    required this.number,
    required this.minOrderSubtotal,
    required this.voucherAmount,
    required this.voucherMinSpend,
    required this.voucherValidDays,
    String? id,
    String? title,
    this.productCodes = const <String>[],
  }) : _id = id,
       _title = title,
       assert(number >= 1, 'number starts at 1'),
       assert(minOrderSubtotal >= 0, 'minOrderSubtotal must not be negative'),
       assert(voucherAmount > 0, 'voucherAmount must be positive'),
       assert(voucherMinSpend >= 0, 'voucherMinSpend must not be negative'),
       assert(voucherValidDays > 0, 'voucherValidDays must be positive');

  /// Stage number shown to the user ("Tahap 1").
  final int number;

  /// Minimum eligible subtotal of one completed order, in rupiah.
  final int minOrderSubtotal;

  /// Voucher value issued when the stage completes, in rupiah.
  final int voucherAmount;

  /// Minimum subtotal of the order that redeems the voucher, in rupiah.
  final int voucherMinSpend;

  /// Number of WIB days the voucher stays valid after its issue day.
  final int voucherValidDays;

  /// Kode produk misi tahap ini. Kosong = semua produk dihitung.
  final List<String> productCodes;

  final String? _id;
  final String? _title;

  /// ID tahap yang stabil untuk penyimpanan dan server; tanpa nilai
  /// eksplisit: `tahap-1`, `tahap-2`, dan seterusnya.
  String get id => _id ?? 'tahap-$number';

  /// Judul tahap di layar; tanpa nilai eksplisit: "Tahap 1".
  String get title => _title ?? 'Tahap $number';

  /// Apakah semua produk dihitung (tidak ada daftar produk misi).
  bool get countsAllProducts => productCodes.isEmpty;

  /// Apakah produk [productCode] dihitung untuk tahap ini.
  bool countsProduct(String productCode) =>
      productCodes.isEmpty || productCodes.contains(productCode);

  @override
  bool operator ==(Object other) =>
      other is MissionStage &&
      other.number == number &&
      other.minOrderSubtotal == minOrderSubtotal &&
      other.voucherAmount == voucherAmount &&
      other.voucherMinSpend == voucherMinSpend &&
      other.voucherValidDays == voucherValidDays &&
      other.id == id &&
      other.title == title &&
      listEquals(other.productCodes, productCodes);

  @override
  int get hashCode => Object.hash(
    number,
    minOrderSubtotal,
    voucherAmount,
    voucherMinSpend,
    voucherValidDays,
    id,
    title,
    Object.hashAll(productCodes),
  );

  @override
  String toString() =>
      'MissionStage(number: $number, id: $id, title: $title, '
      'minOrderSubtotal: $minOrderSubtotal, '
      'voucherAmount: $voucherAmount, voucherMinSpend: $voucherMinSpend, '
      'voucherValidDays: $voucherValidDays, productCodes: $productCodes)';
}

/// Kampanye contoh v3: tahap 1 (min. Rp75.000 -> voucher Rp10.000, min.
/// belanja Rp100.000) dan tahap 2 (nilai demo: min. Rp100.000 -> voucher
/// Rp15.000, min. belanja Rp150.000), masing-masing berlaku 30 hari.
/// Daftar produk misi sengaja kosong; host yang mengisinya.
const List<MissionStage> demoMissionStages = <MissionStage>[
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
    voucherAmount: 15000,
    voucherMinSpend: 150000,
    voucherValidDays: 30,
  ),
];

/// Progress state of a stage relative to the number of vouchers issued.
enum StageStatus {
  /// The stage voucher has been issued.
  completed,

  /// The next completed order is evaluated against this stage.
  active,

  /// Opens after the voucher of the previous stage is issued.
  locked,
}

/// Status of the stage at zero-based [stageIndex] when [issuedCount] stage
/// vouchers have been issued so far.
StageStatus stageStatus({required int stageIndex, required int issuedCount}) {
  assert(stageIndex >= 0, 'stageIndex must not be negative');
  assert(issuedCount >= 0, 'issuedCount must not be negative');
  if (stageIndex < issuedCount) {
    return StageStatus.completed;
  }
  if (stageIndex == issuedCount) {
    return StageStatus.active;
  }
  return StageStatus.locked;
}

/// Whether every stage in [stages] has issued its voucher.
bool allStagesDone({
  required List<MissionStage> stages,
  required int issuedCount,
}) => issuedCount >= stages.length;
