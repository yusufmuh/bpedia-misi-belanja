import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'support/host_theme.dart';
import 'support/test_app.dart';
import 'support/v2_fixtures.dart';

const String _note =
    'Pesanan BP-1002 senilai Rp120.000 sedang dikirim. Tekan Pesanan Diterima '
    'setelah barang sampai.';

Future<void> _pumpLadder(
  WidgetTester tester,
  int issuedCount, {
  String? pendingNote,
  double textScale = 1,
  Size screen = const Size(360, 740),
  Brightness brightness = Brightness.light,
}) => pumpInApp(
  tester,
  MissionLadder(
    stages: v2MissionStages,
    issuedCount: issuedCount,
    pendingNote: pendingNote,
  ),
  textScale: textScale,
  screen: screen,
  brightness: brightness,
);

String _stageLabel(WidgetTester tester, int number) =>
    tester.getSemantics(find.text('Tahap $number')).label;

final ColorScheme _scheme = hostColorScheme(Brightness.light);

Finder _connectors(Color color) => find.descendant(
  of: find.byType(MissionLadder),
  matching: find.byWidgetPredicate(
    (Widget widget) => widget is ColoredBox && widget.color == color,
  ),
);

void main() {
  testWidgets('issuedCount 0: Tahap 1 Aktif, Tahap 2 Terkunci', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pumpLadder(tester, 0);

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Terkunci'), findsOneWidget);
    expect(find.text('Selesai'), findsNothing);
    expect(
      find.text('Belanja produk misi min. Rp75.000 dalam 1 pesanan'),
      findsOneWidget,
    );
    expect(
      find.text('Voucher Rp10.000 · min. belanja Rp100.000 · berlaku 30 hari'),
      findsOneWidget,
    );
    expect(
      find.text('Belanja produk misi min. Rp100.000 dalam 1 pesanan'),
      findsOneWidget,
    );
    expect(
      find.text('Voucher Rp5.000 · min. belanja Rp100.000 · berlaku 30 hari'),
      findsOneWidget,
    );
    expect(find.text('Terbuka setelah voucher Tahap 1 terbit'), findsOneWidget);
    expect(find.text('Tahap berikutnya menunggu kampanye'), findsOneWidget);

    expect(
      _stageLabel(tester, 1),
      allOf(
        contains('Tahap 1'),
        contains('Aktif'),
        contains('minimal Rp75.000'),
        contains('voucher Rp10.000'),
      ),
    );
    expect(
      _stageLabel(tester, 2),
      allOf(
        contains('Terkunci'),
        contains('Terbuka setelah voucher Tahap 1 terbit'),
      ),
    );
    semantics.dispose();
  });

  testWidgets('issuedCount 1: Tahap 1 Selesai, Tahap 2 Aktif', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pumpLadder(tester, 1);

    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Terkunci'), findsNothing);
    expect(find.text('Terbuka setelah voucher Tahap 1 terbit'), findsNothing);
    expect(find.text('Tahap berikutnya menunggu kampanye'), findsOneWidget);
    expect(_stageLabel(tester, 1), contains('Selesai'));
    expect(_stageLabel(tester, 2), contains('Aktif'));
    semantics.dispose();
  });

  testWidgets('issuedCount 2: semua Selesai dan menunggu kampanye', (
    WidgetTester tester,
  ) async {
    await _pumpLadder(tester, 2);

    expect(find.text('Selesai'), findsNWidgets(2));
    expect(find.text('Aktif'), findsNothing);
    expect(find.text('Terkunci'), findsNothing);
    expect(
      find.text('Semua tahap selesai. Tahap berikutnya menunggu kampanye.'),
      findsOneWidget,
    );
    expect(find.text('Tahap berikutnya menunggu kampanye'), findsNothing);
  });

  testWidgets('garis penghubung primary setelah tahap selesai', (
    WidgetTester tester,
  ) async {
    await _pumpLadder(tester, 1);

    expect(_connectors(_scheme.primary), findsNWidgets(2));
    expect(_connectors(_scheme.outlineVariant), findsNWidgets(2));
  });

  testWidgets('satu MergeSemantics per tahap', (WidgetTester tester) async {
    await _pumpLadder(tester, 0);

    expect(
      find.descendant(
        of: find.byType(MissionLadder),
        matching: find.byType(MergeSemantics),
      ),
      findsNWidgets(v2MissionStages.length),
    );
  });

  testWidgets('pendingNote tampil di bawah tahap aktif saja', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pumpLadder(tester, 1, pendingNote: _note);

    expect(find.text(_note), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    expect(_stageLabel(tester, 2), contains(_note));
    expect(_stageLabel(tester, 1), isNot(contains(_note)));
    semantics.dispose();
  });

  testWidgets('pendingNote disembunyikan saat semua tahap selesai', (
    WidgetTester tester,
  ) async {
    await _pumpLadder(tester, 2, pendingNote: _note);

    expect(find.text(_note), findsNothing);
  });

  testWidgets('kontras teks memenuhi pedoman', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pumpLadder(tester, 1, pendingNote: _note);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  for (final int issuedCount in <int>[0, 1, 2]) {
    testWidgets('tanpa overflow pada teks 200% di 360x740 '
        '(issuedCount $issuedCount)', (WidgetTester tester) async {
      await _pumpLadder(tester, issuedCount, pendingNote: _note, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Tahap 1'), findsOneWidget);
    });
  }

  testWidgets('tanpa overflow di layar 320 dp dan tema gelap', (
    WidgetTester tester,
  ) async {
    await _pumpLadder(
      tester,
      0,
      pendingNote: _note,
      textScale: 2,
      screen: const Size(320, 640),
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('kampanye tanpa tahap hanya menampilkan baris kampanye', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      const MissionLadder(stages: <MissionStage>[], issuedCount: 0),
    );

    expect(find.text('Tahap berikutnya menunggu kampanye'), findsOneWidget);
    expect(find.byType(MergeSemantics), findsNothing);
  });
}
