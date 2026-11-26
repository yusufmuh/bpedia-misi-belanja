import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import '../support/mission_harness.dart';
import '../support/shot.dart';

void main() {
  testWidgets('strip tambah ke keranjang sampai target tercapai', (
    WidgetTester tester,
  ) async {
    final LocalMissionController controller = localController(
      cart: <String, int>{'P39A06S01000021': 2, 'P39A06S01000044': 1},
    );
    await pumpShot(tester, missionPageApp(controller));
    final Finder name = find.text('Animate Acne Solution Night Cream 10 g');
    await tester.scrollUntilVisible(
      name,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final Finder add = find.descendant(
      of: find.ancestor(of: name, matching: find.byType(MissionProductCard)),
      matching: find.text('Keranjang'),
    );
    await tester.runAsync<void>(() async {});
    await Scrollable.ensureVisible(tester.element(add), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 300));
    await settleImages(tester, rounds: 3);
    await tester.tap(add);
    await shotStrip(
      tester,
      'misi_strip_tambah',
      frames: 12,
      step: const Duration(milliseconds: 110),
    );
    expect(controller.state.phase, MissionPhase.ready);
  });

  for (final Brightness brightness in Brightness.values) {
    final String tone = brightness == Brightness.dark ? 'gelap' : 'terang';
    testWidgets('lembar misi tuntas ($tone)', (WidgetTester tester) async {
      final LocalMissionController controller = localController(
        cart: <String, int>{'P39A06S01000007': 2, 'P39A06S01000044': 1},
      );
      controller.placeOrder();
      await pumpShot(
        tester,
        missionPageApp(controller, brightness: brightness),
      );
      controller.completeOrder();
      await tester.pump();
      await tester.pump();
      if (brightness == Brightness.light) {
        await shotStrip(
          tester,
          'misi_strip_tuntas',
          frames: 12,
          step: const Duration(milliseconds: 130),
        );
      }
      await tester.pump(const Duration(milliseconds: 1800));
      await settleImages(tester, rounds: 3);
      await saveShot(tester, 'misi_lembar_tuntas_$tone');
      expect(find.text('Tahap 1 Misi Belanja selesai'), findsOneWidget);
    });
  }
}
