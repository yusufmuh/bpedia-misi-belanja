import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

void main() {
  group('PRD 3 - Misi Belanja Logic Tests', () {
    final stage1 = demoStages[0]; // threshold: 75000, discount: 10000, redeemMinimum: 100000

    test('Pesanan Rp74.999 tidak memenuhi syarat Tahap 1', () {
      final res = qualifies(
        terms: stage1,
        subtotal: 74999,
        completed: true,
        alreadyCounted: false,
      );
      expect(res, isFalse);
    });

    test('Pesanan Rp75.000 berstatus selesai memenuhi syarat Tahap 1', () {
      final res = qualifies(
        terms: stage1,
        subtotal: 75000,
        completed: true,
        alreadyCounted: false,
      );
      expect(res, isTrue);
    });

    test('Pesanan belum selesai tidak memenuhi syarat', () {
      final res = qualifies(
        terms: stage1,
        subtotal: 100000,
        completed: false,
        alreadyCounted: false,
      );
      expect(res, isFalse);
    });

    test('Pesanan yang sudah dihitung tidak dapat diklaim ulang', () {
      final res = qualifies(
        terms: stage1,
        subtotal: 100000,
        completed: true,
        alreadyCounted: true,
      );
      expect(res, isFalse);
    });

    test('Penukaran voucher gagal jika belanja berikutnya di bawah Rp100.000', () {
      final res = mayRedeem(
        terms: stage1,
        subtotal: 99999,
        sourceOrder: 'ORD-1',
        nextOrder: 'ORD-2',
        used: false,
      );
      expect(res, isFalse);
    });

    test('Penukaran voucher gagal jika dipakai di nomor pesanan asal (anti-self-loop)', () {
      final res = mayRedeem(
        terms: stage1,
        subtotal: 150000,
        sourceOrder: 'ORD-1',
        nextOrder: 'ORD-1',
        used: false,
      );
      expect(res, isFalse);
    });

    test('Penukaran voucher sukses jika pesanan baru >= Rp100.000 dan beda order', () {
      final res = mayRedeem(
        terms: stage1,
        subtotal: 100000,
        sourceOrder: 'ORD-1',
        nextOrder: 'ORD-2',
        used: false,
      );
      expect(res, isTrue);
    });
  });
}
