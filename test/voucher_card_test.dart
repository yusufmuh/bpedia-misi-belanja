import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';
import 'package:misi_belanja/src/widgets/ticket_shape.dart';

import 'support/test_app.dart';

void main() {
  final int issuedDay = wibDayOf(2026, 11, 24);
  final MissionVoucher voucher = MissionVoucher.issue(
    id: 'vch-1-BP-1001',
    stage: demoMissionStages[0],
    sourceOrderId: 'BP-1001',
    issuedDay: issuedDay,
  );
  final MissionVoucher used = voucher.markUsed('BP-2002');

  testWidgets('aktif: nominal, syarat, tanggal, chip Aktif, tombol Pakai', (
    WidgetTester tester,
  ) async {
    int uses = 0;
    await pumpInApp(
      tester,
      VoucherCard(voucher: voucher, today: issuedDay, onUse: () => uses++),
    );

    expect(find.text('Voucher'), findsOneWidget);
    expect(find.text('Rp10.000'), findsOneWidget);
    expect(find.text('Min. belanja Rp100.000'), findsOneWidget);
    expect(find.text('Berlaku s.d. 24 Des 2026'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('Pakai'));
    expect(uses, 1);
  });

  testWidgets('tepat di hari terakhir masih Aktif', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      VoucherCard(voucher: voucher, today: voucher.expiresDay, onUse: () {}),
    );

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Pakai'), findsOneWidget);
  });

  testWidgets('aktif tanpa onUse: tidak ada tombol Pakai', (
    WidgetTester tester,
  ) async {
    await pumpInApp(tester, VoucherCard(voucher: voucher, today: issuedDay));

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('terpakai: chip Terpakai tanpa tombol Pakai', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      VoucherCard(
        voucher: used,
        today: issuedDay,
        onUse: () => fail('Voucher terpakai tidak boleh bisa dipakai'),
      ),
    );

    expect(find.text('Terpakai'), findsOneWidget);
    expect(find.text('Aktif'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('kedaluwarsa: chip Kedaluwarsa tanpa tombol Pakai', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      VoucherCard(
        voucher: voucher,
        today: voucher.expiresDay + 1,
        onUse: () => fail('Voucher kedaluwarsa tidak boleh bisa dipakai'),
      ),
    );

    expect(find.text('Kedaluwarsa'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('terpakai lebih diutamakan daripada kedaluwarsa', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      VoucherCard(voucher: used, today: used.expiresDay + 5),
    );

    expect(find.text('Terpakai'), findsOneWidget);
    expect(find.text('Kedaluwarsa'), findsNothing);
  });

  testWidgets('semantics: kalimat ringkasan dan tombol berlabel', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpInApp(
      tester,
      VoucherCard(voucher: voucher, today: issuedDay, onUse: () {}),
    );

    expect(
      find.bySemanticsLabel(
        'Voucher Rp10.000 dari Misi Belanja Tahap 1. Minimal belanja '
        'Rp100.000. Berlaku sampai 24 Desember 2026. Status: aktif.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Pakai voucher Rp10.000'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('semantics status terpakai dan kedaluwarsa', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpInApp(
      tester,
      Column(
        children: <Widget>[
          VoucherCard(voucher: used, today: issuedDay),
          VoucherCard(voucher: voucher, today: voucher.expiresDay + 1),
        ],
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp(r'Status: terpakai\.$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Status: kedaluwarsa\.$')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('tanpa overflow pada teks 200% di 360x740', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      Column(
        children: <Widget>[
          VoucherCard(voucher: voucher, today: issuedDay, onUse: () {}),
          const SizedBox(height: 12),
          VoucherCard(voucher: used, today: issuedDay),
          const SizedBox(height: 12),
          VoucherCard(voucher: voucher, today: voucher.expiresDay + 1),
        ],
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Pakai'), findsOneWidget);
    expect(find.text('Terpakai'), findsOneWidget);
    expect(find.text('Kedaluwarsa'), findsOneWidget);
  });

  testWidgets('teks 200%: stub pindah ke atas dan nominal tidak mengecil', (
    WidgetTester tester,
  ) async {
    Axis dividerAxis() {
      final ClipPath clip = tester.widget<ClipPath>(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is ClipPath && widget.clipper is TicketClipper,
        ),
      );
      return (clip.clipper! as TicketClipper).axis;
    }

    final Widget card = VoucherCard(
      voucher: voucher,
      today: issuedDay,
      onUse: () {},
    );

    const Size tablet = Size(600, 900);
    await pumpInApp(tester, card, screen: tablet);
    expect(dividerAxis(), Axis.vertical);
    expect(tester.takeException(), isNull);
    final double normalHeight = tester.getRect(find.text('Rp10.000')).height;

    await pumpInApp(tester, card, textScale: 2, screen: tablet);
    expect(dividerAxis(), Axis.horizontal);
    expect(
      tester.getRect(find.text('Rp10.000')).height,
      greaterThanOrEqualTo(normalHeight * 1.9),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lebar tak terbatas memakai lebar cadangan', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: VoucherCard(voucher: voucher, today: issuedDay, onUse: () {}),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(VoucherCard)).width, 340);
  });

  testWidgets('tema gelap dan layar 320 dp tanpa overflow', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      VoucherCard(voucher: voucher, today: issuedDay, onUse: () {}),
      textScale: 2,
      screen: const Size(320, 640),
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
