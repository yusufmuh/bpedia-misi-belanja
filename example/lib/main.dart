import 'package:flutter/material.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'demo_data.dart';
import 'host_theme.dart';

void main() => runApp(MissionDemoApp(controller: demoController()));

/// App contoh: [MissionsPage] di atas [LocalMissionController] dengan panel
/// uji (masuk/keluar, simulasi pesanan, ganti hari, tema, kurangi gerak).
/// Tombol kembali halaman membuka panel uji.
class MissionDemoApp extends StatefulWidget {
  /// Membuat app contoh di atas [controller].
  const MissionDemoApp({super.key, required this.controller});

  /// Pengendali dalam memori.
  final LocalMissionController controller;

  @override
  State<MissionDemoApp> createState() => _MissionDemoAppState();
}

class _MissionDemoAppState extends State<MissionDemoApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _reduceMotion = false;
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  void _openPanel() {
    final BuildContext? context = _navigator.currentContext;
    if (context == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) => DemoPanel(
        controller: widget.controller,
        dark: _themeMode == ThemeMode.dark,
        reduceMotion: _reduceMotion,
        onDarkChanged: (bool dark) => setState(
          () => _themeMode = dark ? ThemeMode.dark : ThemeMode.light,
        ),
        onReduceMotionChanged: (bool value) =>
            setState(() => _reduceMotion = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misi Belanja',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      theme: hostTheme(Brightness.light),
      darkTheme: hostTheme(Brightness.dark),
      themeMode: _themeMode,
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              _reduceMotion || MediaQuery.of(context).disableAnimations,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: MissionsPage(controller: widget.controller, onBack: _openPanel),
    );
  }
}

/// Panel uji untuk mencoba semua keadaan halaman tanpa server.
class DemoPanel extends StatelessWidget {
  /// Membuat panel untuk [controller].
  const DemoPanel({
    super.key,
    required this.controller,
    required this.dark,
    required this.reduceMotion,
    required this.onDarkChanged,
    required this.onReduceMotionChanged,
  });

  /// Pengendali yang diuji.
  final LocalMissionController controller;

  /// Tema gelap aktif.
  final bool dark;

  /// Kurangi gerak aktif.
  final bool reduceMotion;

  /// Mengganti tema.
  final ValueChanged<bool> onDarkChanged;

  /// Mengganti kurangi gerak.
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final MissionViewState state = controller.state;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final String? orderId = controller.openOrderId;
        final LocalOrderStatus? status = controller.openOrderStatus;
        void notify(String message) {
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }

        Widget action(String label, VoidCallback? onPressed) => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(label),
        );

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              Text(
                'Panel uji (demo)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hari WIB: ${formatWibDateLong(state.today)} · '
                'voucher terbit: ${state.issuedCount} · '
                'pesanan: ${orderId == null ? 'tidak ada' : '$orderId (${status?.name})'}',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sudah masuk'),
                value: state.signedIn,
                onChanged: (bool value) =>
                    value ? controller.signIn() : controller.signOut(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tema gelap'),
                value: dark,
                onChanged: onDarkChanged,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kurangi gerak'),
                value: reduceMotion,
                onChanged: onReduceMotionChanged,
              ),
              const SizedBox(height: 8),
              const Text(
                'Status pesanan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  action(
                    'Checkout keranjang',
                    orderId == null && state.signedIn
                        ? () {
                            final String? id = controller.placeOrder();
                            notify(
                              id == null
                                  ? 'Keranjang masih kosong.'
                                  : 'Pesanan $id dibuat (Dikemas).',
                            );
                          }
                        : null,
                  ),
                  action(
                    'Kirim',
                    status == LocalOrderStatus.packing
                        ? controller.shipOrder
                        : null,
                  ),
                  action(
                    'Selesai',
                    orderId == null
                        ? null
                        : () {
                            final MissionDecision? decision = controller
                                .completeOrder();
                            if (decision != null && !decision.issued) {
                              notify(
                                'Pesanan selesai, tetapi belum memenuhi target '
                                'tahap.',
                              );
                            }
                            Navigator.of(context).pop();
                          },
                  ),
                  action(
                    'Batalkan',
                    orderId == null ? null : controller.cancelOrder,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Hari dan data',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  action('Besok', () => controller.setToday(state.today + 1)),
                  action(
                    '+31 hari',
                    () => controller.setToday(state.today + 31),
                  ),
                  action('Hari ini', () => controller.setToday(wibToday())),
                  action('Kosongkan keranjang', controller.clearCart),
                  action('Atur ulang misi', controller.reset),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Navigasi host tercatat: '
                '${controller.log.isEmpty ? '-' : controller.log.reversed.take(4).join(', ')}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
