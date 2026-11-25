import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kit/kit.dart';
import '../mission_assets.dart';
import '../mission_stage.dart';
import '../mission_view.dart';
import '../rupiah.dart';

/// Menampilkan lembar "Misi tuntas" untuk [celebration]: kupon tiket jatuh
/// dari atas dan memantul, konfeti, Bipy berjalan lalu melambai, nominal
/// voucher naik dari nol, aksi "Lihat voucher" dan "Lanjut tahap N".
///
/// [onSeeVoucher] dan [onNextStage] dipanggil setelah lembar ditutup.
Future<void> showMissionCompleteSheet(
  BuildContext context, {
  required MissionCelebration celebration,
  required VoidCallback onSeeVoucher,
  VoidCallback? onNextStage,
}) {
  final MissionStage stage = celebration.stage;
  final MissionStage? next = celebration.nextStage;
  final VoidCallback? nextAction = onNextStage;
  return showResultSheet<void>(
    context,
    builder: (BuildContext sheet) => ResultSheet(
      ribbon: 'Misi tuntas!',
      title: '${stage.title} selesai',
      pill: 'Voucher belanja',
      art: const SizedBox.square(dimension: 150, child: TicketDrop()),
      companion: const MissionWaveCompanion(height: 112),
      amount: celebration.voucher.amount,
      amountPrefix: 'Rp',
      caption: 'Voucher ${rupiah(celebration.voucher.amount)} jadi milikmu',
      message:
          'Pakai di checkout berikutnya (min. belanja '
          '${rupiah(celebration.voucher.minSpend)}).',
      note: 'Berlaku ${stage.voucherValidDays} hari',
      primaryVariant: CandyVariant.gold,
      primaryLabel: 'Lihat voucher',
      onPrimary: () {
        Navigator.of(sheet).pop();
        onSeeVoucher();
      },
      secondaryLabel: next != null && nextAction != null
          ? 'Lanjut ${next.title.toLowerCase()}'
          : null,
      onSecondary: next != null && nextAction != null
          ? () {
              Navigator.of(sheet).pop();
              nextAction();
            }
          : null,
    ),
  );
}

/// Kupon tiket 3D yang jatuh dari atas, memantul, lalu berayun pelan.
/// Kurangi gerak: tiket langsung diam di tempat.
class TicketDrop extends StatefulWidget {
  /// Membuat tiket jatuh.
  const TicketDrop({super.key});

  @override
  State<TicketDrop> createState() => _TicketDropState();
}

class _TicketDropState extends State<TicketDrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotionOf(context)) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: const Image(
        image: MissionArt.ticket,
        fit: BoxFit.contain,
        semanticLabel: 'Kupon voucher',
      ),
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final double fall = Curves.bounceOut.transform(
          (t / 0.8).clamp(0.0, 1.0),
        );
        final double settle = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
        final double swing =
            math.sin(settle * math.pi * 3) * (1 - settle) * 0.12;
        return Opacity(
          opacity: (t / 0.12).clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..translateByDouble(0, (1 - fall) * -170, 0, 1)
              ..rotateZ(-0.18 * (1 - fall) + swing),
            child: child,
          ),
        );
      },
    );
  }
}

/// Bipy berjalan membawa tas, lalu berganti melambai setelah [delay].
class MissionWaveCompanion extends StatefulWidget {
  /// Membuat pendamping setinggi [height].
  const MissionWaveCompanion({
    super.key,
    required this.height,
    this.delay = const Duration(milliseconds: 1100),
  });

  /// Tinggi sprite (dp).
  final double height;

  /// Jeda sebelum melambai.
  final Duration delay;

  @override
  State<MissionWaveCompanion> createState() => _MissionWaveCompanionState();
}

class _MissionWaveCompanionState extends State<MissionWaveCompanion> {
  final SpriteController _sprite = SpriteController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _sprite.play(MissionSprites.wave, returnToBase: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sprite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpriteAnimation(
      spec: MissionSprites.walk,
      controller: _sprite,
      height: widget.height,
      semanticLabel: 'Bipy melambai',
    );
  }
}
