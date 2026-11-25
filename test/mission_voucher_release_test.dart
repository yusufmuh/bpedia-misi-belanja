import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

const int issuedDay = 20781;

final MissionVoucher fresh = MissionVoucher.issue(
  id: 'vch-1-BP-1001',
  stage: demoMissionStages[0],
  sourceOrderId: 'BP-1001',
  issuedDay: issuedDay,
);

void main() {
  group('MissionVoucher.release', () {
    test('voucher terpakai kembali bisa dipakai; aslinya tidak berubah', () {
      final MissionVoucher used = fresh.markUsed('BP-1002');
      final MissionVoucher released = used.release();

      expect(released.isUsed, isFalse);
      expect(released.usedOnOrderId, isNull);
      expect(released, fresh);
      expect(used.usedOnOrderId, 'BP-1002');
    });

    test('voucher yang belum dipakai dikembalikan apa adanya', () {
      expect(identical(fresh.release(), fresh), isTrue);
    });

    test(
      'setelah dilepas boleh dipakai di pesanan lain, lalu terpakai lagi',
      () {
        final MissionVoucher released = fresh.markUsed('BP-1002').release();
        expect(
          redeemProblem(
            voucher: released,
            orderId: 'BP-1003',
            subtotal: 100000,
            today: issuedDay + 5,
          ),
          isNull,
        );
        final MissionVoucher reused = released.markUsed('BP-1003');
        expect(reused.usedOnOrderId, 'BP-1003');
        expect(
          redeemProblem(
            voucher: reused,
            orderId: 'BP-1004',
            subtotal: 100000,
            today: issuedDay + 5,
          ),
          RedeemProblem.alreadyUsed,
        );
      },
    );

    test('boleh dipakai lagi di pesanan yang sama setelah batal', () {
      final MissionVoucher released = fresh.markUsed('BP-1002').release();
      expect(
        redeemProblem(
          voucher: released,
          orderId: 'BP-1002',
          subtotal: 100000,
          today: issuedDay,
        ),
        isNull,
      );
    });

    test('melepas tidak memperpanjang masa berlaku', () {
      final MissionVoucher released = fresh.markUsed('BP-1002').release();
      expect(released.issuedDay, fresh.issuedDay);
      expect(released.expiresDay, fresh.expiresDay);
      expect(released.isActiveOn(fresh.expiresDay), isTrue);
      expect(released.isActiveOn(fresh.expiresDay + 1), isFalse);
      expect(
        redeemProblem(
          voucher: released,
          orderId: 'BP-1003',
          subtotal: 100000,
          today: fresh.expiresDay + 1,
        ),
        RedeemProblem.expired,
      );
    });

    test('tetap tidak bisa dipakai di pesanan yang menerbitkannya', () {
      final MissionVoucher released = fresh.markUsed('BP-1002').release();
      expect(
        redeemProblem(
          voucher: released,
          orderId: 'BP-1001',
          subtotal: 500000,
          today: issuedDay,
        ),
        RedeemProblem.sameOrder,
      );
    });

    test('JSON setelah dilepas: usedOnOrderId null dan terbaca kembali', () {
      final MissionVoucher released = fresh.markUsed('BP-1002').release();
      final Map<String, Object?> json = released.toJson();
      expect(json['usedOnOrderId'], isNull);
      expect(json.keys, fresh.toJson().keys);
      expect(MissionVoucher.fromJson(json), fresh);
    });
  });
}
