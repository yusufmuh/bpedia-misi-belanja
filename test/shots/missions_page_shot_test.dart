import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import '../support/mission_harness.dart';
import '../support/shot.dart';

const Size _long = Size(390, 2600);

void main() {
  for (final Brightness brightness in Brightness.values) {
    final String tone = brightness == Brightness.dark ? 'gelap' : 'terang';

    testWidgets('misi di keranjang ($tone)', (WidgetTester tester) async {
      final LocalMissionController controller = localController(
        cart: <String, int>{'P39A06S01000021': 1, 'P39A06S01000044': 1},
      );
      await shot(
        tester,
        missionPageApp(controller, brightness: brightness),
        name: 'misi_keranjang_$tone',
      );
      await shot(
        tester,
        missionPageApp(controller, brightness: brightness),
        name: 'misi_panjang_$tone',
        size: _long,
      );
    });

    testWidgets('misi siap checkout ($tone)', (WidgetTester tester) async {
      final LocalMissionController controller = localController(
        cart: <String, int>{
          'P39A06S01000021': 2,
          'P39A06S01000044': 1,
          'P39A06S01000089': 1,
        },
      );
      await shot(
        tester,
        missionPageApp(controller, brightness: brightness),
        name: 'misi_siap_$tone',
      );
    });

    testWidgets('misi tamu ($tone)', (WidgetTester tester) async {
      await shot(
        tester,
        missionPageApp(
          localController(signedIn: false),
          brightness: brightness,
        ),
        name: 'misi_tamu_$tone',
      );
    });

    testWidgets('misi menunggu pesanan selesai ($tone)', (
      WidgetTester tester,
    ) async {
      final LocalMissionController controller = localController(
        cart: <String, int>{'P39A06S01000007': 2, 'P39A06S01000044': 1},
      );
      controller
        ..placeOrder()
        ..shipOrder();
      await shot(
        tester,
        missionPageApp(controller, brightness: brightness),
        name: 'misi_menunggu_$tone',
      );
    });

    testWidgets('misi tahap 2 dengan voucher ($tone)', (
      WidgetTester tester,
    ) async {
      final LocalMissionController controller = localController(
        cart: <String, int>{'P39A06S01000007': 2, 'P39A06S01000044': 1},
      );
      controller
        ..placeOrder()
        ..completeOrder()
        ..acknowledgeCelebration();
      await controller.addToCart('P21F02C01000026');
      await shot(
        tester,
        missionPageApp(controller, brightness: brightness),
        name: 'misi_tahap2_$tone',
        size: _long,
      );
    });

    testWidgets('semua tahap selesai ($tone)', (WidgetTester tester) async {
      final LocalMissionController controller = localController(issuedCount: 2);
      await shot(
        tester,
        missionPageApp(controller, brightness: brightness),
        name: 'misi_tuntas_semua_$tone',
      );
    });
  }

  testWidgets('teks 200% di lebar 360', (WidgetTester tester) async {
    await shot(
      tester,
      missionPageApp(
        localController(cart: <String, int>{'P39A06S01000021': 1}),
        textScale: 2,
      ),
      name: 'misi_teks200',
      size: const Size(360, 1800),
    );
  });
}
