import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Geometry of a voucher ticket: a rounded rectangle with two semicircle
/// notches where the dashed divider meets the outline.
///
/// With [Axis.vertical] the divider runs top to bottom at `x = divider` and the
/// notches cut the top and bottom edges. With [Axis.horizontal] it runs side
/// to side at `y = divider` and the notches cut the left and right edges.
@immutable
final class TicketGeometry {
  /// Resolves the shape for [size], keeping the notches clear of the rounded
  /// corners.
  factory TicketGeometry.resolve(
    Size size, {
    required Axis axis,
    required double divider,
    double cornerRadius = 16,
    double notchRadius = 10,
  }) {
    final double shortest = math.min(size.width, size.height);
    final double corner = math.min(cornerRadius, shortest / 2);
    final double notch = math.min(notchRadius, shortest / 4);
    final double extent = axis == Axis.vertical ? size.width : size.height;
    final double lowest = corner + notch;
    final double highest = math.max(lowest, extent - corner - notch);
    return TicketGeometry._(
      size: size,
      axis: axis,
      cornerRadius: corner,
      notchRadius: notch,
      divider: divider.clamp(lowest, highest),
    );
  }

  const TicketGeometry._({
    required this.size,
    required this.axis,
    required this.cornerRadius,
    required this.notchRadius,
    required this.divider,
  });

  /// Size of the ticket.
  final Size size;

  /// Direction of the dashed divider line.
  final Axis axis;

  /// Radius of the four outer corners.
  final double cornerRadius;

  /// Radius of the two notches.
  final double notchRadius;

  /// Position of the divider: x for [Axis.vertical], y for [Axis.horizontal].
  final double divider;

  /// Outline of the ticket, clockwise from the top-left corner.
  Path outline() {
    final double w = size.width;
    final double h = size.height;
    final double r = cornerRadius;
    final double n = notchRadius;
    final double d = divider;
    final bool vertical = axis == Axis.vertical;
    final Radius corner = Radius.circular(r);
    final Radius notch = Radius.circular(n);
    final Path path = Path()..moveTo(r, 0);
    if (vertical) {
      path
        ..lineTo(d - n, 0)
        ..arcToPoint(Offset(d + n, 0), radius: notch, clockwise: false);
    }
    path
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: corner);
    if (!vertical) {
      path
        ..lineTo(w, d - n)
        ..arcToPoint(Offset(w, d + n), radius: notch, clockwise: false);
    }
    path
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: corner);
    if (vertical) {
      path
        ..lineTo(d + n, h)
        ..arcToPoint(Offset(d - n, h), radius: notch, clockwise: false);
    }
    path
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: corner);
    if (!vertical) {
      path
        ..lineTo(0, d + n)
        ..arcToPoint(Offset(0, d - n), radius: notch, clockwise: false);
    }
    return path
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: corner)
      ..close();
  }

  /// End points of the dashed divider, [inset] away from each notch.
  (Offset, Offset) dividerSegment(double inset) {
    final double gap = notchRadius + inset;
    return axis == Axis.vertical
        ? (Offset(divider, gap), Offset(divider, size.height - gap))
        : (Offset(gap, divider), Offset(size.width - gap, divider));
  }
}

/// Clips a child to the ticket outline.
class TicketClipper extends CustomClipper<Path> {
  /// Creates a clipper whose divider runs along [axis] at [divider].
  const TicketClipper({required this.axis, required this.divider});

  /// Direction of the divider line.
  final Axis axis;

  /// Position of the divider along the cross direction.
  final double divider;

  @override
  Path getClip(Size size) =>
      TicketGeometry.resolve(size, axis: axis, divider: divider).outline();

  @override
  bool shouldReclip(TicketClipper oldClipper) =>
      oldClipper.axis != axis || oldClipper.divider != divider;
}

/// Paints the ticket border and the dashed divider between the notches.
class TicketOutlinePainter extends CustomPainter {
  /// Creates the painter; colours come from the host theme.
  const TicketOutlinePainter({
    required this.axis,
    required this.divider,
    required this.borderColor,
    required this.dashColor,
  });

  /// Direction of the divider line.
  final Axis axis;

  /// Position of the divider along the cross direction.
  final double divider;

  /// Colour of the outline stroke.
  final Color borderColor;

  /// Colour of the dashed divider.
  final Color dashColor;

  static const double _dashLength = 5;
  static const double _dashGap = 4;
  static const double _dividerInset = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final TicketGeometry geometry = TicketGeometry.resolve(
      size,
      axis: axis,
      divider: divider,
    );
    canvas.drawPath(
      geometry.outline(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor,
    );
    final (Offset start, Offset end) = geometry.dividerSegment(_dividerInset);
    final Offset span = end - start;
    final double length = span.distance;
    if (length <= 0) {
      return;
    }
    final Offset unit = span / length;
    final Paint dash = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = dashColor;
    double travelled = 0;
    while (travelled < length) {
      final double dashEnd = math.min(travelled + _dashLength, length);
      canvas.drawLine(start + unit * travelled, start + unit * dashEnd, dash);
      travelled = dashEnd + _dashGap;
    }
  }

  @override
  bool shouldRepaint(TicketOutlinePainter oldDelegate) =>
      oldDelegate.axis != axis ||
      oldDelegate.divider != divider ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.dashColor != dashColor;
}
