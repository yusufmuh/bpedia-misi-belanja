import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

MissionDecision _evaluate({
  int issuedCount = 0,
  Set<String> counted = const <String>{},
  String orderId = 'BP-1001',
  required int subtotal,
  bool completed = true,
}) => evaluateOrder(
  stages: demoMissionStages,
  issuedCount: issuedCount,
  countedOrderIds: counted,
  orderId: orderId,
  eligibleSubtotal: subtotal,
  completed: completed,
);

void main() {
  group('evaluateOrder · tahap 1', () {
    test('Rp74.999 ditolak: belowThreshold', () {
      final MissionDecision decision = _evaluate(subtotal: 74999);
      expect(decision.issued, isFalse);
      expect(decision.issuedStage, isNull);
      expect(decision.rejection, OrderRejection.belowThreshold);
    });

    test('Rp75.000 tepat menerbitkan voucher tahap 1', () {
      final MissionDecision decision = _evaluate(subtotal: 75000);
      expect(decision.issued, isTrue);
      expect(decision.rejection, isNull);
      expect(decision.issuedStage, demoMissionStages[0]);
      expect(decision.issuedStage?.voucherAmount, 10000);
    });
  });

  group('evaluateOrder · tahap 2', () {
    test('Rp99.999 ditolak setelah voucher tahap 1 terbit', () {
      final MissionDecision decision = _evaluate(
        issuedCount: 1,
        counted: const <String>{'BP-1001'},
        orderId: 'BP-1002',
        subtotal: 99999,
      );
      expect(decision.rejection, OrderRejection.belowThreshold);
      expect(decision.issued, isFalse);
    });

    test('Rp100.000 tepat menerbitkan voucher tahap 2', () {
      final MissionDecision decision = _evaluate(
        issuedCount: 1,
        counted: const <String>{'BP-1001'},
        orderId: 'BP-1002',
        subtotal: 100000,
      );
      expect(decision.issuedStage, demoMissionStages[1]);
      expect(decision.issuedStage?.voucherAmount, 5000);
    });
  });

  group('evaluateOrder · penolakan', () {
    test('pesanan belum selesai: notCompleted', () {
      final MissionDecision decision = _evaluate(
        subtotal: 500000,
        completed: false,
      );
      expect(decision.rejection, OrderRejection.notCompleted);
    });

    test('pesanan yang sudah dihitung: alreadyCounted', () {
      final MissionDecision decision = _evaluate(
        counted: const <String>{'BP-1001'},
        subtotal: 150000,
      );
      expect(decision.rejection, OrderRejection.alreadyCounted);
    });

    test('semua tahap selesai: allStagesDone', () {
      final MissionDecision decision = _evaluate(
        issuedCount: 2,
        orderId: 'BP-1003',
        subtotal: 250000,
      );
      expect(decision.rejection, OrderRejection.allStagesDone);
    });

    test('satu pesanan besar hanya menyelesaikan satu tahap', () {
      final MissionDecision first = _evaluate(subtotal: 200000);
      expect(first.issuedStage?.number, 1);

      final MissionDecision replay = _evaluate(
        issuedCount: 1,
        counted: const <String>{'BP-1001'},
        subtotal: 200000,
      );
      expect(replay.rejection, OrderRejection.alreadyCounted);
    });

    test('urutan pemeriksaan: notCompleted, alreadyCounted, allStagesDone, '
        'belowThreshold', () {
      expect(
        _evaluate(
          issuedCount: 2,
          counted: const <String>{'BP-1001'},
          subtotal: 1,
          completed: false,
        ).rejection,
        OrderRejection.notCompleted,
      );
      expect(
        _evaluate(
          issuedCount: 2,
          counted: const <String>{'BP-1001'},
          subtotal: 1,
        ).rejection,
        OrderRejection.alreadyCounted,
      );
      expect(
        _evaluate(issuedCount: 2, subtotal: 1).rejection,
        OrderRejection.allStagesDone,
      );
    });
  });

  group('MissionDecision', () {
    test('kesetaraan nilai', () {
      expect(
        MissionDecision.issued(demoMissionStages[0]),
        MissionDecision.issued(demoMissionStages[0]),
      );
      expect(
        const MissionDecision.rejected(OrderRejection.belowThreshold),
        isNot(const MissionDecision.rejected(OrderRejection.notCompleted)),
      );
    });
  });
}
