import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'support/mission_harness.dart';

MissionViewState _state({
  bool signedIn = true,
  int issuedCount = 0,
  List<MissionOrderLine> cart = const <MissionOrderLine>[],
  MissionPendingOrder? pending,
}) => MissionViewState(
  signedIn: signedIn,
  stages: harnessStages,
  issuedCount: issuedCount,
  today: demoToday,
  products: stageOneProducts,
  cartLines: cart,
  pendingOrder: pending,
);

const MissionOrderLine _wash = MissionOrderLine(
  productCode: 'P39A06S01000021',
  unitPrice: 17800,
  quantity: 2,
);
const MissionOrderLine _cream = MissionOrderLine(
  productCode: 'P39A06S01000007',
  unitPrice: 26000,
  quantity: 2,
);
const MissionOrderLine _other = MissionOrderLine(
  productCode: 'BUKAN-MISI',
  unitPrice: 90000,
  quantity: 1,
);

void main() {
  group('MissionProduct', () {
    test('diskon dihitung dari harga coret dan dibulatkan', () {
      const MissionProduct product = MissionProduct(
        code: 'A',
        name: 'A',
        image: AssetImage('a.webp'),
        price: 10000,
        strikePrice: 11500,
      );
      expect(product.discountPercent, 13);
    });

    test('tanpa harga coret atau harga coret lebih murah: tanpa diskon', () {
      const MissionProduct plain = MissionProduct(
        code: 'A',
        name: 'A',
        image: AssetImage('a.webp'),
        price: 10000,
      );
      const MissionProduct odd = MissionProduct(
        code: 'A',
        name: 'A',
        image: AssetImage('a.webp'),
        price: 10000,
        strikePrice: 9000,
      );
      expect(plain.discountPercent, isNull);
      expect(odd.discountPercent, isNull);
    });
  });

  group('MissionViewState', () {
    test('fase belum mulai saat keranjang tanpa produk misi', () {
      expect(_state().phase, MissionPhase.notStarted);
      expect(
        _state(cart: <MissionOrderLine>[_other]).phase,
        MissionPhase.notStarted,
      );
    });

    test('progres hanya menghitung produk misi tahap aktif', () {
      final MissionViewState state = _state(
        cart: <MissionOrderLine>[_wash, _other],
      );
      expect(
        state.progress,
        const MissionProgress(current: 35600, target: 75000),
      );
      expect(state.phase, MissionPhase.inCart);
    });

    test('target tercapai menjadi siap checkout', () {
      final MissionViewState state = _state(
        cart: <MissionOrderLine>[_wash, _cream],
      );
      expect(state.progress?.reached, isTrue);
      expect(state.phase, MissionPhase.ready);
    });

    test('pesanan berjalan mengalahkan isi keranjang', () {
      final MissionViewState state = _state(
        cart: <MissionOrderLine>[_wash, _cream],
        pending: const MissionPendingOrder(
          orderId: 'BP-1',
          missionSubtotal: 80000,
        ),
      );
      expect(state.phase, MissionPhase.awaitingCompletion);
    });

    test('semua tahap selesai: tanpa tahap aktif dan tanpa progres', () {
      final MissionViewState state = _state(issuedCount: 2);
      expect(state.allDone, isTrue);
      expect(state.activeStage, isNull);
      expect(state.activeIndex, isNull);
      expect(state.progress, isNull);
      expect(state.phase, MissionPhase.allDone);
    });

    test('tahap aktif mengikuti jumlah voucher terbit', () {
      expect(_state(issuedCount: 1).activeStage, harnessStages[1]);
      expect(_state(issuedCount: 1).statusOf(0), StageStatus.completed);
      expect(_state(issuedCount: 1).statusOf(1), StageStatus.active);
    });

    test('quantityOf menjumlah baris dengan kode sama', () {
      final MissionViewState state = _state(
        cart: <MissionOrderLine>[_wash, _wash],
      );
      expect(state.quantityOf('P39A06S01000021'), 4);
      expect(state.quantityOf('lain'), 0);
    });

    test('kategori unik urut kemunculan', () {
      final MissionViewState state = _state().copyWith(
        products: stageTwoProducts,
      );
      expect(state.categories, <String>[
        'Skincare',
        'Makeup',
        'Lashes & Tools',
      ]);
    });

    test('voucher aktif tidak menghitung yang terpakai atau kedaluwarsa', () {
      final MissionVoucher fresh = MissionVoucher.issue(
        id: 'v1',
        stage: harnessStages[0],
        sourceOrderId: 'BP-1',
        issuedDay: demoToday,
      );
      final MissionVoucher old = MissionVoucher.issue(
        id: 'v2',
        stage: harnessStages[0],
        sourceOrderId: 'BP-2',
        issuedDay: demoToday - 40,
      );
      final MissionViewState state = _state().copyWith(
        vouchers: <MissionVoucher>[fresh, old, fresh.markUsed('BP-3')],
      );
      expect(state.activeVoucherCount, 1);
    });

    test('tamu: tanpa voucher, pesanan, dan perayaan', () {
      final MissionViewState guest = MissionViewState.guest(
        stages: harnessStages,
        today: demoToday,
      );
      expect(guest.signedIn, isFalse);
      expect(guest.issuedCount, 0);
      expect(guest.vouchers, isEmpty);
      expect(guest.pendingOrder, isNull);
      expect(guest.celebration, isNull);
    });

    test('copyWith mengosongkan nilai opsional dan setara bila sama', () {
      final MissionViewState pending = _state(
        pending: const MissionPendingOrder(orderId: 'BP-1', missionSubtotal: 1),
      );
      expect(pending.copyWith(clearPendingOrder: true).pendingOrder, isNull);
      expect(pending.copyWith(), pending);
      expect(pending.copyWith().hashCode, pending.hashCode);
    });
  });
}
