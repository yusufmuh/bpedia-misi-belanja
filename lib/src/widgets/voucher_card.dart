import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mission_voucher.dart';
import '../rupiah.dart';
import '../wib_date.dart';
import 'status_pill.dart';
import 'ticket_shape.dart';

enum _VoucherState { active, used, expired }

_VoucherState _stateOf(MissionVoucher voucher, int today) {
  if (voucher.isUsed) {
    return _VoucherState.used;
  }
  if (voucher.isExpiredOn(today)) {
    return _VoucherState.expired;
  }
  return _VoucherState.active;
}

/// Ticket-shaped card for a mission voucher.
///
/// Shows the amount, minimum spend, last valid day and a status label
/// ("Aktif", "Terpakai", "Kedaluwarsa"). A "Pakai" button appears only when
/// the voucher is active on [today] and [onUse] is set. When the amount does
/// not fit beside the details at full size (large text, narrow screens) the
/// stub moves above the details and the divider turns horizontal.
class VoucherCard extends StatelessWidget {
  /// Creates the card for [voucher] as seen on WIB day [today].
  const VoucherCard({
    super.key,
    required this.voucher,
    required this.today,
    this.onUse,
  });

  /// Voucher to show.
  final MissionVoucher voucher;

  /// Current WIB day number.
  final int today;

  /// Called when the user taps "Pakai" on an active voucher.
  final VoidCallback? onUse;

  static const double _fallbackWidth = 340;
  static const double _minStubShare = 0.36;
  static const double _maxStubShare = 0.5;
  static const double _minStubWidth = 104;
  static const EdgeInsetsDirectional _sideStubPadding =
      EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16);
  static const EdgeInsetsDirectional _topStubPadding =
      EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final _VoucherState state = _stateOf(voucher, today);
    final bool active = state == _VoucherState.active;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final String amount = rupiah(voucher.amount);
    final TextStyle labelStyle =
        (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
          color: scheme.onSurfaceVariant,
        );
    final TextStyle amountStyle =
        (theme.textTheme.headlineSmall ?? const TextStyle()).copyWith(
          color: active ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        );
    final Size stubContent = _measureStub(
      context,
      amount: amount,
      labelStyle: labelStyle,
      amountStyle: amountStyle,
    );
    final Widget details = _VoucherDetails(
      voucher: voucher,
      state: state,
      onUse: active ? onUse : null,
    );
    return Semantics(
      container: true,
      label: _summary(voucher, state),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool bounded = constraints.hasBoundedWidth;
          final double width = bounded ? constraints.maxWidth : _fallbackWidth;
          final double sideStubWidth =
              stubContent.width + _sideStubPadding.horizontal;
          final Axis axis;
          final double divider;
          final Widget body;
          if (sideStubWidth > width * _maxStubShare) {
            final double stubHeight =
                stubContent.height + _topStubPadding.vertical;
            axis = Axis.horizontal;
            divider = stubHeight;
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: stubHeight,
                  child: _VoucherStub(
                    amount: amount,
                    labelStyle: labelStyle,
                    amountStyle: amountStyle,
                    padding: _topStubPadding,
                  ),
                ),
                details,
              ],
            );
          } else {
            final double stubWidth = math.min(
              math.max(
                sideStubWidth,
                math.max(width * _minStubShare, _minStubWidth),
              ),
              width * _maxStubShare,
            );
            axis = Axis.vertical;
            divider = rtl ? width - stubWidth : stubWidth;
            body = Row(
              children: <Widget>[
                SizedBox(
                  width: stubWidth,
                  child: _VoucherStub(
                    amount: amount,
                    labelStyle: labelStyle,
                    amountStyle: amountStyle,
                    padding: _sideStubPadding,
                  ),
                ),
                Expanded(child: details),
              ],
            );
          }
          final Widget ticket = CustomPaint(
            foregroundPainter: TicketOutlinePainter(
              axis: axis,
              divider: divider,
              borderColor: scheme.outlineVariant,
              dashColor: scheme.outline.withValues(alpha: 0.6),
            ),
            child: ClipPath(
              clipper: TicketClipper(axis: axis, divider: divider),
              child: ColoredBox(
                color: active
                    ? scheme.surfaceContainerLowest
                    : scheme.surfaceContainerLow,
                child: Material(type: MaterialType.transparency, child: body),
              ),
            ),
          );
          return bounded ? ticket : SizedBox(width: width, child: ticket);
        },
      ),
    );
  }
}

Size _measureStub(
  BuildContext context, {
  required String amount,
  required TextStyle labelStyle,
  required TextStyle amountStyle,
}) {
  final DefaultTextStyle defaults = DefaultTextStyle.of(context);
  final bool boldText = MediaQuery.boldTextOf(context);
  double width = 0;
  double height = 0;
  for (final (String text, TextStyle style) in <(String, TextStyle)>[
    ('Voucher', labelStyle),
    (amount, amountStyle),
  ]) {
    TextStyle effective = defaults.style.merge(style);
    if (boldText) {
      effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: effective),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior:
          defaults.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    width = math.max(width, painter.width);
    height += painter.height;
    painter.dispose();
  }
  return Size(width, height);
}

String _summary(MissionVoucher voucher, _VoucherState state) {
  final String status = switch (state) {
    _VoucherState.active => 'aktif',
    _VoucherState.used => 'terpakai',
    _VoucherState.expired => 'kedaluwarsa',
  };
  return 'Voucher ${rupiah(voucher.amount)} dari Misi Belanja '
      'Tahap ${voucher.stageNumber}. '
      'Minimal belanja ${rupiah(voucher.minSpend)}. '
      'Berlaku sampai ${formatWibDateLong(voucher.expiresDay)}. '
      'Status: $status.';
}

class _VoucherStub extends StatelessWidget {
  const _VoucherStub({
    required this.amount,
    required this.labelStyle,
    required this.amountStyle,
    required this.padding,
  });

  final String amount;
  final TextStyle labelStyle;
  final TextStyle amountStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: padding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Voucher', style: labelStyle),
              Text(amount, style: amountStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherDetails extends StatelessWidget {
  const _VoucherDetails({
    required this.voucher,
    required this.state,
    required this.onUse,
  });

  final MissionVoucher voucher;
  final _VoucherState state;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final VoidCallback? use = onUse;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: Text(
              'Min. belanja ${rupiah(voucher.minSpend)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: state == _VoucherState.active
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 2),
          ExcludeSemantics(
            child: Text(
              'Berlaku s.d. ${formatWibDateShort(voucher.expiresDay)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              ExcludeSemantics(child: _VoucherPill(state: state)),
              if (use != null)
                TextButton(
                  onPressed: use,
                  style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                  child: Text(
                    'Pakai',
                    semanticsLabel: 'Pakai voucher ${rupiah(voucher.amount)}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherPill extends StatelessWidget {
  const _VoucherPill({required this.state});

  final _VoucherState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (state) {
      _VoucherState.active => StatusPill(
        label: 'Aktif',
        icon: Icons.event_available_outlined,
        background: scheme.primary,
        foreground: scheme.onPrimary,
      ),
      _VoucherState.used => StatusPill(
        label: 'Terpakai',
        icon: Icons.check_circle_outline_rounded,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      _VoucherState.expired => StatusPill(
        label: 'Kedaluwarsa',
        icon: Icons.event_busy_outlined,
        background: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }
}
