import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';
import 'package:misi_belanja_example/demo_data.dart';
import 'package:misi_belanja_example/main.dart';

Future<LocalMissionController> _pumpDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final LocalMissionController controller = demoController(
    today: wibToday(DateTime.utc(2026, 11, 26, 3)),
  );
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MissionDemoApp(controller: controller),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  test('tahap demo memakai nilai modul dan daftar produk misi', () {
    expect(demoStages, hasLength(2));
    expect(demoStages.first.minOrderSubtotal, 75000);
    expect(demoStages.first.productCodes, hasLength(stageOneProducts.length));
    expect(demoStages.last.productCodes, hasLength(stageTwoProducts.length));
  });

  testWidgets('halaman tampil; tombol kembali membuka panel uji', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = await _pumpDemo(tester);
    expect(find.text('Tahap 1 dari 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Panel uji (demo)'), findsOneWidget);

    await tester.ensureVisible(find.text('Sudah masuk'));
    await tester.pump();
    await tester.tap(find.text('Sudah masuk'));
    await tester.pump();
    expect(controller.state.signedIn, isFalse);
  });

  testWidgets('panel: checkout dan selesai memicu perayaan tahap', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = await _pumpDemo(tester);
    await controller.setQuantity('P39A06S01000007', 3);
    await tester.pump();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('Checkout keranjang'));
    await tester.pump();
    await tester.tap(find.text('Checkout keranjang'));
    await tester.pump();
    expect(controller.openOrderId, isNotNull);
    await tester.ensureVisible(find.text('Selesai'));
    await tester.pump();
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Tahap 1 Misi Belanja selesai'), findsOneWidget);
    expect(controller.state.issuedCount, 1);
  });
}
