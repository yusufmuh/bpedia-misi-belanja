import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

const MissionStage serumStage = MissionStage(
  number: 1,
  id: 'nov-serum',
  title: 'Paket serum',
  minOrderSubtotal: 75000,
  voucherAmount: 10000,
  voucherMinSpend: 100000,
  voucherValidDays: 30,
  productCodes: <String>['SERUM-A', 'TONER-B'],
);

const MissionStage maskStage = MissionStage(
  number: 2,
  minOrderSubtotal: 100000,
  voucherAmount: 15000,
  voucherMinSpend: 150000,
  voucherValidDays: 30,
  productCodes: <String>['MASKER-C'],
);

const List<MissionStage> productStages = <MissionStage>[serumStage, maskStage];

MissionOrderLine line(String code, int unitPrice, [int quantity = 1]) =>
    MissionOrderLine(
      productCode: code,
      unitPrice: unitPrice,
      quantity: quantity,
    );

MissionDecision evaluateLines(
  List<MissionOrderLine> lines, {
  List<MissionStage> stages = productStages,
  int issuedCount = 0,
  Set<String> counted = const <String>{},
  String orderId = 'BP-2001',
  bool completed = true,
}) => evaluateOrderLines(
  stages: stages,
  issuedCount: issuedCount,
  countedOrderIds: counted,
  orderId: orderId,
  lines: lines,
  completed: completed,
);

void main() {
  group('MissionOrderLine', () {
    test('total = harga x jumlah', () {
      expect(line('SERUM-A', 45000, 2).total, 90000);
      expect(line('SERUM-A', 45000).total, 45000);
    });

    test('jumlah 0 atau harga 0 bernilai 0', () {
      expect(line('SERUM-A', 45000, 0).total, 0);
      expect(line('SERUM-A', 0, 3).total, 0);
    });

    test('harga atau jumlah negatif ditolak saat pengembangan', () {
      expect(() => line('SERUM-A', -1), throwsAssertionError);
      expect(() => line('SERUM-A', 1000, -1), throwsAssertionError);
    });

    test('kesetaraan nilai', () {
      expect(line('SERUM-A', 45000, 2), line('SERUM-A', 45000, 2));
      expect(
        line('SERUM-A', 45000, 2).hashCode,
        line('SERUM-A', 45000, 2).hashCode,
      );
      expect(line('SERUM-A', 45000, 2), isNot(line('SERUM-A', 45000, 3)));
      expect(line('SERUM-A', 45000, 2), isNot(line('TONER-B', 45000, 2)));
      expect(line('SERUM-A', 45000, 2), isNot(line('SERUM-A', 44000, 2)));
      expect(line('SERUM-A', 45000, 2).toString(), contains('SERUM-A'));
    });
  });

  group('missionSubtotal', () {
    test('hanya produk misi yang dihitung', () {
      expect(
        missionSubtotal(serumStage, <MissionOrderLine>[
          line('SERUM-A', 45000),
          line('LIPSTIK-Z', 120000, 2),
          line('TONER-B', 15000, 2),
        ]),
        75000,
      );
    });

    test('produk yang sama di dua baris dijumlahkan', () {
      expect(
        missionSubtotal(serumStage, <MissionOrderLine>[
          line('SERUM-A', 45000),
          line('SERUM-A', 45000, 2),
        ]),
        135000,
      );
    });

    test('daftar produk misi kosong: semua produk dihitung', () {
      expect(
        missionSubtotal(demoMissionStages.first, <MissionOrderLine>[
          line('SERUM-A', 45000),
          line('LIPSTIK-Z', 120000, 2),
        ]),
        285000,
      );
    });

    test('tanpa baris atau tanpa produk misi: 0', () {
      expect(missionSubtotal(serumStage, const <MissionOrderLine>[]), 0);
      expect(
        missionSubtotal(serumStage, <MissionOrderLine>[
          line('LIPSTIK-Z', 120000, 2),
        ]),
        0,
      );
    });

    test('tiap tahap memakai daftar produknya sendiri', () {
      final List<MissionOrderLine> lines = <MissionOrderLine>[
        line('SERUM-A', 45000),
        line('MASKER-C', 25000, 3),
      ];
      expect(missionSubtotal(serumStage, lines), 45000);
      expect(missionSubtotal(maskStage, lines), 75000);
    });

    test('menerima Iterable apa pun', () {
      final Iterable<MissionOrderLine> lazy = <int>[
        1,
        2,
        3,
      ].map((int quantity) => line('TONER-B', 10000, quantity));
      expect(missionSubtotal(serumStage, lazy), 60000);
    });
  });

  group('evaluateOrderLines', () {
    test('subtotal produk misi Rp75.000 tepat menerbitkan voucher tahap 1', () {
      final MissionDecision decision = evaluateLines(<MissionOrderLine>[
        line('SERUM-A', 45000),
        line('TONER-B', 15000, 2),
      ]);
      expect(decision.issued, isTrue);
      expect(decision.issuedStage, serumStage);
      expect(decision.rejection, isNull);
    });

    test('pesanan besar tanpa cukup produk misi: belowThreshold', () {
      final MissionDecision decision = evaluateLines(<MissionOrderLine>[
        line('SERUM-A', 74999),
        line('LIPSTIK-Z', 250000, 2),
      ]);
      expect(decision.issued, isFalse);
      expect(decision.rejection, OrderRejection.belowThreshold);
    });

    test('tahap 2 menilai produk misi tahap 2, bukan tahap 1', () {
      final MissionDecision stageOneProducts = evaluateLines(
        <MissionOrderLine>[line('SERUM-A', 200000)],
        issuedCount: 1,
        counted: const <String>{'BP-2001'},
        orderId: 'BP-2002',
      );
      expect(stageOneProducts.rejection, OrderRejection.belowThreshold);

      final MissionDecision stageTwoProducts = evaluateLines(
        <MissionOrderLine>[line('MASKER-C', 25000, 4)],
        issuedCount: 1,
        counted: const <String>{'BP-2001'},
        orderId: 'BP-2002',
      );
      expect(stageTwoProducts.issuedStage, maskStage);
      expect(stageTwoProducts.issuedStage?.voucherAmount, 15000);
    });

    test('satu pesanan menyelesaikan paling banyak satu tahap', () {
      final MissionDecision decision = evaluateLines(<MissionOrderLine>[
        line('SERUM-A', 300000),
        line('MASKER-C', 300000),
      ]);
      expect(decision.issuedStage, serumStage);
    });

    test('pesanan belum selesai: notCompleted, apa pun isinya', () {
      expect(
        evaluateLines(<MissionOrderLine>[
          line('SERUM-A', 300000),
        ], completed: false).rejection,
        OrderRejection.notCompleted,
      );
    });

    test('pesanan yang sudah dihitung: alreadyCounted', () {
      expect(
        evaluateLines(
          <MissionOrderLine>[line('SERUM-A', 300000)],
          counted: const <String>{'BP-2001'},
        ).rejection,
        OrderRejection.alreadyCounted,
      );
    });

    test('semua tahap selesai: allStagesDone', () {
      expect(
        evaluateLines(
          <MissionOrderLine>[line('MASKER-C', 300000)],
          issuedCount: 2,
          counted: const <String>{'BP-2001', 'BP-2002'},
          orderId: 'BP-2003',
        ).rejection,
        OrderRejection.allStagesDone,
      );
      expect(
        evaluateLines(<MissionOrderLine>[
          line('MASKER-C', 300000),
        ], stages: const <MissionStage>[]).rejection,
        OrderRejection.allStagesDone,
      );
    });

    test('urutan pemeriksaan sama dengan evaluateOrder', () {
      expect(
        evaluateLines(
          const <MissionOrderLine>[],
          issuedCount: 2,
          counted: const <String>{'BP-2001'},
          completed: false,
        ).rejection,
        OrderRejection.notCompleted,
      );
      expect(
        evaluateLines(
          const <MissionOrderLine>[],
          issuedCount: 2,
          counted: const <String>{'BP-2001'},
        ).rejection,
        OrderRejection.alreadyCounted,
      );
    });

    test('tanpa daftar produk misi hasilnya sama dengan evaluateOrder', () {
      for (final int issuedCount in <int>[0, 1, 2]) {
        for (final int subtotal in <int>[0, 74999, 75000, 99999, 100000]) {
          for (final bool completed in <bool>[true, false]) {
            expect(
              evaluateLines(
                <MissionOrderLine>[line('APA-SAJA', subtotal)],
                stages: demoMissionStages,
                issuedCount: issuedCount,
                completed: completed,
              ),
              evaluateOrder(
                stages: demoMissionStages,
                issuedCount: issuedCount,
                countedOrderIds: const <String>{},
                orderId: 'BP-2001',
                eligibleSubtotal: subtotal,
                completed: completed,
              ),
              reason:
                  'issuedCount $issuedCount, subtotal $subtotal, '
                  'completed $completed',
            );
          }
        }
      }
    });
  });

  group('missionProgress', () {
    test('Rp45.000 dari Rp75.000: kurang Rp30.000', () {
      final MissionProgress progress = missionProgress(
        serumStage,
        <MissionOrderLine>[line('SERUM-A', 45000), line('LIPSTIK-Z', 90000)],
      );
      expect(progress.current, 45000);
      expect(progress.target, 75000);
      expect(progress.remaining, 30000);
      expect(progress.reached, isFalse);
      expect(progress.fraction, closeTo(0.6, 1e-12));
    });

    test('tepat di ambang: tercapai, sisa 0', () {
      final MissionProgress progress = missionProgress(
        serumStage,
        <MissionOrderLine>[line('SERUM-A', 25000, 3)],
      );
      expect(progress.current, 75000);
      expect(progress.remaining, 0);
      expect(progress.reached, isTrue);
      expect(progress.fraction, 1);
    });

    test('di atas ambang: sisa tetap 0 dan bar penuh', () {
      final MissionProgress progress = missionProgress(
        serumStage,
        <MissionOrderLine>[line('SERUM-A', 45000, 4)],
      );
      expect(progress.current, 180000);
      expect(progress.remaining, 0);
      expect(progress.reached, isTrue);
      expect(progress.fraction, 1);
    });

    test('keranjang kosong: 0 dari target', () {
      final MissionProgress progress = missionProgress(
        serumStage,
        const <MissionOrderLine>[],
      );
      expect(progress.current, 0);
      expect(progress.remaining, 75000);
      expect(progress.reached, isFalse);
      expect(progress.fraction, 0);
    });

    test('tahap tanpa ambang selalu tercapai', () {
      const MissionStage freeStage = MissionStage(
        number: 1,
        minOrderSubtotal: 0,
        voucherAmount: 5000,
        voucherMinSpend: 0,
        voucherValidDays: 7,
      );
      final MissionProgress progress = missionProgress(
        freeStage,
        const <MissionOrderLine>[],
      );
      expect(progress.reached, isTrue);
      expect(progress.remaining, 0);
      expect(progress.fraction, 1);
    });

    test('tercapai tepat ketika evaluateOrderLines menerbitkan voucher', () {
      for (final int price in <int>[1, 74999, 75000, 75001, 150000]) {
        final List<MissionOrderLine> lines = <MissionOrderLine>[
          line('TONER-B', price),
          line('LIPSTIK-Z', 500000),
        ];
        expect(
          missionProgress(serumStage, lines).reached,
          evaluateLines(lines).issued,
          reason: 'harga $price',
        );
      }
    });

    test('kesetaraan nilai', () {
      expect(
        const MissionProgress(current: 45000, target: 75000),
        const MissionProgress(current: 45000, target: 75000),
      );
      expect(
        const MissionProgress(current: 45000, target: 75000).hashCode,
        const MissionProgress(current: 45000, target: 75000).hashCode,
      );
      expect(
        const MissionProgress(current: 45000, target: 75000),
        isNot(const MissionProgress(current: 45001, target: 75000)),
      );
      expect(
        const MissionProgress(current: 45000, target: 75000).toString(),
        'MissionProgress(45000 / 75000)',
      );
    });
  });
}
