import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'host_theme.dart';

/// Pumps [child] in a scrollable phone-sized screen, as the hub does.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  Size screen = const Size(360, 740),
  Brightness brightness = Brightness.light,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: hostTheme(brightness),
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
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
