import 'kit/game_cue.dart';
import 'mission_order.dart';
import 'mission_products.dart';
import 'mission_stage.dart';
import 'mission_view.dart';
import 'mission_voucher.dart';

/// Status pesanan simulasi di [LocalMissionController].
enum LocalOrderStatus {
  /// Pesanan dibuat dan sedang dikemas.
  packing,

  /// Pesanan dikirim.
  shipped,
}

/// Pengendali dalam memori untuk `example/` dan tes.
///
/// Menyimpan keranjang, satu pesanan berjalan, dan voucher di memori, lalu
/// memakai aturan murni modul ([evaluateOrderLines], [MissionVoucher.issue])
/// persis seperti mesin host. Aksi navigasi dicatat di [log].
class LocalMissionController extends MissionController {
  /// Membuat pengendali dengan tahap dan produk tertentu.
  LocalMissionController({
    required List<MissionStage> stages,
    required int today,
    List<MissionProduct> products = const <MissionProduct>[],
    Map<int, List<MissionProduct>> stageProducts =
        const <int, List<MissionProduct>>{},
    bool signedIn = true,
    int issuedCount = 0,
    Map<String, int> cart = const <String, int>{},
    List<MissionVoucher> vouchers = const <MissionVoucher>[],
    bool? soundOn,
    this.latency = Duration.zero,
  }) : _stages = List<MissionStage>.unmodifiable(stages),
       _fallbackProducts = List<MissionProduct>.unmodifiable(products),
       _stageProducts = Map<int, List<MissionProduct>>.of(stageProducts),
       _signedIn = signedIn,
       _issuedCount = issuedCount,
       _today = today,
       _soundOn = soundOn,
       _vouchers = List<MissionVoucher>.of(vouchers) {
    for (final MapEntry<String, int> entry in cart.entries) {
      if (entry.value > 0) _cart[entry.key] = entry.value;
    }
  }

  /// Jeda buatan tiap aksi (meniru jaringan).
  final Duration latency;

  /// Catatan aksi yang tidak bisa dijalankan di memori (navigasi, suara).
  final List<String> log = <String>[];

  final List<MissionStage> _stages;
  final List<MissionProduct> _fallbackProducts;
  final Map<int, List<MissionProduct>> _stageProducts;
  final Map<String, int> _cart = <String, int>{};
  final List<MissionVoucher> _vouchers;
  final Set<String> _countedOrderIds = <String>{};
  bool _signedIn;
  int _issuedCount;
  int _today;
  bool? _soundOn;
  bool _busy = false;
  int _orderSequence = 0;
  _LocalOrder? _order;
  MissionCelebration? _celebration;

  /// Daftar semua produk yang dikenal pengendali.
  Iterable<MissionProduct> get _allProducts sync* {
    yield* _fallbackProducts;
    for (final List<MissionProduct> list in _stageProducts.values) {
      yield* list;
    }
  }

  MissionProduct? _productOf(String code) {
    for (final MissionProduct product in _allProducts) {
      if (product.code == code) return product;
    }
    return null;
  }

  List<MissionProduct> get _activeProducts =>
      _stageProducts[_issuedCount] ?? _fallbackProducts;

  List<MissionOrderLine> get _cartLines => <MissionOrderLine>[
    for (final MapEntry<String, int> entry in _cart.entries)
      MissionOrderLine(
        productCode: entry.key,
        unitPrice: _productOf(entry.key)?.price ?? 0,
        quantity: entry.value,
      ),
  ];

  @override
  MissionViewState get state {
    if (!_signedIn) {
      return MissionViewState.guest(
        stages: _stages,
        today: _today,
        products: _activeProducts,
        cartLines: _cartLines,
        soundOn: _soundOn,
      );
    }
    final _LocalOrder? order = _order;
    return MissionViewState(
      signedIn: true,
      stages: _stages,
      issuedCount: _issuedCount,
      today: _today,
      products: _activeProducts,
      cartLines: _cartLines,
      vouchers: List<MissionVoucher>.unmodifiable(_vouchers.reversed),
      pendingOrder: order == null || !order.reachesTarget
          ? null
          : MissionPendingOrder(
              orderId: order.id,
              missionSubtotal: order.missionSubtotal,
              statusLabel: switch (order.status) {
                LocalOrderStatus.packing => 'Dikemas',
                LocalOrderStatus.shipped => 'Dikirim',
              },
            ),
      celebration: _celebration,
      soundOn: _soundOn,
      busy: _busy,
    );
  }

  /// Pesanan simulasi yang sedang berjalan, bila ada.
  String? get openOrderId => _order?.id;

  /// Status pesanan simulasi yang sedang berjalan, bila ada.
  LocalOrderStatus? get openOrderStatus => _order?.status;

  Future<void> _wait() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  @override
  Future<void> refresh() async {
    await _wait();
    notifyListeners();
  }

  @override
  Future<bool> addToCart(String code) async {
    final MissionProduct? product = _productOf(code);
    if (product == null) return false;
    final int current = _cart[code] ?? 0;
    final int? max = product.maxQuantity;
    if (max != null && current >= max) return false;
    _busy = true;
    notifyListeners();
    await _wait();
    _cart[code] = current + 1;
    _busy = false;
    notifyListeners();
    return true;
  }

  @override
  Future<void> setQuantity(String code, int quantity) async {
    final int? max = _productOf(code)?.maxQuantity;
    final int clamped = max == null || quantity <= max ? quantity : max;
    await _wait();
    if (clamped <= 0) {
      _cart.remove(code);
    } else {
      _cart[code] = clamped;
    }
    notifyListeners();
  }

  @override
  void acknowledgeCelebration() {
    if (_celebration == null) return;
    _celebration = null;
    notifyListeners();
  }

  /// Masuk sebagai pengguna demo.
  void signIn() {
    _signedIn = true;
    notifyListeners();
  }

  /// Keluar; keranjang tamu tetap ada.
  void signOut() {
    _signedIn = false;
    notifyListeners();
  }

  /// Mengganti hari WIB (panel uji: melihat voucher kedaluwarsa).
  void setToday(int day) {
    _today = day;
    notifyListeners();
  }

  /// Checkout simulasi: semua isi keranjang menjadi satu pesanan Dikemas.
  /// Mengembalikan nomor pesanan, atau `null` bila keranjang kosong, tamu,
  /// atau masih ada pesanan berjalan.
  String? placeOrder() {
    if (!_signedIn || _cart.isEmpty || _order != null) return null;
    _orderSequence += 1;
    final String id = 'BP-261126-${_orderSequence.toString().padLeft(4, '0')}';
    final List<MissionOrderLine> lines = _cartLines;
    final MissionStage? stage = _issuedCount < _stages.length
        ? _stages[_issuedCount]
        : null;
    final int subtotal = stage == null ? 0 : missionSubtotal(stage, lines);
    _order = _LocalOrder(
      id: id,
      lines: lines,
      missionSubtotal: subtotal,
      reachesTarget: stage != null && subtotal >= stage.minOrderSubtotal,
    );
    _cart.clear();
    notifyListeners();
    return id;
  }

  /// Pesanan berjalan berubah menjadi Dikirim.
  void shipOrder() {
    final _LocalOrder? order = _order;
    if (order == null) return;
    _order = order.copyWith(status: LocalOrderStatus.shipped);
    notifyListeners();
  }

  /// Pesanan berjalan Selesai: dievaluasi dengan aturan murni. Mengembalikan
  /// keputusan misi, atau `null` bila tidak ada pesanan.
  MissionDecision? completeOrder() {
    final _LocalOrder? order = _order;
    if (order == null) return null;
    final MissionDecision decision = evaluateOrderLines(
      stages: _stages,
      issuedCount: _issuedCount,
      countedOrderIds: _countedOrderIds,
      orderId: order.id,
      lines: order.lines,
      completed: true,
    );
    _order = null;
    final MissionStage? stage = decision.issuedStage;
    if (stage != null) {
      _countedOrderIds.add(order.id);
      final MissionVoucher voucher = MissionVoucher.issue(
        id: 'vch-${stage.number}-${order.id}',
        stage: stage,
        sourceOrderId: order.id,
        issuedDay: _today,
      );
      _vouchers.add(voucher);
      _issuedCount += 1;
      _celebration = MissionCelebration(
        stage: stage,
        voucher: voucher,
        nextStage: _issuedCount < _stages.length ? _stages[_issuedCount] : null,
      );
    }
    notifyListeners();
    return decision;
  }

  /// Pesanan berjalan dibatalkan; isinya kembali ke keranjang.
  void cancelOrder() {
    final _LocalOrder? order = _order;
    if (order == null) return;
    for (final MissionOrderLine line in order.lines) {
      _cart[line.productCode] = (_cart[line.productCode] ?? 0) + line.quantity;
    }
    _order = null;
    notifyListeners();
  }

  /// Mengosongkan keranjang.
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Kembali ke awal kampanye (panel uji).
  void reset() {
    _cart.clear();
    _vouchers.clear();
    _countedOrderIds.clear();
    _issuedCount = 0;
    _order = null;
    _celebration = null;
    notifyListeners();
  }

  @override
  void openLogin() => log.add('openLogin');

  @override
  void openShop() => log.add('openShop');

  @override
  void openCart() => log.add('openCart');

  @override
  void openCheckout() => log.add('openCheckout');

  @override
  void openProduct(String code) => log.add('openProduct:$code');

  @override
  void openOrder(String orderId) => log.add('openOrder:$orderId');

  @override
  void openVouchers() => log.add('openVouchers');

  @override
  void useVoucher(String voucherId) => log.add('useVoucher:$voucherId');

  @override
  void setSoundOn(bool on) {
    _soundOn = on;
    notifyListeners();
  }

  @override
  void playCue(GameCue cue) => log.add('cue:${cue.name}');
}

final class _LocalOrder {
  const _LocalOrder({
    required this.id,
    required this.lines,
    required this.missionSubtotal,
    required this.reachesTarget,
    this.status = LocalOrderStatus.packing,
  });

  final String id;
  final List<MissionOrderLine> lines;
  final int missionSubtotal;
  final bool reachesTarget;
  final LocalOrderStatus status;

  _LocalOrder copyWith({LocalOrderStatus? status}) => _LocalOrder(
    id: id,
    lines: lines,
    missionSubtotal: missionSubtotal,
    reachesTarget: reachesTarget,
    status: status ?? this.status,
  );
}
