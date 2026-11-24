import 'package:flutter/foundation.dart';

import 'mission_stage.dart';

/// Why a completed-order evaluation did not issue a voucher.
enum OrderRejection {
  /// The order has not reached the completed ("Selesai") state.
  notCompleted,

  /// The eligible subtotal is below the active stage minimum.
  belowThreshold,

  /// The order was already evaluated; one order is counted once.
  alreadyCounted,

  /// Every stage has issued its voucher; the next stage awaits a campaign.
  allStagesDone,
}

/// Outcome of [evaluateOrder]. Exactly one of [issuedStage] and [rejection]
/// is non-null.
@immutable
final class MissionDecision {
  /// The order completed [stage]; its voucher should be issued.
  const MissionDecision.issued(MissionStage stage)
    : issuedStage = stage,
      rejection = null;

  /// The order did not complete a stage, for [reason].
  const MissionDecision.rejected(OrderRejection reason)
    : issuedStage = null,
      rejection = reason;

  /// Stage completed by the order, or null when rejected.
  final MissionStage? issuedStage;

  /// Reason the order did not count, or null when a stage was completed.
  final OrderRejection? rejection;

  /// Whether a stage voucher should be issued.
  bool get issued => issuedStage != null;

  @override
  bool operator ==(Object other) =>
      other is MissionDecision &&
      other.issuedStage == issuedStage &&
      other.rejection == rejection;

  @override
  int get hashCode => Object.hash(issuedStage, rejection);

  @override
  String toString() => issued
      ? 'MissionDecision.issued(stage ${issuedStage?.number})'
      : 'MissionDecision.rejected(${rejection?.name})';
}

/// Evaluates one order against the active stage.
///
/// [issuedCount] is the number of stage vouchers issued so far, so the active
/// stage is `stages[issuedCount]`. [eligibleSubtotal] is the product subtotal
/// after product discounts, before shipping, fees, mission vouchers and
/// Kelopak. Checks run in this order: [OrderRejection.notCompleted],
/// [OrderRejection.alreadyCounted], [OrderRejection.allStagesDone],
/// [OrderRejection.belowThreshold]. One order completes at most one stage;
/// the host stores [orderId] in [countedOrderIds] once the order is completed
/// and evaluated, whatever the outcome.
MissionDecision evaluateOrder({
  required List<MissionStage> stages,
  required int issuedCount,
  required Set<String> countedOrderIds,
  required String orderId,
  required int eligibleSubtotal,
  required bool completed,
}) {
  assert(issuedCount >= 0, 'issuedCount must not be negative');
  assert(orderId.isNotEmpty, 'orderId must not be empty');
  if (!completed) {
    return const MissionDecision.rejected(OrderRejection.notCompleted);
  }
  if (countedOrderIds.contains(orderId)) {
    return const MissionDecision.rejected(OrderRejection.alreadyCounted);
  }
  final int activeIndex = issuedCount < 0 ? 0 : issuedCount;
  if (allStagesDone(stages: stages, issuedCount: activeIndex)) {
    return const MissionDecision.rejected(OrderRejection.allStagesDone);
  }
  final MissionStage stage = stages[activeIndex];
  if (eligibleSubtotal < stage.minOrderSubtotal) {
    return const MissionDecision.rejected(OrderRejection.belowThreshold);
  }
  return MissionDecision.issued(stage);
}
