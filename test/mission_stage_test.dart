import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

void main() {
  group('demoMissionStages', () {
    test('tahap 1: min. Rp75.000 -> voucher Rp10.000, min. belanja '
        'Rp100.000, 30 hari', () {
      expect(
        demoMissionStages.first,
        const MissionStage(
          number: 1,
          minOrderSubtotal: 75000,
          voucherAmount: 10000,
          voucherMinSpend: 100000,
          voucherValidDays: 30,
        ),
      );
    });

    test('tahap 2 (demo v3): min. Rp100.000 -> voucher Rp15.000, min. belanja '
        'Rp150.000, 30 hari', () {
      expect(demoMissionStages, hasLength(2));
      expect(
        demoMissionStages[1],
        const MissionStage(
          number: 2,
          minOrderSubtotal: 100000,
          voucherAmount: 15000,
          voucherMinSpend: 150000,
          voucherValidDays: 30,
        ),
      );
    });
  });

  group('stageStatus', () {
    const Map<int, List<StageStatus>> table = <int, List<StageStatus>>{
      0: <StageStatus>[StageStatus.active, StageStatus.locked],
      1: <StageStatus>[StageStatus.completed, StageStatus.active],
      2: <StageStatus>[StageStatus.completed, StageStatus.completed],
    };

    table.forEach((int issuedCount, List<StageStatus> expected) {
      test('issuedCount $issuedCount -> $expected', () {
        for (int index = 0; index < expected.length; index++) {
          expect(
            stageStatus(stageIndex: index, issuedCount: issuedCount),
            expected[index],
            reason: 'stageIndex $index',
          );
        }
      });
    });

    test('tahap ketiga tetap terkunci saat tahap 1 masih aktif', () {
      expect(stageStatus(stageIndex: 2, issuedCount: 0), StageStatus.locked);
    });
  });

  group('allStagesDone', () {
    test('false sampai semua voucher tahap terbit', () {
      expect(allStagesDone(stages: demoMissionStages, issuedCount: 0), isFalse);
      expect(allStagesDone(stages: demoMissionStages, issuedCount: 1), isFalse);
      expect(allStagesDone(stages: demoMissionStages, issuedCount: 2), isTrue);
      expect(allStagesDone(stages: demoMissionStages, issuedCount: 3), isTrue);
    });

    test('kampanye tanpa tahap tidak menyisakan tahap aktif', () {
      expect(
        allStagesDone(stages: const <MissionStage>[], issuedCount: 0),
        isTrue,
      );
    });
  });
}
