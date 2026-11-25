import 'package:flutter/material.dart';

import '../kit/kit.dart';
import '../mission_assets.dart';
import '../mission_products.dart';
import '../rupiah.dart';
import 'mission_tones.dart';

/// Bar progres tebal menuju target tahap: Bipy berjalan di ujung isian,
/// bendera di garis akhir, isian berdenyut tiap kali bertambah, dan berubah
/// hijau saat target tercapai.
///
/// Kurangi gerak: isian langsung ke nilai akhir dan sprite diam.
class MissionProgressTrack extends StatefulWidget {
  /// Membuat bar untuk [progress].
  const MissionProgressTrack({
    super.key,
    required this.progress,
    required this.label,
    required this.message,
    this.messageIcon,
    this.success = false,
    this.showWalker = true,
  });

  /// Nilai sekarang dan target (rupiah).
  final MissionProgress progress;

  /// Judul kecil di atas bar, mis. "Produk misi di keranjang".
  final String label;

  /// Kalimat di bawah bar, mis. "Tambah Rp30.000 lagi".
  final String message;

  /// Ikon di depan [message].
  final IconData? messageIcon;

  /// Warna berhasil (hijau) untuk isian dan [message].
  final bool success;

  /// Menampilkan Bipy berjalan di ujung isian.
  final bool showWalker;

  /// Tinggi bar (dp).
  static const double barHeight = 16;

  /// Tinggi sprite Bipy (dp).
  static const double walkerHeight = 58;

  @override
  State<MissionProgressTrack> createState() => _MissionProgressTrackState();
}

class _MissionProgressTrackState extends State<MissionProgressTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(MissionProgressTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress.current > oldWidget.progress.current &&
        !reduceMotionOf(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    final bool reduce = reduceMotionOf(context);
    final MissionProgress progress = widget.progress;
    final Color accent = widget.success ? tones.success : scheme.primary;
    final IconData? icon = widget.messageIcon;
    final TextStyle figures = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Semantics(
      container: true,
      label: widget.label,
      value: '${rupiah(progress.current)} dari ${rupiah(progress.target)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: <Widget>[
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: rupiah(progress.current),
                        style: figures.copyWith(color: accent),
                      ),
                      TextSpan(text: ' / ${rupiah(progress.target)}'),
                    ],
                  ),
                  style: figures,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress.fraction),
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 760),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double fraction, Widget? _) {
                return AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, Widget? child) => _Track(
                    fraction: fraction,
                    pulse: _pulse.value,
                    success: widget.success,
                    showWalker: widget.showWalker,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w600,
                    color: widget.success ? tones.success : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.fraction,
    required this.pulse,
    required this.success,
    required this.showWalker,
  });

  final double fraction;
  final double pulse;
  final bool success;
  final bool showWalker;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    const double bar = MissionProgressTrack.barHeight;
    const double walker = MissionProgressTrack.walkerHeight;
    const double flag = 34;
    final double walkerWidth =
        walker *
        MissionSprites.walk.frameSize.width /
        MissionSprites.walk.frameSize.height;
    final double swell = Curves.easeOut.transform(
      pulse < 0.35 ? pulse / 0.35 : (1 - pulse) / 0.65,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double trackWidth = width - flag * 0.55;
        final double fillWidth = (trackWidth * fraction).clamp(0, trackWidth);
        final double walkerLeft = (fillWidth - walkerWidth / 2).clamp(
          0,
          trackWidth - walkerWidth * 0.8,
        );
        return SizedBox(
          height: walker + bar / 2 + 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                width: trackWidth,
                bottom: 0,
                height: bar,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(bar),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
              ),
              if (fillWidth > 0)
                Positioned(
                  left: 0,
                  bottom: -swell * 2,
                  width: fillWidth.clamp(bar, trackWidth),
                  height: bar + swell * 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(bar),
                      gradient: success
                          ? LinearGradient(
                              colors: <Color>[
                                tones.success.withValues(alpha: 0.8),
                                tones.success,
                              ],
                            )
                          : const LinearGradient(
                              colors: <Color>[
                                FestivePalette.candyTop,
                                FestivePalette.candyBottom,
                              ],
                            ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: (success ? tones.success : scheme.primary)
                              .withValues(alpha: 0.25 + swell * 0.35),
                          blurRadius: 6 + swell * 10,
                        ),
                      ],
                    ),
                    child: const CustomPaint(painter: _StripePainter()),
                  ),
                ),
              const Positioned(
                right: 0,
                bottom: -2,
                width: flag,
                height: flag,
                child: Image(image: MissionArt.flag, fit: BoxFit.contain),
              ),
              if (showWalker)
                Positioned(
                  left: walkerLeft,
                  bottom: bar * 0.55,
                  width: walkerWidth,
                  height: walker,
                  child: const SpriteAnimation(
                    spec: MissionSprites.walk,
                    height: walker,
                    semanticLabel: 'Bipy',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Garis miring tipis pada isian bar, supaya terasa seperti permen.
class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final RRect clip = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height),
    );
    canvas
      ..save()
      ..clipRRect(clip);
    final Paint stripe = Paint()
      ..color = const Color(0x2EFFFFFF)
      ..strokeWidth = 5;
    for (double x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3, 2, size.width - 6, size.height * 0.32),
          Radius.circular(size.height),
        ),
        Paint()..color = const Color(0x40FFFFFF),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
