import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'support/test_app.dart';

void main() {
  final int issuedDay = wibDayOf(2026, 11, 24);
  final MissionVoucher voucher = MissionVoucher.issue(
    id: 'vch-1-BP-1001',
    stage: demoMissionStages[0],
    sourceOrderId: 'BP-1001',
    issuedDay: issuedDay,
  );

  group('MissionVoucher.issue', () {
    test('mengambil nominal tahap dan berlaku 30 hari', () {
      expect(voucher.stageNumber, 1);
      expect(voucher.amount, 10000);
      expect(voucher.minSpend, 100000);
      expect(voucher.issuedDay, issuedDay);
      expect(voucher.expiresDay, wibDayOf(2026, 12, 24));
      expect(voucher.usedOnOrderId, isNull);
      expect(voucher.isActiveOn(issuedDay), isTrue);
    });
  });

  group('redeemProblem', () {
    RedeemProblem? check({
      MissionVoucher? target,
      String orderId = 'BP-2002',
      int subtotal = 100000,
      int? today,
    }) => redeemProblem(
      voucher: target ?? voucher,
      orderId: orderId,
      subtotal: subtotal,
      today: today ?? issuedDay,
    );

    test('pesanan asal voucher: sameOrder', () {
      expect(
        check(orderId: 'BP-1001', subtotal: 150000),
        RedeemProblem.sameOrder,
      );
    });

    test('Rp99.999: belowMinimum', () {
      expect(check(subtotal: 99999), RedeemProblem.belowMinimum);
    });

    test('Rp100.000 tepat di pesanan lain: boleh dipakai', () {
      expect(check(), isNull);
    });

    test('voucher sudah dipakai: alreadyUsed', () {
      expect(
        check(target: voucher.markUsed('BP-2002'), orderId: 'BP-3003'),
        RedeemProblem.alreadyUsed,
      );
    });

    test('hari setelah expiresDay: expired', () {
      expect(check(today: voucher.expiresDay + 1), RedeemProblem.expired);
    });

    test('tepat di expiresDay: masih boleh dipakai', () {
      expect(check(today: voucher.expiresDay), isNull);
    });

    test('urutan pemeriksaan: alreadyUsed, expired, sameOrder, '
        'belowMinimum', () {
      expect(
        check(
          target: voucher.markUsed('BP-2002'),
          orderId: 'BP-1001',
          subtotal: 1,
          today: voucher.expiresDay + 1,
        ),
        RedeemProblem.alreadyUsed,
      );
      expect(
        check(orderId: 'BP-1001', subtotal: 1, today: voucher.expiresDay + 1),
        RedeemProblem.expired,
      );
      expect(check(orderId: 'BP-1001', subtotal: 1), RedeemProblem.sameOrder);
    });
  });

  group('markUsed', () {
    test('mengembalikan instance baru tanpa mengubah aslinya', () {
      final MissionVoucher used = voucher.markUsed('BP-2002');
      expect(identical(used, voucher), isFalse);
      expect(voucher.usedOnOrderId, isNull);
      expect(voucher.isUsed, isFalse);
      expect(used.usedOnOrderId, 'BP-2002');
      expect(used.isUsed, isTrue);
      expect(used.id, voucher.id);
      expect(used.amount, voucher.amount);
      expect(used.expiresDay, voucher.expiresDay);
    });
  });

  group('JSON', () {
    test('toJson lalu fromJson menghasilkan voucher yang sama', () {
      expect(MissionVoucher.fromJson(voucher.toJson()), voucher);
      final MissionVoucher used = voucher.markUsed('BP-2002');
      expect(MissionVoucher.fromJson(used.toJson()), used);
    });

    test('bertahan melewati jsonEncode/jsonDecode', () {
      final MissionVoucher used = voucher.markUsed('BP-2002');
      final Object? decoded = jsonDecode(jsonEncode(used.toJson()));
      expect(decoded, isA<Map<String, Object?>>());
      expect(MissionVoucher.fromJson(decoded! as Map<String, Object?>), used);
    });

    test('kunci toJson stabil', () {
      expect(voucher.toJson(), <String, Object?>{
        'id': 'vch-1-BP-1001',
        'stageNumber': 1,
        'sourceOrderId': 'BP-1001',
        'amount': 10000,
        'minSpend': 100000,
        'issuedDay': issuedDay,
        'expiresDay': issuedDay + 30,
        'usedOnOrderId': null,
      });
    });

    test('data rusak melempar FormatException', () {
      final Map<String, Object?> valid = voucher.toJson();
      final List<Map<String, Object?>> broken = <Map<String, Object?>>[
        <String, Object?>{...valid}..remove('id'),
        <String, Object?>{...valid, 'amount': '10000'},
        <String, Object?>{...valid, 'amount': 0},
        <String, Object?>{...valid, 'issuedDay': 1.5},
        <String, Object?>{...valid, 'sourceOrderId': ''},
        <String, Object?>{...valid, 'usedOnOrderId': ''},
        <String, Object?>{...valid, 'stageNumber': 0},
        <String, Object?>{...valid, 'expiresDay': issuedDay - 1},
      ];
      for (final Map<String, Object?> json in broken) {
        expect(
          () => MissionVoucher.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });
  });
}
