import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misi_belanja/src/widgets/ticket_shape.dart';

void main() {
  const Size size = Size(300, 120);

  test('pembatas tegak: takik di tepi atas dan bawah', () {
    final Path outline = TicketGeometry.resolve(
      size,
      axis: Axis.vertical,
      divider: 114,
    ).outline();

    expect(outline.contains(const Offset(114, 4)), isFalse);
    expect(outline.contains(const Offset(114, 116)), isFalse);
    expect(outline.contains(const Offset(114, 60)), isTrue);
    expect(outline.contains(const Offset(130, 4)), isTrue);
    expect(outline.contains(const Offset(4, 60)), isTrue);
    expect(outline.contains(const Offset(2, 2)), isFalse);
    expect(outline.contains(const Offset(298, 118)), isFalse);
  });

  test('pembatas mendatar: takik di tepi kiri dan kanan', () {
    final Path outline = TicketGeometry.resolve(
      size,
      axis: Axis.horizontal,
      divider: 50,
    ).outline();

    expect(outline.contains(const Offset(4, 50)), isFalse);
    expect(outline.contains(const Offset(296, 50)), isFalse);
    expect(outline.contains(const Offset(150, 50)), isTrue);
    expect(outline.contains(const Offset(150, 4)), isTrue);
    expect(outline.contains(const Offset(4, 70)), isTrue);
  });

  test('garis putus-putus berada di antara kedua takik', () {
    final (Offset top, Offset bottom) = TicketGeometry.resolve(
      size,
      axis: Axis.vertical,
      divider: 114,
    ).dividerSegment(6);
    expect(top, const Offset(114, 16));
    expect(bottom, const Offset(114, 104));

    final (Offset left, Offset right) = TicketGeometry.resolve(
      size,
      axis: Axis.horizontal,
      divider: 50,
    ).dividerSegment(6);
    expect(left, const Offset(16, 50));
    expect(right, const Offset(284, 50));
  });

  test('posisi takik dijaga di luar sudut membulat', () {
    expect(
      TicketGeometry.resolve(size, axis: Axis.vertical, divider: 0).divider,
      26,
    );
    expect(
      TicketGeometry.resolve(size, axis: Axis.vertical, divider: 400).divider,
      274,
    );
    expect(
      TicketGeometry.resolve(size, axis: Axis.horizontal, divider: 400).divider,
      94,
    );
  });

  test('ukuran sangat kecil tidak melempar error', () {
    final TicketGeometry geometry = TicketGeometry.resolve(
      const Size(20, 8),
      axis: Axis.vertical,
      divider: 10,
    );
    expect(geometry.outline().getBounds().width, lessThanOrEqualTo(20));
    expect(
      TicketGeometry.resolve(
        Size.zero,
        axis: Axis.horizontal,
        divider: 0,
      ).outline(),
      isA<Path>(),
    );
  });
}
