import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Light ColorScheme of the Bpedia Preview host (SPEC-CONTRACT section 3).
const ColorScheme brandLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFD81F57),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFDE7EC),
  onPrimaryContainer: Color(0xFF45122B),
  secondary: Color(0xFFB3164B),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFBCFDB),
  onSecondaryContainer: Color(0xFF45122B),
  tertiary: Color(0xFFF5B83D),
  onTertiary: Color(0xFF2A0A18),
  tertiaryContainer: Color(0xFFFFF4DB),
  onTertiaryContainer: Color(0xFF8A5A00),
  error: Color(0xFFC62828),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFFFF7F8),
  onSurface: Color(0xFF45122B),
  onSurfaceVariant: Color(0xFF6E4556),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFF7F8),
  surfaceContainer: Color(0xFFFDE7EC),
  outline: Color(0xFF9C7E8A),
  outlineVariant: Color(0xFFF3D3DD),
);

/// Host-like theme for [brightness].
ThemeData brandTheme(Brightness brightness) => ThemeData(
  colorScheme: brightness == Brightness.light
      ? brandLightScheme
      : ColorScheme.fromSeed(
          seedColor: brandLightScheme.primary,
          brightness: Brightness.dark,
        ),
);

/// Pumps [child] in a scrollable phone-sized screen, as the hub does.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  Size screen = const Size(360, 740),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: brandTheme(brightness),
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// WIB day number of a calendar date.
int wibDayOf(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;
