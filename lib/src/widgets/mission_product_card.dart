import 'package:flutter/material.dart';

import '../kit/kit.dart';
import '../mission_view.dart';
import '../rupiah.dart';
import 'mission_tones.dart';

/// Kartu produk misi bergaya marketplace: foto 1:1 berpita "Misi", nama dua
/// baris, harga, harga coret dan diskon bila ada, lalu tombol "+ Keranjang"
/// yang berubah menjadi stepper jumlah setelah produk masuk keranjang.
class MissionProductCard extends StatelessWidget {
  /// Membuat kartu untuk [product] dengan [quantity] di keranjang.
  const MissionProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onQuantityChanged,
    this.onOpen,
    this.addButtonKey,
  });

  /// Data tampilan produk.
  final MissionProduct product;

  /// Jumlah di keranjang (0 = tombol tambah).
  final int quantity;

  /// Menambah satu ke keranjang. `null` = nonaktif.
  final VoidCallback? onAdd;

  /// Mengubah jumlah. `null` = stepper nonaktif.
  final ValueChanged<int>? onQuantityChanged;

  /// Membuka detail produk.
  final VoidCallback? onOpen;

  /// Kunci tombol tambah (titik awal animasi tas terbang).
  final Key? addButtonKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    final int? discount = product.discountPercent;
    final int? strike = product.strikePrice;
    final bool dark = scheme.brightness == Brightness.dark;
    final Widget info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(
                color: Colors.white,
                child: Image(
                  image: product.image,
                  fit: BoxFit.cover,
                  semanticLabel: product.name,
                  errorBuilder:
                      (BuildContext context, Object error, StackTrace? _) =>
                          ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                ),
              ),
              const Positioned(
                left: 6,
                top: 6,
                child: ExcludeSemantics(child: FestiveRibbon(label: 'Misi')),
              ),
              if (discount != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tones.sale,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Text(
                        '-$discount%',
                        style: TextStyle(
                          fontSize: 11,
                          height: 14 / 11,
                          fontWeight: FontWeight.w700,
                          color: tones.onSale,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  rupiah(product.price),
                  style: TextStyle(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.secondary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              if (strike != null && discount != null)
                Text(
                  rupiah(strike),
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: scheme.outline,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: scheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final VoidCallback? open = onOpen;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: dark
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (open == null)
                info
              else
                Semantics(
                  button: true,
                  label: 'Lihat ${product.name}, ${rupiah(product.price)}',
                  excludeSemantics: true,
                  child: InkWell(onTap: open, child: info),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: quantity <= 0
                    ? _AddButton(
                        key: addButtonKey,
                        productName: product.name,
                        onPressed: onAdd,
                      )
                    : QtyStepper(
                        quantity: quantity,
                        max: product.maxQuantity,
                        productName: product.name,
                        onChanged: onQuantityChanged,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    super.key,
    required this.productName,
    required this.onPressed,
  });

  final String productName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: 'Tambah $productName ke keranjang',
      excludeSemantics: true,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Keranjang', maxLines: 1),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.2),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Stepper jumlah berbentuk pil: kurang, angka, tambah. Tiap tombol punya
/// target sentuh 48 dp. Kurang dari 1 menghapus produk dari keranjang.
class QtyStepper extends StatelessWidget {
  /// Membuat stepper untuk [quantity].
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.max,
    this.productName,
  });

  /// Jumlah sekarang.
  final int quantity;

  /// Batas atas. `null` = bebas.
  final int? max;

  /// Nama produk untuk label pembaca layar.
  final String? productName;

  /// Dipanggil dengan jumlah baru. `null` = nonaktif.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ValueChanged<int>? change = onChanged;
    final int? limit = max;
    final bool canAdd = change != null && (limit == null || quantity < limit);
    final String name = productName ?? 'produk';
    Widget button(IconData icon, String label, VoidCallback? onTap) {
      final Color color = onTap == null
          ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
          : scheme.primary;
      return Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
          color: scheme.primaryContainer.withValues(alpha: 0.5),
        ),
        child: Row(
          children: <Widget>[
            button(
              quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove,
              quantity <= 1
                  ? 'Hapus $name dari keranjang'
                  : 'Kurangi jumlah $name',
              change == null ? null : () => change(quantity - 1),
            ),
            Expanded(
              child: Semantics(
                label: 'Jumlah $name di keranjang',
                value: '$quantity',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: reduceMotionOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$quantity',
                      key: ValueKey<int>(quantity),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            button(
              Icons.add,
              'Tambah jumlah $name',
              canAdd ? () => change(quantity + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
