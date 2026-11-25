import 'package:flutter/material.dart';

/// Warna status SPEC-V3 §2.1.2 yang tidak ada di `ColorScheme` host.
///
/// Permukaan dan teks tetap dari `ColorScheme`; kelas ini hanya menambah
/// hijau berhasil, emas hadiah, biru info, dan merah diskon untuk kedua tema.
@immutable
final class MissionTones {
  const MissionTones._({
    required this.success,
    required this.successTint,
    required this.goldTint,
    required this.onGoldTint,
    required this.info,
    required this.infoTint,
    required this.sale,
    required this.onSale,
  });

  /// Nada untuk tema [context].
  factory MissionTones.of(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? _dark
      : _light;

  static const MissionTones _light = MissionTones._(
    success: Color(0xFF1E7A55),
    successTint: Color(0xFFE9F7F0),
    goldTint: Color(0xFFFFF4DB),
    onGoldTint: Color(0xFF8A5A00),
    info: Color(0xFF2F6FDE),
    infoTint: Color(0xFFEAF1FE),
    sale: Color(0xFFE5173F),
    onSale: Color(0xFFFFFFFF),
  );

  static const MissionTones _dark = MissionTones._(
    success: Color(0xFF5FD3A0),
    successTint: Color(0xFF12301F),
    goldTint: Color(0xFF3A2C0A),
    onGoldTint: Color(0xFFFFD98A),
    info: Color(0xFF8DB4FF),
    infoTint: Color(0xFF14233F),
    sale: Color(0xFFFF5C7A),
    onSale: Color(0xFF2A0A18),
  );

  /// Hijau berhasil.
  final Color success;

  /// Latar lembut hijau.
  final Color successTint;

  /// Latar lembut emas (hadiah).
  final Color goldTint;

  /// Teks di atas [goldTint].
  final Color onGoldTint;

  /// Biru status pengiriman.
  final Color info;

  /// Latar lembut biru.
  final Color infoTint;

  /// Merah lencana diskon.
  final Color sale;

  /// Teks di atas [sale].
  final Color onSale;
}
