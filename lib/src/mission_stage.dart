import 'package:flutter/foundation.dart';

/// One step of the tiered shopping mission.
///
/// All amounts are whole rupiah. A completed order whose eligible subtotal is
/// at least [minOrderSubtotal] issues a voucher of [voucherAmount] that can be
/// used on a later, different order of at least [voucherMinSpend], for
/// [voucherValidDays] WIB days after the day it was issued.
@immutable
final class MissionStage {
  /// Creates a stage. [number] starts at 1.
  const MissionStage({
    required this.number,
    required this.minOrderSubtotal,
    required this.voucherAmount,
    required this.voucherMinSpend,
    required this.voucherValidDays,
  }) : assert(number >= 1, 'number starts at 1'),
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

  @override
  bool operator ==(Object other) =>
      other is MissionStage &&
      other.number == number &&
      other.minOrderSubtotal == minOrderSubtotal &&
      other.voucherAmount == voucherAmount &&
      other.voucherMinSpend == voucherMinSpend &&
      other.voucherValidDays == voucherValidDays;

  @override
  int get hashCode => Object.hash(
    number,
    minOrderSubtotal,
    voucherAmount,
    voucherMinSpend,
    voucherValidDays,
  );

  @override
  String toString() =>
      'MissionStage(number: $number, minOrderSubtotal: $minOrderSubtotal, '
      'voucherAmount: $voucherAmount, voucherMinSpend: $voucherMinSpend, '
      'voucherValidDays: $voucherValidDays)';
}

/// Demo campaign: stage 1 (min. Rp75.000 -> Rp10.000) and stage 2
/// (min. Rp100.000 -> Rp5.000), both redeemable from Rp100.000, 30 days.
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
    voucherAmount: 5000,
    voucherMinSpend: 100000,
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
