import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'support/mission_harness.dart';
import 'support/test_app.dart';

void main() {
  final MissionProduct patch = stageTwoProducts.first;

  group('MissionProductCard', () {
    testWidgets('jumlah 0: pita Misi, harga, coret, diskon, tombol tambah', (
      WidgetTester tester,
    ) async {
      int added = 0;
      await pumpInApp(
        tester,
        SizedBox(
          width: 180,
          child: MissionProductCard(
            product: patch,
            quantity: 0,
            onAdd: () => added++,
            onQuantityChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Misi'), findsOneWidget);
      expect(find.text('Rp10.000'), findsOneWidget);
      expect(find.text('Rp11.500'), findsOneWidget);
      expect(find.text('-13%'), findsOneWidget);
      await tester.tap(find.text('Keranjang'));
      expect(added, 1);
      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('jumlah > 0: stepper menggantikan tombol tambah', (
      WidgetTester tester,
    ) async {
      final List<int> changes = <int>[];
      await pumpInApp(
        tester,
        SizedBox(
          width: 180,
          child: MissionProductCard(
            product: patch,
            quantity: 2,
            onAdd: () {},
            onQuantityChanged: changes.add,
          ),
        ),
      );
      expect(find.text('Keranjang'), findsNothing);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));
      expect(changes, <int>[3, 1]);
    });

    testWidgets('jumlah 1: tombol kurang menjadi hapus', (
      WidgetTester tester,
    ) async {
      final List<int> changes = <int>[];
      await pumpInApp(
        tester,
        SizedBox(
          width: 180,
          child: MissionProductCard(
            product: patch,
            quantity: 1,
            onAdd: () {},
            onQuantityChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(changes, <int>[0]);
    });

    testWidgets('batas jumlah menonaktifkan tambah', (
      WidgetTester tester,
    ) async {
      final List<int> changes = <int>[];
      await pumpInApp(
        tester,
        QtyStepper(quantity: 1, max: 1, onChanged: changes.add),
      );
      await tester.tap(find.byIcon(Icons.add));
      expect(changes, isEmpty);
    });

    testWidgets('semantics: kartu dan tombol berlabel, target sentuh 48', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final List<String> opened = <String>[];
      await pumpInApp(
        tester,
        SizedBox(
          width: 180,
          child: MissionProductCard(
            product: patch,
            quantity: 0,
            onAdd: () {},
            onQuantityChanged: (_) {},
            onOpen: () => opened.add(patch.code),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Tambah ${patch.name} ke keranjang'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Lihat ')));
      expect(opened, <String>[patch.code]);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('teks 200% tanpa luapan di kolom grid 160', (
      WidgetTester tester,
    ) async {
      await pumpInApp(
        tester,
        Row(
          children: <Widget>[
            for (final int quantity in <int>[0, 3])
              SizedBox(
                width: 160,
                child: MissionProductCard(
                  product: patch,
                  quantity: quantity,
                  onAdd: () {},
                  onQuantityChanged: (_) {},
                ),
              ),
          ],
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('MissionProgressTrack', () {
    testWidgets('angka, pesan, dan semantics nilai', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const MissionProgressTrack(
          progress: MissionProgress(current: 45000, target: 75000),
          label: 'Produk misi di keranjang',
          message: 'Tambah Rp30.000 lagi',
        ),
      );
      expect(find.text('Tambah Rp30.000 lagi'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(
        find.byType(MissionProgressTrack),
      );
      expect(node.label, startsWith('Produk misi di keranjang'));
      expect(node.value, 'Rp45.000 dari Rp75.000');
      semantics.dispose();
    });

    testWidgets('bertambah memicu denyut lalu selesai tanpa ticker bocor', (
      WidgetTester tester,
    ) async {
      Widget track(int current) => MissionProgressTrack(
        progress: MissionProgress(current: current, target: 75000),
        label: 'Produk misi di keranjang',
        message: 'x',
        showWalker: false,
      );
      await pumpInApp(tester, track(10000), disableAnimations: false);
      await pumpInApp(tester, track(60000), disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('melewati target tidak meluap dan teks 200% aman', (
      WidgetTester tester,
    ) async {
      await pumpInApp(
        tester,
        const MissionProgressTrack(
          progress: MissionProgress(current: 90000, target: 75000),
          label: 'Produk misi di keranjang',
          message: 'Target tercapai. Siap checkout, Babes!',
          success: true,
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('MissionHowTo', () {
    testWidgets('tiga langkah dengan target', (WidgetTester tester) async {
      await pumpInApp(tester, const MissionHowTo(targetLabel: 'Rp75.000'));
      expect(find.text('Pilih produk misi'), findsOneWidget);
      expect(find.text('Capai target'), findsOneWidget);
      expect(find.text('Terima voucher'), findsOneWidget);
      expect(find.textContaining('Rp75.000'), findsOneWidget);
    });

    testWidgets('huruf besar berganti daftar tegak tanpa luapan', (
      WidgetTester tester,
    ) async {
      await pumpInApp(
        tester,
        const MissionHowTo(targetLabel: 'Rp75.000'),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final double first = tester.getTopLeft(find.text('Pilih produk misi')).dy;
      final double second = tester.getTopLeft(find.text('Capai target')).dy;
      expect(second, greaterThan(first));
    });
  });

  group('StatusPill dan LivelyPose', () {
    testWidgets('semua nada tampil di kedua tema', (WidgetTester tester) async {
      for (final Brightness brightness in Brightness.values) {
        await pumpInApp(
          tester,
          Wrap(
            children: <Widget>[
              for (final StatusTone tone in StatusTone.values)
                StatusPill(label: tone.name, tone: tone, icon: Icons.check),
            ],
          ),
          brightness: brightness,
        );
        expect(find.text('success'), findsOneWidget);
      }
    });

    testWidgets('pose diam saat kurangi gerak', (WidgetTester tester) async {
      await pumpInApp(
        tester,
        const LivelyPose(image: MissionArt.poseCheer, height: 80),
      );
      expect(
        find.descendant(
          of: find.byType(LivelyPose),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });

    testWidgets('pose bergerak lalu berhenti saat dilepas', (
      WidgetTester tester,
    ) async {
      await pumpInApp(
        tester,
        const LivelyPose(image: MissionArt.poseParty, height: 80, energy: 2),
        disableAnimations: false,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.descendant(
          of: find.byType(LivelyPose),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
      expect(LivelyPose.springAt(0), -1);
      expect(LivelyPose.springAt(3).abs(), lessThan(0.01));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
