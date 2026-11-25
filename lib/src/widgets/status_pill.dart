import 'package:flutter/material.dart';

import 'mission_tones.dart';

/// Nada warna [StatusPill].
enum StatusTone {
  /// Pink lembut: aktif, di keranjang.
  brand,

  /// Hijau: selesai, siap checkout.
  success,

  /// Emas: hadiah, menunggu.
  gold,

  /// Biru: pesanan sedang diproses.
  info,

  /// Netral: terkunci, kedaluwarsa, terpakai.
  neutral,
}

/// Pil status kecil berikon (tinggi 24 pada skala 100%).
class StatusPill extends StatelessWidget {
  /// Membuat pil berlabel [label] dengan nada [tone].
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.brand,
    this.icon,
  });

  /// Teks status.
  final String label;

  /// Nada warna.
  final StatusTone tone;

  /// Ikon kecil di depan teks.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    final (Color background, Color foreground) = switch (tone) {
      StatusTone.brand => (scheme.primaryContainer, scheme.onPrimaryContainer),
      StatusTone.success => (tones.successTint, tones.success),
      StatusTone.gold => (tones.goldTint, tones.onGoldTint),
      StatusTone.info => (tones.infoTint, tones.info),
      StatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    final IconData? glyph = icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (glyph != null) ...<Widget>[
              Icon(glyph, size: 13, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
