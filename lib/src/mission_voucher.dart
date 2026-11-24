import 'package:flutter/foundation.dart';

import 'mission_stage.dart';

/// A voucher issued by a completed mission stage.
///
/// Days are WIB day numbers (days since 1 Jan 1970 in UTC+7). The voucher can
/// be used up to and including [expiresDay].
@immutable
final class MissionVoucher {
  /// Creates a voucher record.
  const MissionVoucher({
    required this.id,
    required this.stageNumber,
    required this.sourceOrderId,
    required this.amount,
    required this.minSpend,
    required this.issuedDay,
    required this.expiresDay,
    this.usedOnOrderId,
  });

  /// Issues the voucher of [stage] for [sourceOrderId] on [issuedDay];
  /// it stays valid through `issuedDay + stage.voucherValidDays`.
  factory MissionVoucher.issue({
    required String id,
    required MissionStage stage,
    required String sourceOrderId,
    required int issuedDay,
  }) => MissionVoucher(
    id: id,
    stageNumber: stage.number,
    sourceOrderId: sourceOrderId,
    amount: stage.voucherAmount,
    minSpend: stage.voucherMinSpend,
    issuedDay: issuedDay,
    expiresDay: issuedDay + stage.voucherValidDays,
  );

  /// Reads a voucher written by [toJson].
  ///
  /// Throws a [FormatException] when a field is missing, has the wrong type or
  /// holds an impossible value.
  factory MissionVoucher.fromJson(Map<String, Object?> json) {
    final MissionVoucher voucher = MissionVoucher(
      id: _readText(json, 'id'),
      stageNumber: _readInt(json, 'stageNumber'),
      sourceOrderId: _readText(json, 'sourceOrderId'),
      amount: _readInt(json, 'amount'),
      minSpend: _readInt(json, 'minSpend'),
      issuedDay: _readInt(json, 'issuedDay'),
      expiresDay: _readInt(json, 'expiresDay'),
      usedOnOrderId: _readOptionalText(json, 'usedOnOrderId'),
    );
    if (voucher.stageNumber < 1 ||
        voucher.amount <= 0 ||
        voucher.minSpend < 0 ||
        voucher.expiresDay < voucher.issuedDay) {
      throw FormatException('MissionVoucher has impossible values', json);
    }
    return voucher;
  }

  /// Unique voucher id.
  final String id;

  /// Number of the stage that issued the voucher.
  final int stageNumber;

  /// Order that completed the stage; the voucher cannot be used on it.
  final String sourceOrderId;

  /// Discount value in rupiah.
  final int amount;

  /// Minimum subtotal of the redeeming order, in rupiah.
  final int minSpend;

  /// WIB day the voucher was issued.
  final int issuedDay;

  /// Last WIB day the voucher can be used.
  final int expiresDay;

  /// Order the voucher was used on, or null while unused.
  final String? usedOnOrderId;

  /// Whether the voucher has been used on an order.
  bool get isUsed => usedOnOrderId != null;

  /// Whether [today] is past [expiresDay].
  bool isExpiredOn(int today) => today > expiresDay;

  /// Whether the voucher is unused and not expired on [today].
  bool isActiveOn(int today) => !isUsed && !isExpiredOn(today);

  /// Returns a copy recorded as used on [orderId]; this instance is unchanged.
  MissionVoucher markUsed(String orderId) {
    assert(!isUsed, 'Voucher $id was already used on $usedOnOrderId');
    assert(orderId.isNotEmpty, 'orderId must not be empty');
    return MissionVoucher(
      id: id,
      stageNumber: stageNumber,
      sourceOrderId: sourceOrderId,
      amount: amount,
      minSpend: minSpend,
      issuedDay: issuedDay,
      expiresDay: expiresDay,
      usedOnOrderId: orderId,
    );
  }

  /// JSON-safe map; [MissionVoucher.fromJson] reads it back.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'stageNumber': stageNumber,
    'sourceOrderId': sourceOrderId,
    'amount': amount,
    'minSpend': minSpend,
    'issuedDay': issuedDay,
    'expiresDay': expiresDay,
    'usedOnOrderId': usedOnOrderId,
  };

  @override
  bool operator ==(Object other) =>
      other is MissionVoucher &&
      other.id == id &&
      other.stageNumber == stageNumber &&
      other.sourceOrderId == sourceOrderId &&
      other.amount == amount &&
      other.minSpend == minSpend &&
      other.issuedDay == issuedDay &&
      other.expiresDay == expiresDay &&
      other.usedOnOrderId == usedOnOrderId;

  @override
  int get hashCode => Object.hash(
    id,
    stageNumber,
    sourceOrderId,
    amount,
    minSpend,
    issuedDay,
    expiresDay,
    usedOnOrderId,
  );

  @override
  String toString() =>
      'MissionVoucher(id: $id, stageNumber: $stageNumber, '
      'sourceOrderId: $sourceOrderId, amount: $amount, minSpend: $minSpend, '
      'issuedDay: $issuedDay, expiresDay: $expiresDay, '
      'usedOnOrderId: $usedOnOrderId)';
}

/// Why a voucher cannot be applied to an order.
enum RedeemProblem {
  /// The order subtotal is below [MissionVoucher.minSpend].
  belowMinimum,

  /// The order is the one that issued the voucher.
  sameOrder,

  /// The voucher was already used.
  alreadyUsed,

  /// Today is past [MissionVoucher.expiresDay].
  expired,
}

/// Returns why [voucher] cannot be used on [orderId] with [subtotal] on
/// [today], or null when it can.
///
/// Checks run in this order: [RedeemProblem.alreadyUsed],
/// [RedeemProblem.expired], [RedeemProblem.sameOrder],
/// [RedeemProblem.belowMinimum]. [subtotal] uses the same definition as the
/// mission eligible subtotal (products after product discounts, before
/// shipping, fees, vouchers and Kelopak).
RedeemProblem? redeemProblem({
  required MissionVoucher voucher,
  required String orderId,
  required int subtotal,
  required int today,
}) {
  if (voucher.isUsed) {
    return RedeemProblem.alreadyUsed;
  }
  if (voucher.isExpiredOn(today)) {
    return RedeemProblem.expired;
  }
  if (orderId == voucher.sourceOrderId) {
    return RedeemProblem.sameOrder;
  }
  if (subtotal < voucher.minSpend) {
    return RedeemProblem.belowMinimum;
  }
  return null;
}

String _readText(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException(
    'MissionVoucher.$key must be a non-empty string',
    value,
  );
}

String? _readOptionalText(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException(
    'MissionVoucher.$key must be null or a non-empty string',
    value,
  );
}

int _readInt(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('MissionVoucher.$key must be an integer', value);
}
