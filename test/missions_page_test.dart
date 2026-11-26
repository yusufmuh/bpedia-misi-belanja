import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';
import 'package:misi_belanja/src/kit/kit.dart'
    show CandyButton, CandyVariant, Pressable;

import 'support/mission_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  MissionController controller, {
  double textScale = 1,
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    missionPageApp(
      controller,
      textScale: textScale,
      brightness: brightness,
      disableAnimations: disableAnimations,
    ),
  );
  await tester.pump();
}

Finder _addButtonOf(String name) => find.descendant(
  of: find.ancestor(
    of: find.text(name),
    matching: find.byType(MissionProductCard),
  ),
  matching: find.text('Keranjang'),
);

Finder _reward(String amount) => find.descendant(
  of: find.byKey(const ValueKey<String>('mission-reward')),
  matching: find.text(amount),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.4);
  await tester.pump();
}

void main() {
  testWidgets('tampilan dasar: hero, tahap aktif, kupon, produk misi', (
    WidgetTester tester,
  ) async {
    await _pump(tester, localController());
    expect(find.text('Misi Belanja'), findsWidgets);
    expect(find.text('Tahap 1 dari 2'), findsOneWidget);
    expect(_reward('Rp10.000'), findsOneWidget);
    expect(find.text('Belum mulai'), findsWidgets);
    await _scrollTo(tester, find.text('6 produk'));
    expect(find.text('Produk misi'), findsWidgets);
    expect(find.text('6 produk'), findsOneWidget);
    expect(find.widgetWithText(CandyButton, 'Keranjang'), findsOneWidget);
  });

  testWidgets('tamu: aksi utama Masuk dan progres disembunyikan', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(signedIn: false);
    await _pump(tester, controller);
    expect(find.text('Masuk untuk ikut misi'), findsOneWidget);
    expect(find.text('Masuk dulu, Babes'), findsOneWidget);
    expect(find.byType(MissionProgressTrack), findsNothing);
    await tester.tap(find.text('Masuk untuk ikut misi'));
    await tester.tap(find.text('Masuk sekarang'));
    expect(
      controller.log.where((String entry) => entry == 'openLogin'),
      hasLength(2),
    );
  });

  testWidgets('tambah produk: keranjang dan progres naik, cue tap', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController();
    await _pump(tester, controller);
    final Finder add = _addButtonOf('Animate Brightening Facial Wash 100 ml');
    await _scrollTo(tester, add);
    await tester.tap(add);
    await tester.pump();
    expect(controller.state.quantityOf('P39A06S01000021'), 1);
    expect(controller.log, contains('cue:tap'));
    expect(controller.state.phase, MissionPhase.inCart);
    expect(find.text('Tambah Rp57.200 lagi'), findsOneWidget);
  });

  testWidgets('target tercapai: Checkout, cue bonus, buka checkout', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000021': 2, 'P39A06S01000044': 1},
    );
    await _pump(tester, controller);
    final Finder add = _addButtonOf('Animate Acne Solution Night Cream 10 g');
    await _scrollTo(tester, add);
    await tester.tap(add);
    await tester.pump();
    expect(controller.state.phase, MissionPhase.ready);
    expect(controller.log, contains('cue:bonus'));
    expect(find.text('Siap checkout'), findsWidgets);
    await tester.tap(find.text('Checkout'));
    expect(controller.log.last, 'openCheckout');
  });

  testWidgets('belum tercapai: tombol bar bawah membuka keranjang', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000021': 1},
    );
    await _pump(tester, controller);
    await tester.tap(find.widgetWithText(CandyButton, 'Keranjang'));
    expect(controller.log.last, 'openCart');
  });

  testWidgets('stepper mengurangi lalu menghapus produk', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000021': 2},
    );
    await _pump(tester, controller);
    await _scrollTo(
      tester,
      find.text('Animate Brightening Facial Wash 100 ml'),
    );
    final Finder minus = find.byIcon(Icons.remove).first;
    await _scrollTo(tester, minus);
    await tester.tap(minus);
    await tester.pump();
    expect(controller.state.quantityOf('P39A06S01000021'), 1);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pump();
    expect(controller.state.quantityOf('P39A06S01000021'), 0);
  });

  testWidgets('batas jumlah: tambah ditolak dengan pesan lembut', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000003': 1},
    );
    await _pump(tester, controller);
    final MissionsPage page = tester.widget(find.byType(MissionsPage));
    expect(await page.controller.addToCart('P39A06S01000003'), isFalse);
    await controller.setQuantity('P39A06S01000003', 0);
    await tester.pump();
    final Finder add = _addButtonOf('Animate Acne Care Serum 20 ml');
    await _scrollTo(tester, add);
    await tester.tap(add);
    await tester.pump();
    expect(controller.state.quantityOf('P39A06S01000003'), 1);
  });

  testWidgets('chip kategori menyaring produk tahap 2', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(issuedCount: 1);
    await _pump(tester, controller);
    final Finder makeup = find.text('Makeup');
    await _scrollTo(tester, makeup);
    expect(find.text('Focallure Acne Pimple Patch Fa186 - 1'), findsOneWidget);
    await tester.tap(makeup);
    await tester.pump();
    expect(find.text('Focallure Acne Pimple Patch Fa186 - 1'), findsNothing);
    expect(find.text('Pinkflash Duo Lipgloss Pf-L13 - D02'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Semua'),
      -100,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Semua')),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.text('Semua'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Focallure Acne Pimple Patch Fa186 - 1', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('menunggu pesanan selesai: status, catatan, lihat pesanan', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 3},
    );
    controller
      ..placeOrder()
      ..shipOrder();
    await _pump(tester, controller);
    expect(find.text('Menunggu pesanan selesai'), findsWidgets);
    expect(find.textContaining('Pesanan dikirim'), findsOneWidget);
    await tester.tap(find.text('Lihat pesanan'));
    expect(controller.log.last, 'openOrder:BP-261126-0001');
  });

  testWidgets('tahap tuntas: lembar perayaan sekali, cue missionDone', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 3},
    );
    controller.placeOrder();
    await _pump(tester, controller);
    controller.completeOrder();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Tahap 1 Misi Belanja selesai'), findsOneWidget);
    expect(find.text('Voucher Rp10.000 jadi milikmu'), findsOneWidget);
    expect(find.text('Lanjut tahap 2'), findsOneWidget);
    expect(controller.log, contains('cue:missionDone'));
    expect(controller.state.celebration, isNull);

    tester
        .widget<CandyButton>(find.widgetWithText(CandyButton, 'Lihat voucher'))
        .onPressed!();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Tahap 1 Misi Belanja selesai'), findsNothing);
    expect(find.text('Voucher kamu'), findsOneWidget);
    expect(find.byType(VoucherCard), findsOneWidget);
  });

  testWidgets('lanjut tahap 2 menutup lembar dan menampilkan tahap 2', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 3},
    );
    controller.placeOrder();
    await _pump(tester, controller);
    controller.completeOrder();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('Lanjut tahap 2'));
    await tester.pump();
    await tester.tap(find.text('Lanjut tahap 2'));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Tahap 2 dari 2'), findsOneWidget);
    expect(_reward('Rp15.000'), findsOneWidget);
  });

  testWidgets('voucher: Pakai memanggil useVoucher', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 3},
    );
    controller
      ..placeOrder()
      ..completeOrder()
      ..acknowledgeCelebration();
    await _pump(tester, controller);
    final Finder use = find.text('Pakai');
    await _scrollTo(tester, use);
    await tester.tap(use);
    expect(controller.log.last, 'useVoucher:vch-1-BP-261126-0001');
    await tester.tap(find.text('Lihat semua'));
    expect(controller.log.last, 'openVouchers');
  });

  testWidgets('semua tahap selesai: kartu tuntas dan Belanja lagi', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(issuedCount: 2);
    await _pump(tester, controller);
    expect(find.text('Semua tahap selesai, Babes!'), findsOneWidget);
    expect(find.text('Semua tahap selesai'), findsOneWidget);
    expect(find.byType(MissionProductCard), findsNothing);
    await tester.tap(find.widgetWithText(CandyButton, 'Belanja lagi'));
    expect(controller.log.last, 'openShop');
  });

  testWidgets('tanpa produk misi: keadaan kosong dengan satu aksi', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      withProducts: false,
    );
    await _pump(tester, controller);
    final Finder empty = find.text('Produk misi sedang disiapkan');
    await _scrollTo(tester, empty);
    await tester.tap(find.text('Lihat katalog'));
    expect(controller.log.last, 'openShop');
  });

  testWidgets('Aturan membuka lembar syarat; suara bisa dimatikan', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController();
    await _pump(tester, controller);
    await tester.tap(find.byTooltip('Matikan suara'));
    await tester.pump();
    expect(controller.state.soundOn, isFalse);
    expect(find.byTooltip('Nyalakan suara'), findsOneWidget);
    await tester.tap(find.text('Aturan'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Syarat & ketentuan Misi Belanja'), findsOneWidget);
    expect(find.textContaining('Satu pesanan menyelesaikan'), findsOneWidget);
  });

  testWidgets('tanpa status suara: tombol suara disembunyikan', (
    WidgetTester tester,
  ) async {
    await _pump(tester, localController(soundOn: null));
    expect(find.byTooltip('Matikan suara'), findsNothing);
  });

  testWidgets('pengendali diganti: halaman mengikuti yang baru', (
    WidgetTester tester,
  ) async {
    await _pump(tester, localController());
    final LocalMissionController next = localController(issuedCount: 2);
    await tester.pumpWidget(missionPageApp(next, disableAnimations: true));
    await tester.pump();
    expect(find.text('Semua tahap selesai, Babes!'), findsOneWidget);
    next.reset();
    await tester.pump();
    expect(find.text('Tahap 1 dari 2'), findsOneWidget);
  });

  testWidgets('animasi penuh: tambah dan tuntas berjalan tanpa galat', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000007': 2, 'P39A06S01000044': 1},
    );
    await _pump(tester, controller, disableAnimations: false);
    final Finder add = _addButtonOf('Animate Facial Essence 60 Kapsul');
    await _scrollTo(tester, add);
    await tester.tap(add);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    controller
      ..placeOrder()
      ..completeOrder();
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Tahap 1 Misi Belanja selesai'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (String name, LocalMissionController Function() make)
      in <(String, LocalMissionController Function())>[
        ('tamu', () => localController(signedIn: false)),
        (
          'di keranjang',
          () => localController(cart: <String, int>{'P39A06S01000021': 1}),
        ),
        (
          'siap checkout',
          () => localController(cart: <String, int>{'P39A06S01000007': 3}),
        ),
        ('tahap 2', () => localController(issuedCount: 1)),
        ('semua selesai', () => localController(issuedCount: 2)),
      ]) {
    testWidgets('teks 200% di lebar 360 tanpa luapan ($name)', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        make(),
        textScale: 2,
        size: const Size(360, 740),
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('semantics: progres dan tombol utama berlabel', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(
      tester,
      localController(cart: <String, int>{'P39A06S01000021': 1}),
    );
    expect(
      find.bySemanticsLabel(RegExp('^Produk misi di keranjang')),
      findsWidgets,
    );
    expect(find.bySemanticsLabel(RegExp('Lihat keranjang')), findsOneWidget);
    semantics.dispose();
  });
  group('tahap berjudul kustom', () {
    final List<MissionStage> titled = <MissionStage>[
      for (final MissionStage stage in harnessStages)
        MissionStage(
          number: stage.number,
          title: stage.number == 1 ? 'Skincare Animate' : 'Glow Bareng',
          minOrderSubtotal: stage.minOrderSubtotal,
          voucherAmount: stage.voucherAmount,
          voucherMinSpend: stage.voucherMinSpend,
          voucherValidDays: stage.voucherValidDays,
          productCodes: stage.productCodes,
        ),
    ];

    testWidgets('chip hero memakai nomor tahap, bukan judul', (
      WidgetTester tester,
    ) async {
      await _pump(tester, localController(stages: titled));
      expect(find.text('Tahap 1 dari 2'), findsOneWidget);
      expect(find.text('Skincare Animate dari 2'), findsNothing);
      expect(find.text('Skincare Animate'), findsWidgets);
    });

    testWidgets('lembar tuntas: judul, berlaku, dan lanjut memakai nomor', (
      WidgetTester tester,
    ) async {
      final LocalMissionController controller = localController(
        stages: titled,
        cart: <String, int>{'P39A06S01000007': 3},
      );
      controller.placeOrder();
      await _pump(tester, controller);
      controller.completeOrder();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final MissionVoucher voucher = controller.state.vouchers.single;
      expect(find.text('Tahap 1 Misi Belanja selesai'), findsOneWidget);
      expect(find.text('Lanjut tahap 2'), findsOneWidget);
      expect(find.text('Lanjut glow bareng'), findsNothing);
      expect(
        find.text('Berlaku s.d. ${formatWibDateShort(voucher.expiresDay)}'),
        findsWidgets,
      );
      expect(
        tester
            .widget<CandyButton>(
              find.widgetWithText(CandyButton, 'Lihat voucher'),
            )
            .variant,
        CandyVariant.pink,
      );
    });
  });

  testWidgets('lembar tuntas tahap terakhir: tautan Nanti saja', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      issuedCount: 1,
      cart: <String, int>{'P21F02C01000026': 3},
    );
    controller.placeOrder();
    await _pump(tester, controller);
    controller.completeOrder();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Tahap 2 Misi Belanja selesai'), findsOneWidget);
    expect(find.text('Nanti saja'), findsOneWidget);
    tester
        .widget<Pressable>(
          find.ancestor(
            of: find.text('Nanti saja'),
            matching: find.byType(Pressable),
          ),
        )
        .onTap!();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Tahap 2 Misi Belanja selesai'), findsNothing);
  });

  testWidgets('kartu atas memuat tangga tahap, seksi bawah tanpa duplikat', (
    WidgetTester tester,
  ) async {
    await _pump(tester, localController(issuedCount: 1));
    expect(find.byType(MissionStageTrack), findsOneWidget);
    expect(find.text('Berjalan'), findsOneWidget);
    expect(find.text('Segera hadir'), findsOneWidget);
    final double trackTop = tester
        .getTopLeft(find.byType(MissionStageTrack))
        .dy;
    expect(trackTop, lessThan(tester.getTopLeft(_reward('Rp15.000')).dy));
  });

  testWidgets('bilah lekat: Di keranjang dan Tambah X lagi, progres 4 dp', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      localController(cart: <String, int>{'P39A06S01000021': 1}),
    );
    expect(find.textContaining('Kurang '), findsNothing);
    expect(find.text('Di keranjang'), findsNWidgets(2));
    expect(
      find.textContaining(RegExp(r'^Tambah Rp[\d.]+ lagi$')),
      findsOneWidget,
    );
    final Finder bar = find.byKey(
      const ValueKey<String>('mission-bar-progress'),
    );
    expect(bar, findsOneWidget);
    expect(tester.getSize(bar).height, 4);
  });
}
