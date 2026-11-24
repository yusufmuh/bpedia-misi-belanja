import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mission_stage.dart';
import '../rupiah.dart';
import 'status_pill.dart';

const double _indicatorSize = 32;
const double _indicatorTop = 12;
const double _lineWidth = 2;
const double _lineGap = 4;
const double _rowGap = 12;
const double _contentGap = 12;
const double _detailIconSize = 18;
const double _fallbackLineHeight = 1.4;

double _firstLineIconTop(
  BuildContext context,
  TextStyle? style,
  double iconSize,
) {
  final double fontSize = style?.fontSize ?? 14;
  final double lineHeight =
      MediaQuery.textScalerOf(context).scale(fontSize) *
      (style?.height ?? _fallbackLineHeight);
  return math.max(0, (lineHeight - iconSize) / 2);
}

/// Vertical timeline of mission stages ("Tahap 1", "Tahap 2", ...) followed by
/// a muted row saying the next stage awaits a campaign.
///
/// [issuedCount] is the number of stage vouchers issued so far. [pendingNote]
/// is shown under the active stage, for example when a qualifying order is
/// still being delivered.
class MissionLadder extends StatelessWidget {
  /// Creates the ladder.
  const MissionLadder({
    super.key,
    required this.stages,
    required this.issuedCount,
    this.pendingNote,
  });

  /// Stages in order; the first one is active until its voucher is issued.
  final List<MissionStage> stages;

  /// Number of stage vouchers issued so far.
  final int issuedCount;

  /// Optional note under the active stage.
  final String? pendingNote;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int issued = issuedCount < 0 ? 0 : issuedCount;
    final bool finished =
        stages.isNotEmpty && allStagesDone(stages: stages, issuedCount: issued);
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < stages.length; index++) {
      final StageStatus status = stageStatus(
        stageIndex: index,
        issuedCount: issued,
      );
      rows.add(
        MergeSemantics(
          child: _TimelineRow(
            indicator: _StageIndicator(
              number: stages[index].number,
              status: status,
            ),
            incomingColor: index == 0
                ? null
                : _lineColor(
                    scheme,
                    stageStatus(stageIndex: index - 1, issuedCount: issued),
                  ),
            outgoingColor: _lineColor(scheme, status),
            child: _StageCard(
              stage: stages[index],
              status: status,
              previousStageNumber: index == 0 ? null : stages[index - 1].number,
              pendingNote: status == StageStatus.active ? pendingNote : null,
            ),
          ),
        ),
      );
    }
    rows.add(
      _TimelineRow(
        indicator: _CampaignIndicator(finished: finished),
        incomingColor: stages.isEmpty
            ? null
            : _lineColor(
                scheme,
                stageStatus(stageIndex: stages.length - 1, issuedCount: issued),
              ),
        bottomGap: 0,
        child: _CampaignNote(finished: finished),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

Color _lineColor(ColorScheme scheme, StageStatus status) =>
    status == StageStatus.completed ? scheme.primary : scheme.outlineVariant;

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.indicator,
    required this.child,
    this.incomingColor,
    this.outgoingColor,
    this.bottomGap = _rowGap,
  });

  final Widget indicator;
  final Widget child;
  final Color? incomingColor;
  final Color? outgoingColor;
  final double bottomGap;

  static const double _lineStart = (_indicatorSize - _lineWidth) / 2;

  @override
  Widget build(BuildContext context) {
    final Color? incoming = incomingColor;
    final Color? outgoing = outgoingColor;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (incoming != null)
          PositionedDirectional(
            start: _lineStart,
            top: 0,
            width: _lineWidth,
            height: _indicatorTop - _lineGap,
            child: ColoredBox(color: incoming),
          ),
        if (outgoing != null)
          PositionedDirectional(
            start: _lineStart,
            top: _indicatorTop + _indicatorSize + _lineGap,
            bottom: 0,
            width: _lineWidth,
            child: ColoredBox(color: outgoing),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: bottomGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: _indicatorTop),
                child: SizedBox.square(
                  dimension: _indicatorSize,
                  child: ExcludeSemantics(child: indicator),
                ),
              ),
              const SizedBox(width: _contentGap),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({required this.number, required this.status});

  final int number;
  final StageStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return switch (status) {
      StageStatus.completed => DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary),
        ),
      ),
      StageStatus.active => DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            textScaler: TextScaler.noScaling,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      StageStatus.locked => DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.outlineVariant,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.lock_rounded,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    };
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.status,
    required this.previousStageNumber,
    required this.pendingNote,
  });

  final MissionStage stage;
  final StageStatus status;
  final int? previousStageNumber;
  final String? pendingNote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool locked = status == StageStatus.locked;
    final bool active = status == StageStatus.active;
    final Color textColor = locked ? scheme.onSurfaceVariant : scheme.onSurface;
    final int? previous = previousStageNumber;
    final String? note = pendingNote;
    final String requirementAmount = rupiah(stage.minOrderSubtotal);
    final String voucherAmount = rupiah(stage.voucherAmount);
    final String minSpend = rupiah(stage.voucherMinSpend);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: locked
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'Tahap ${stage.number}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _StagePill(status: status),
              ],
            ),
            const SizedBox(height: 10),
            _DetailLine(
              icon: Icons.shopping_bag_outlined,
              color: textColor,
              semanticsLabel:
                  'Syarat: selesaikan 1 pesanan minimal $requirementAmount',
              spans: <InlineSpan>[
                const TextSpan(text: 'Selesaikan 1 pesanan min. '),
                TextSpan(
                  text: requirementAmount,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _DetailLine(
              icon: Icons.confirmation_number_outlined,
              color: textColor,
              semanticsLabel:
                  'Hadiah: voucher $voucherAmount, minimal belanja $minSpend, '
                  'berlaku ${stage.voucherValidDays} hari',
              spans: <InlineSpan>[
                const TextSpan(text: 'Voucher '),
                TextSpan(
                  text: voucherAmount,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' · min. belanja $minSpend · berlaku '
                      '${stage.voucherValidDays} hari',
                ),
              ],
            ),
            if (locked && previous != null) ...<Widget>[
              const SizedBox(height: 6),
              _DetailLine(
                icon: Icons.lock_outline_rounded,
                color: scheme.onSurfaceVariant,
                spans: <InlineSpan>[
                  TextSpan(
                    text: 'Terbuka setelah voucher Tahap $previous terbit',
                  ),
                ],
              ),
            ],
            if (active && note != null) ...<Widget>[
              const SizedBox(height: 12),
              _PendingNote(text: note),
            ],
          ],
        ),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  const _StagePill({required this.status});

  final StageStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (status) {
      StageStatus.completed => StatusPill(
        label: 'Selesai',
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
      StageStatus.active => StatusPill(
        label: 'Aktif',
        background: scheme.primary,
        foreground: scheme.onPrimary,
      ),
      StageStatus.locked => StatusPill(
        label: 'Terkunci',
        background: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.color,
    required this.spans,
    this.semanticsLabel,
  });

  final IconData icon;
  final Color color;
  final List<InlineSpan> spans;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            top: _firstLineIconTop(context, style, _detailIconSize),
          ),
          child: Icon(icon, size: _detailIconSize, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(children: spans),
            style: style,
            semanticsLabel: semanticsLabel,
          ),
        ),
      ],
    );
  }
}

class _PendingNote extends StatelessWidget {
  const _PendingNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onTertiaryContainer,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(
                top: _firstLineIconTop(context, style, _detailIconSize),
              ),
              child: Icon(
                Icons.local_shipping,
                size: _detailIconSize,
                color: scheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      ),
    );
  }
}

class _CampaignIndicator extends StatelessWidget {
  const _CampaignIndicator({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      child: Center(
        child: Icon(
          finished ? Icons.emoji_events_outlined : Icons.more_horiz_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CampaignNote extends StatelessWidget {
  const _CampaignNote({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Text(
        finished
            ? 'Semua tahap selesai. Tahap berikutnya menunggu kampanye.'
            : 'Tahap berikutnya menunggu kampanye',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
