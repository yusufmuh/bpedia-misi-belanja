import 'package:flutter/material.dart';

/// Compact status label used by the ladder and the voucher card.
class StatusPill extends StatelessWidget {
  /// Creates a pill with [label] in [foreground] on [background].
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  /// Status text, always visible.
  final String label;

  /// Fill colour taken from the host [ColorScheme].
  final Color background;

  /// Text and icon colour taken from the host [ColorScheme].
  final Color foreground;

  /// Optional leading icon reinforcing the status.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final IconData? glyph = icon;
    final TextStyle? style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (glyph != null) ...<Widget>[
              Icon(glyph, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}
