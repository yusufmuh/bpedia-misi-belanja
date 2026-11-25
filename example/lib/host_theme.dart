import 'package:flutter/material.dart';

/// `ColorScheme` host seperti `BpTheme` di `bpedia_app` (token SPEC-V3
/// §2.1.1–§2.1.2): permukaan putih/netral gelap, pink hanya aksen.
ColorScheme hostColorScheme(Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  final Color surface = dark
      ? const Color(0xFF1A181B)
      : const Color(0xFFFFFFFF);
  final Color brand = dark ? const Color(0xFFFF7AA0) : const Color(0xFFD81F57);
  final Color onBrand = dark
      ? const Color(0xFF2A0A18)
      : const Color(0xFFFFFFFF);
  final Color brandStrong = dark
      ? const Color(0xFFF9A2C1)
      : const Color(0xFFB3164B);
  final Color brandTint = dark
      ? const Color(0xFF3B1026)
      : const Color(0xFFFDE7EC);
  final Color goldTint = dark
      ? const Color(0xFF3A2C0A)
      : const Color(0xFFFFF4DB);
  final Color onGoldTint = dark
      ? const Color(0xFFFFD98A)
      : const Color(0xFF8A5A00);
  final Color danger = dark ? const Color(0xFFFF8A80) : const Color(0xFFC62828);
  final Color dangerTint = dark
      ? const Color(0xFF3A1414)
      : const Color(0xFFFDECEC);
  final Color muted = dark ? const Color(0xFF242126) : const Color(0xFFF3F3F5);
  final Color raised = dark ? const Color(0xFF242126) : const Color(0xFFFFFFFF);
  return ColorScheme(
    brightness: brightness,
    primary: brand,
    onPrimary: onBrand,
    primaryContainer: brandTint,
    onPrimaryContainer: brandStrong,
    secondary: brandStrong,
    onSecondary: dark ? onBrand : surface,
    secondaryContainer: brandTint,
    onSecondaryContainer: brandStrong,
    tertiary: onGoldTint,
    onTertiary: dark ? goldTint : surface,
    tertiaryContainer: goldTint,
    onTertiaryContainer: onGoldTint,
    error: danger,
    onError: dark ? dangerTint : surface,
    errorContainer: dangerTint,
    onErrorContainer: danger,
    surface: surface,
    onSurface: dark ? const Color(0xFFF4F0F2) : const Color(0xFF1F1A1D),
    onSurfaceVariant: dark ? const Color(0xFFB5ADB2) : const Color(0xFF6B6468),
    surfaceDim: dark ? const Color(0xFF0F0E10) : const Color(0xFFF5F5F7),
    surfaceBright: raised,
    surfaceContainerLowest: surface,
    surfaceContainerLow: surface,
    surfaceContainer: muted,
    surfaceContainerHigh: raised,
    surfaceContainerHighest: muted,
    outline: dark ? const Color(0xFF857D82) : const Color(0xFF9A9398),
    outlineVariant: dark ? const Color(0xFF2E2A30) : const Color(0xFFECECEF),
    shadow: const Color(0xFF000000),
  );
}

/// Tema host dengan Poppins.
ThemeData hostTheme(Brightness brightness) => ThemeData(
  fontFamily: 'Poppins',
  colorScheme: hostColorScheme(brightness),
  scaffoldBackgroundColor: brightness == Brightness.dark
      ? const Color(0xFF0F0E10)
      : const Color(0xFFF5F5F7),
);
