import 'package:flutter/foundation.dart';

import 'mission_order.dart';
import 'mission_stage.dart';

/// Satu baris pesanan atau keranjang: [quantity] buah produk [productCode]
/// seharga [unitPrice] rupiah per buah (setelah diskon produk).
@immutable
final class MissionOrderLine {
  const MissionOrderLine({
    required this.productCode,
    required this.unitPrice,
    required this.quantity,
  }) : assert(unitPrice >= 0, 'unitPrice must not be negative'),
       assert(quantity >= 0, 'quantity must not be negative');

  final String productCode;
  final int unitPrice;
  final int quantity;

  /// Harga x jumlah. Baris dengan harga atau jumlah yang tidak positif
  /// bernilai 0, jadi data rusak tidak pernah mengurangi subtotal.
  int get total => unitPrice > 0 && quantity > 0 ? unitPrice * quantity : 0;

  @override
  bool operator ==(Object other) =>
      other is MissionOrderLine &&
      other.productCode == productCode &&
      other.unitPrice == unitPrice &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(productCode, unitPrice, quantity);

  @override
  String toString() => 'MissionOrderLine($productCode, $unitPrice x $quantity)';
}

/// Subtotal yang dihitung untuk [stage]: jumlah harga x jumlah dari baris
/// yang produknya termasuk produk misi tahap itu. Bila
/// [MissionStage.productCodes] kosong, semua baris dihitung.
int missionSubtotal(MissionStage stage, Iterable<MissionOrderLine> lines) {
  int subtotal = 0;
  for (final MissionOrderLine line in lines) {
    if (stage.countsProduct(line.productCode)) subtotal += line.total;
  }
  return subtotal;
}

/// Padanan [evaluateOrder] untuk pesanan berisi [lines]: subtotal yang
/// dinilai adalah subtotal produk misi tahap aktif ([missionSubtotal]).
/// Urutan pemeriksaan dan hasilnya sama dengan [evaluateOrder]; satu pesanan
/// menyelesaikan paling banyak satu tahap.
MissionDecision evaluateOrderLines({
  required List<MissionStage> stages,
  required int issuedCount,
  required Set<String> countedOrderIds,
  required String orderId,
  required Iterable<MissionOrderLine> lines,
  required bool completed,
}) {
  final int activeIndex = issuedCount < 0 ? 0 : issuedCount;
  return evaluateOrder(
    stages: stages,
    issuedCount: issuedCount,
    countedOrderIds: countedOrderIds,
    orderId: orderId,
    eligibleSubtotal: activeIndex < stages.length
        ? missionSubtotal(stages[activeIndex], lines)
        : 0,
    completed: completed,
  );
}

/// Kemajuan satu tahap untuk isi keranjang atau pesanan tertentu.
@immutable
final class MissionProgress {
  const MissionProgress({required this.current, required this.target});

  /// Subtotal produk misi saat ini, dalam rupiah.
  final int current;

  /// Subtotal minimal tahap ([MissionStage.minOrderSubtotal]).
  final int target;

  /// Kekurangan sampai [target]; 0 bila sudah tercapai.
  int get remaining => current >= target ? 0 : target - current;

  /// Apakah [current] sudah mencapai [target].
  bool get reached => current >= target;

  /// Bagian yang sudah terisi untuk bar progres, 0..1.
  double get fraction =>
      target <= 0 || current >= target ? 1 : current / target;

  @override
  bool operator ==(Object other) =>
      other is MissionProgress &&
      other.current == current &&
      other.target == target;

  @override
  int get hashCode => Object.hash(current, target);

  @override
  String toString() => 'MissionProgress($current / $target)';
}

/// Kemajuan [stage] bila [lines] dipesan dalam satu pesanan.
MissionProgress missionProgress(
  MissionStage stage,
  Iterable<MissionOrderLine> lines,
) => MissionProgress(
  current: missionSubtotal(stage, lines),
  target: stage.minOrderSubtotal,
);
