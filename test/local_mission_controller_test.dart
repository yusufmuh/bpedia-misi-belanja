import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'support/mission_harness.dart';

void main() {
  test('tambah ke keranjang menaikkan progres dan memberi tahu', () async {
    final LocalMissionController controller = localController();
    int notified = 0;
    controller.addListener(() => notified++);

    expect(await controller.addToCart('P39A06S01000021'), isTrue);
    expect(controller.state.quantityOf('P39A06S01000021'), 1);
    expect(controller.state.progress?.current, 17800);
    expect(notified, greaterThan(0));
  });

  test('produk tak dikenal atau melewati batas jumlah ditolak', () async {
    final LocalMissionController controller = localController();
    expect(await controller.addToCart('tidak-ada'), isFalse);
    expect(await controller.addToCart('P39A06S01000003'), isTrue);
    expect(await controller.addToCart('P39A06S01000003'), isFalse);
    expect(controller.state.quantityOf('P39A06S01000003'), 1);
  });

  test('setQuantity 0 menghapus baris; batas atas dijaga', () async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000021': 2, 'P39A06S01000003': 1},
    );
    await controller.setQuantity('P39A06S01000021', 0);
    await controller.setQuantity('P39A06S01000003', 5);
    expect(controller.state.quantityOf('P39A06S01000021'), 0);
    expect(controller.state.quantityOf('P39A06S01000003'), 1);
  });

  test('pesanan di bawah target tidak membuat tahap menunggu', () {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000021': 1},
    );
    expect(controller.placeOrder(), isNotNull);
    expect(controller.state.pendingOrder, isNull);
    final MissionDecision? decision = controller.completeOrder();
    expect(decision?.rejection, OrderRejection.belowThreshold);
    expect(controller.state.issuedCount, 0);
  });

  test('alur penuh: checkout, kirim, selesai, voucher, tahap 2', () {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 2, 'P39A06S01000044': 1},
    );
    final String? id = controller.placeOrder();
    expect(id, 'BP-261126-0001');
    expect(controller.state.phase, MissionPhase.awaitingCompletion);
    expect(controller.state.pendingOrder?.statusLabel, 'Dikemas');
    controller.shipOrder();
    expect(controller.state.pendingOrder?.statusLabel, 'Dikirim');

    final MissionDecision? decision = controller.completeOrder();
    expect(decision?.issued, isTrue);
    final MissionViewState state = controller.state;
    expect(state.issuedCount, 1);
    expect(state.activeStage, harnessStages[1]);
    expect(state.products, stageTwoProducts);
    expect(state.vouchers.single.amount, 10000);
    expect(state.vouchers.single.expiresDay, demoToday + 30);
    expect(state.celebration?.nextStage, harnessStages[1]);

    controller.acknowledgeCelebration();
    expect(controller.state.celebration, isNull);
  });

  test('batal mengembalikan isi pesanan ke keranjang', () {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 3},
    );
    controller
      ..placeOrder()
      ..cancelOrder();
    expect(controller.state.pendingOrder, isNull);
    expect(controller.state.quantityOf('P39A06S01000007'), 3);
  });

  test('tamu tidak bisa checkout; masuk memulihkan keadaan', () {
    final LocalMissionController controller = localController(
      signedIn: false,
      cart: <String, int>{'P39A06S01000007': 3},
    );
    expect(controller.state.signedIn, isFalse);
    expect(controller.placeOrder(), isNull);
    controller.signIn();
    expect(controller.state.phase, MissionPhase.ready);
  });

  test('ganti hari mengubah status voucher', () {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 3},
    );
    controller
      ..placeOrder()
      ..completeOrder()
      ..setToday(demoToday + 31);
    expect(controller.state.activeVoucherCount, 0);
  });

  test('reset kembali ke awal kampanye', () {
    final LocalMissionController controller = localController(
      issuedCount: 2,
      cart: <String, int>{'P39A06S01000007': 1},
    );
    controller.reset();
    expect(controller.state.issuedCount, 0);
    expect(controller.state.cartLines, isEmpty);
  });

  test('aksi navigasi, suara, dan voucher dicatat', () {
    final LocalMissionController controller = localController();
    controller
      ..openLogin()
      ..openCart()
      ..openCheckout()
      ..openShop()
      ..openProduct('X')
      ..openOrder('BP-1')
      ..openVouchers()
      ..useVoucher('v1')
      ..playCue(GameCue.missionDone)
      ..setSoundOn(false);
    expect(controller.log, <String>[
      'openLogin',
      'openCart',
      'openCheckout',
      'openShop',
      'openProduct:X',
      'openOrder:BP-1',
      'openVouchers',
      'useVoucher:v1',
      'cue:missionDone',
    ]);
    expect(controller.state.soundOn, isFalse);
  });
}
