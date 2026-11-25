import 'package:flutter/material.dart';

import '../kit/kit.dart';
import '../mission_assets.dart';
import '../mission_stage.dart';
import '../rupiah.dart';
import 'mission_tones.dart';
import 'status_pill.dart';

/// Tangga tahap Misi Belanja: jalur horizontal bernomor (lingkaran, garis
/// penghubung, nominal voucher tiap tahap) lalu kartu tiap tahap dengan
/// target, kupon hadiah, dan status.
///
/// Status tahap memakai aturan murni [stageStatus]. Tahap aktif boleh
/// diberi label fase dari halaman ([activeStatus], mis. "Di keranjang").
class MissionLadder extends StatelessWidget {
  /// Membuat tangga untuk [stages] dengan [issuedCount] voucher terbit.
  const MissionLadder({
    super.key,
    required this.stages,
    required this.issuedCount,
    this.pendingNote,
    this.activeStatus,
    this.activeTone = StatusTone.brand,
  });

  /// Tahap kampanye berurutan.
  final List<MissionStage> stages;

  /// Jumlah voucher misi yang sudah terbit.
  final int issuedCount;

  /// Catatan pesanan berjalan, tampil di bawah tahap aktif saja.
  final String? pendingNote;

  /// Label status tahap aktif. Bawaan "Aktif".
  final String? activeStatus;

  /// Nada pil status tahap aktif.
  final StatusTone activeTone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool allDone = allStagesDone(
      stages: stages,
      issuedCount: issuedCount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (stages.isNotEmpty) ...<Widget>[
          ExcludeSemantics(
            child: _StageTrack(stages: stages, issuedCount: issuedCount),
          ),
          const SizedBox(height: 14),
        ],
        for (int index = 0; index < stages.length; index++) ...<Widget>[
          _StageCard(
            stage: stages[index],
            previous: index == 0 ? null : stages[index - 1],
            status: stageStatus(stageIndex: index, issuedCount: issuedCount),
            pendingNote: pendingNote,
            activeStatus: activeStatus ?? 'Aktif',
            activeTone: activeTone,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: <Widget>[
            Icon(
              allDone && stages.isNotEmpty
                  ? Icons.emoji_events_rounded
                  : Icons.more_horiz_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                allDone && stages.isNotEmpty
                    ? 'Semua tahap selesai. Tahap berikutnya menunggu kampanye.'
                    : 'Tahap berikutnya menunggu kampanye',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StageTrack extends StatelessWidget {
  const _StageTrack({required this.stages, required this.issuedCount});

  final List<MissionStage> stages;
  final int issuedCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int nodes = stages.length + 1;
    Widget line(bool done) => Expanded(
      child: SizedBox(
        height: 4,
        child: ColoredBox(color: done ? scheme.primary : scheme.outlineVariant),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int index = 0; index < nodes; index++)
          Expanded(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 44,
                  child: Row(
                    children: <Widget>[
                      if (index == 0)
                        const Spacer()
                      else
                        line(index - 1 < issuedCount),
                      _StageNode(
                        number: index + 1,
                        status: index < stages.length
                            ? stageStatus(
                                stageIndex: index,
                                issuedCount: issuedCount,
                              )
                            : null,
                      ),
                      if (index == nodes - 1)
                        const Spacer()
                      else
                        line(index < issuedCount),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  index < stages.length
                      ? rupiah(stages[index].voucherAmount)
                      : 'Segera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: index == issuedCount
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: index == issuedCount && index < stages.length
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({required this.number, required this.status});

  final int number;

  /// `null` = simpul "Segera" (tahap kampanye berikutnya).
  final StageStatus? status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    const double size = 40;
    return switch (status) {
      StageStatus.completed => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: tones.success, shape: BoxShape.circle),
        child: Icon(Icons.check_rounded, color: scheme.surface, size: 24),
      ),
      StageStatus.active => Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          gradient: FestivePalette.candy,
          shape: BoxShape.circle,
          border: Border.all(color: FestivePalette.goldLight, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x40D81F57),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          textScaler: TextScaler.noScaling,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      StageStatus.locked => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(
          Icons.lock_rounded,
          color: scheme.onSurfaceVariant,
          size: 18,
        ),
      ),
      null => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
        ),
        padding: const EdgeInsets.all(7),
        child: const Opacity(
          opacity: 0.55,
          child: Image(image: MissionArt.flag, fit: BoxFit.contain),
        ),
      ),
    };
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.previous,
    required this.status,
    required this.pendingNote,
    required this.activeStatus,
    required this.activeTone,
  });

  final MissionStage stage;
  final MissionStage? previous;
  final StageStatus status;
  final String? pendingNote;
  final String activeStatus;
  final StatusTone activeTone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    final bool active = status == StageStatus.active;
    final String? note = active ? pendingNote : null;
    final String lockNote =
        'Terbuka setelah voucher ${previous?.title ?? 'tahap sebelumnya'} '
        'terbit';
    final String statusLabel = switch (status) {
      StageStatus.completed => 'Selesai',
      StageStatus.active => activeStatus,
      StageStatus.locked => 'Terkunci',
    };
    final String target =
        'Belanja produk misi min. ${rupiah(stage.minOrderSubtotal)} '
        'dalam 1 pesanan';
    final String reward =
        'Voucher ${rupiah(stage.voucherAmount)} · min. belanja '
        '${rupiah(stage.voucherMinSpend)} · berlaku '
        '${stage.voucherValidDays} hari';
    final StringBuffer summary = StringBuffer()
      ..write('${stage.title}, $statusLabel. ')
      ..write(
        'Belanja produk misi minimal ${rupiah(stage.minOrderSubtotal)} '
        'dalam 1 pesanan. ',
      )
      ..write(
        'Hadiah voucher ${rupiah(stage.voucherAmount)}, minimal belanja '
        '${rupiah(stage.voucherMinSpend)}, berlaku '
        '${stage.voucherValidDays} hari.',
      );
    if (status == StageStatus.locked) summary.write(' $lockNote.');
    if (note != null) summary.write(' $note');
    final Color muted = scheme.onSurfaceVariant;
    return MergeSemantics(
      child: Semantics(
        label: summary.toString(),
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? scheme.surface : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        stage.title,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      StatusPill(
                        label: statusLabel,
                        tone: switch (status) {
                          StageStatus.completed => StatusTone.success,
                          StageStatus.active => activeTone,
                          StageStatus.locked => StatusTone.neutral,
                        },
                        icon: switch (status) {
                          StageStatus.completed => Icons.check_circle_rounded,
                          StageStatus.active => null,
                          StageStatus.locked => Icons.lock_rounded,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target,
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: active ? scheme.onSurface : muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: tones.goldTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                      child: Row(
                        children: <Widget>[
                          Opacity(
                            opacity: status == StageStatus.locked ? 0.6 : 1,
                            child: const Image(
                              image: MissionArt.ticket,
                              width: 30,
                              height: 30,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reward,
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w600,
                                color: tones.onGoldTint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (status == StageStatus.locked) ...<Widget>[
                    const SizedBox(height: 8),
                    _NoteRow(
                      icon: Icons.lock_clock_rounded,
                      text: lockNote,
                      color: muted,
                    ),
                  ],
                  if (note != null) ...<Widget>[
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: tones.infoTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _NoteRow(
                          icon: Icons.local_shipping,
                          text: note,
                          color: tones.info,
                          textColor: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.icon,
    required this.text,
    required this.color,
    this.textColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: textColor ?? color,
            ),
          ),
        ),
      ],
    );
  }
}
