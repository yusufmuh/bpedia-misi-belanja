import 'package:flutter/material.dart';

import '../mission_assets.dart';

/// Tiga langkah "Cara main" berseni 3D: tambah produk misi, checkout dalam
/// satu pesanan, terima voucher setelah pesanan selesai.
///
/// Berbaris mendatar; pada huruf besar (≥ 130%) berganti menjadi daftar
/// tegak supaya teks tidak terjepit.
class MissionHowTo extends StatelessWidget {
  /// Membuat langkah dengan target [minSubtotal] (teks rupiah sudah jadi).
  const MissionHowTo({super.key, required this.targetLabel});

  /// Target tahap aktif, mis. "Rp75.000".
  final String targetLabel;

  @override
  Widget build(BuildContext context) {
    final List<(ImageProvider, String, String)> steps =
        <(ImageProvider, String, String)>[
          (
            MissionArt.bag,
            'Pilih produk misi',
            'Tambah produk berpita Misi ke keranjang.',
          ),
          (
            MissionArt.flag,
            'Capai target',
            'Checkout produk misi min. $targetLabel dalam 1 pesanan.',
          ),
          (
            MissionArt.ticket,
            'Terima voucher',
            'Voucher masuk setelah pesanan berstatus Selesai.',
          ),
        ];
    final bool stacked = MediaQuery.textScalerOf(context).scale(14) > 18;
    if (stacked) {
      return Column(
        children: <Widget>[
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _StepArt(image: steps[i].$1, number: i + 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StepText(title: steps[i].$2, body: steps[i].$3),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          Expanded(
            child: Column(
              children: <Widget>[
                _StepArt(image: steps[i].$1, number: i + 1),
                const SizedBox(height: 8),
                _StepText(title: steps[i].$2, body: steps[i].$3, center: true),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepArt extends StatelessWidget {
  const _StepArt({required this.image, required this.number});

  final ImageProvider image;
  final int number;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Text(
                '$number',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({
    required this.title,
    required this.body,
    this.center = false,
  });

  final String title;
  final String body;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextAlign align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          textAlign: align,
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          textAlign: align,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
