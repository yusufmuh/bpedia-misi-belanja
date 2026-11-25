import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kit/festive_palette.dart';
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
    final Color stubInk = active ? Colors.white : scheme.onSurfaceVariant;
    final TextStyle labelStyle = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: stubInk,
    );
    final TextStyle amountStyle = TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w800,
      color: stubInk,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
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
                    active: active,
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
                    active: active,
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
              borderColor: active ? scheme.primary : scheme.outlineVariant,
              dashColor: scheme.outline.withValues(alpha: 0.6),
            ),
            child: ClipPath(
              clipper: TicketClipper(axis: axis, divider: divider),
              child: ColoredBox(
                color: active ? scheme.surface : scheme.surfaceContainerHighest,
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
    required this.active,
    required this.labelStyle,
    required this.amountStyle,
    required this.padding,
  });

  final String amount;
  final bool active;
  final TextStyle labelStyle;
  final TextStyle amountStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    FestivePalette.candyBottom,
                    FestivePalette.candyLip,
                  ],
                )
              : null,
          color: active ? null : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        child: CustomPaint(
          painter: active ? const _DotsPainter() : null,
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
        ),
      ),
    );
  }
}

/// Bintik putih tipis di stub aktif, supaya kupon terasa seperti tiket pesta.
class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = const Color(0x1FFFFFFF);
    const double gap = 14;
    int row = 0;
    for (double y = 6; y < size.height; y += gap) {
      final double shift = row.isEven ? 0 : gap / 2;
      for (double x = 6 + shift; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 2, dot);
      }
      row += 1;
    }
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.05),
      size.shortestSide * 0.45,
      Paint()..color = const Color(0x14FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => false;
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
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
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
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
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
                  style: TextButton.styleFrom(
                    minimumSize: const Size(72, 48),
                    foregroundColor: scheme.onPrimary,
                    backgroundColor: scheme.primary,
                    shape: const StadiumBorder(),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
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
    return switch (state) {
      _VoucherState.active => const StatusPill(
        label: 'Aktif',
        tone: StatusTone.success,
        icon: Icons.event_available_outlined,
      ),
      _VoucherState.used => const StatusPill(
        label: 'Terpakai',
        tone: StatusTone.neutral,
        icon: Icons.check_circle_outline_rounded,
      ),
      _VoucherState.expired => const StatusPill(
        label: 'Kedaluwarsa',
        tone: StatusTone.neutral,
        icon: Icons.event_busy_outlined,
      ),
    };
  }
}
