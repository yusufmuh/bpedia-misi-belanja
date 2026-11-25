import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'support/v2_fixtures.dart';

const MissionStage plainStage = MissionStage(
  number: 3,
  minOrderSubtotal: 120000,
  voucherAmount: 20000,
  voucherMinSpend: 200000,
  voucherValidDays: 14,
);

const MissionStage productStage = MissionStage(
  number: 3,
  id: 'des-glow',
  title: 'Paket glow Desember',
  minOrderSubtotal: 120000,
  voucherAmount: 20000,
  voucherMinSpend: 200000,
  voucherValidDays: 14,
  productCodes: <String>['SERUM-A', 'TONER-B'],
);

void main() {
  group('MissionStage · id, title, productCodes', () {
    test('tanpa nilai eksplisit: id dan judul diturunkan dari nomor', () {
      expect(plainStage.id, 'tahap-3');
      expect(plainStage.title, 'Tahap 3');
      expect(plainStage.productCodes, isEmpty);
      expect(plainStage.countsAllProducts, isTrue);
    });

    test('nilai eksplisit dipakai apa adanya', () {
      expect(productStage.id, 'des-glow');
      expect(productStage.title, 'Paket glow Desember');
      expect(productStage.productCodes, <String>['SERUM-A', 'TONER-B']);
      expect(productStage.countsAllProducts, isFalse);
    });

    test('countsProduct: daftar kosong menghitung semua produk', () {
      expect(plainStage.countsProduct('SERUM-A'), isTrue);
      expect(plainStage.countsProduct('APA-SAJA'), isTrue);
    });

    test('countsProduct: hanya kode di daftar produk misi', () {
      expect(productStage.countsProduct('SERUM-A'), isTrue);
      expect(productStage.countsProduct('TONER-B'), isTrue);
      expect(productStage.countsProduct('LIPSTIK-Z'), isFalse);
      expect(productStage.countsProduct('serum-a'), isFalse);
    });

    test('kesetaraan memperhitungkan id, judul, dan produk misi', () {
      const MissionStage sameAsProduct = MissionStage(
        number: 3,
        id: 'des-glow',
        title: 'Paket glow Desember',
        minOrderSubtotal: 120000,
        voucherAmount: 20000,
        voucherMinSpend: 200000,
        voucherValidDays: 14,
        productCodes: <String>['SERUM-A', 'TONER-B'],
      );
      expect(productStage, sameAsProduct);
      expect(productStage.hashCode, sameAsProduct.hashCode);
      expect(productStage, isNot(plainStage));
      expect(
        productStage,
        isNot(
          const MissionStage(
            number: 3,
            id: 'des-glow',
            title: 'Paket glow Desember',
            minOrderSubtotal: 120000,
            voucherAmount: 20000,
            voucherMinSpend: 200000,
            voucherValidDays: 14,
            productCodes: <String>['TONER-B', 'SERUM-A'],
          ),
        ),
      );
    });

    test('id dan judul bawaan setara dengan yang ditulis eksplisit', () {
      const MissionStage explicitDefaults = MissionStage(
        number: 3,
        id: 'tahap-3',
        title: 'Tahap 3',
        minOrderSubtotal: 120000,
        voucherAmount: 20000,
        voucherMinSpend: 200000,
        voucherValidDays: 14,
      );
      expect(explicitDefaults, plainStage);
      expect(explicitDefaults.hashCode, plainStage.hashCode);
    });

    test('daftar produk misi yang dibuat saat berjalan tetap setara', () {
      final MissionStage runtime = MissionStage(
        number: 3,
        id: 'des-glow',
        title: 'Paket glow Desember',
        minOrderSubtotal: 120000,
        voucherAmount: 20000,
        voucherMinSpend: 200000,
        voucherValidDays: 14,
        productCodes: <String>['SERUM-A', 'TONER-B'].toList(),
      );
      expect(runtime, productStage);
      expect(runtime.hashCode, productStage.hashCode);
    });

    test('toString menyebut id dan produk misi', () {
      expect(productStage.toString(), contains('id: des-glow'));
      expect(productStage.toString(), contains('[SERUM-A, TONER-B]'));
    });
  });

  group('demoMissionStages v3', () {
    test('id dan judul bawaan, daftar produk misi kosong', () {
      expect(
        <String>[for (final MissionStage stage in demoMissionStages) stage.id],
        <String>['tahap-1', 'tahap-2'],
      );
      expect(
        <String>[
          for (final MissionStage stage in demoMissionStages) stage.title,
        ],
        <String>['Tahap 1', 'Tahap 2'],
      );
      for (final MissionStage stage in demoMissionStages) {
        expect(stage.productCodes, isEmpty);
        expect(stage.voucherValidDays, 30);
      }
    });

    test('tahap 1 sama dengan v2; ambang tahap 2 tidak berubah', () {
      expect(demoMissionStages[0], v2MissionStages[0]);
      expect(
        demoMissionStages[1].minOrderSubtotal,
        v2MissionStages[1].minOrderSubtotal,
      );
    });

    test('voucher tahap 2: Rp15.000 dengan min. belanja Rp150.000', () {
      final MissionVoucher voucher = MissionVoucher.issue(
        id: 'vch-2-BP-1002',
        stage: demoMissionStages[1],
        sourceOrderId: 'BP-1002',
        issuedDay: 20781,
      );
      expect(voucher.amount, 15000);
      expect(voucher.minSpend, 150000);
      expect(voucher.expiresDay, 20811);
      expect(
        redeemProblem(
          voucher: voucher,
          orderId: 'BP-1003',
          subtotal: 149999,
          today: 20790,
        ),
        RedeemProblem.belowMinimum,
      );
      expect(
        redeemProblem(
          voucher: voucher,
          orderId: 'BP-1003',
          subtotal: 150000,
          today: 20790,
        ),
        isNull,
      );
    });
  });
}
