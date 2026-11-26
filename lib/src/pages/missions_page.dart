import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../kit/kit.dart';
import '../mission_assets.dart';
import '../mission_products.dart';
import '../mission_stage.dart';
import '../mission_view.dart';
import '../mission_voucher.dart';
import '../rupiah.dart';
import '../widgets/lively_pose.dart';
import '../widgets/mission_celebration.dart';
import '../widgets/mission_how_to.dart';
import '../widgets/mission_ladder.dart';
import '../widgets/mission_product_card.dart';
import '../widgets/mission_progress_track.dart';
import '../widgets/mission_tones.dart';
import '../widgets/status_pill.dart';
import '../widgets/voucher_card.dart';

/// Halaman game Misi Belanja (SPEC-V3 §6.3).
///
/// Hero pesta dengan Bipy berjalan, kartu tahap aktif dengan bar progres
/// subtotal produk misi, grid produk misi dengan tambah cepat, tangga tahap
/// dan hadiah, voucher milik pengguna, cara main, dan bar bawah yang
/// menempel. Saat sebuah tahap tuntas ([MissionViewState.celebration]),
/// lembar perayaan tampil sekali.
///
/// Halaman tidak tahu sumber data: semua lewat [controller].
class MissionsPage extends StatefulWidget {
  /// Membuat halaman di atas [controller].
  const MissionsPage({
    super.key,
    required this.controller,
    this.title = 'Misi Belanja',
    this.onBack,
    this.showBack = true,
  });

  /// Sumber keadaan dan aksi.
  final MissionController controller;

  /// Judul bilah atas.
  final String title;

  /// Tombol kembali. Bawaan `Navigator.maybePop`.
  final VoidCallback? onBack;

  /// Menampilkan tombol kembali.
  final bool showBack;

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  final ScrollController _scroll = ScrollController();
  final ConfettiController _confetti = ConfettiController();
  final CoinFlightController _flight = CoinFlightController();
  final GlobalKey _cartTargetKey = GlobalKey(debugLabel: 'mission-cart');
  final GlobalKey _voucherPanelKey = GlobalKey(debugLabel: 'mission-vouchers');
  final Map<String, GlobalKey> _addKeys = <String, GlobalKey>{};
  String? _category;
  bool _celebrating = false;
  bool _wasReady = false;

  MissionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _wasReady = _controller.state.phase == MissionPhase.ready;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
  }

  @override
  void didUpdateWidget(MissionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _scroll.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final MissionViewState state = _controller.state;
    final bool ready = state.signedIn && state.phase == MissionPhase.ready;
    if (ready && !_wasReady) _onTargetReached();
    _wasReady = ready;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
  }

  void _onTargetReached() {
    emitCue(_controller.playCue, GameCue.bonus);
    _confetti.fire(origin: const Alignment(0, -0.3), count: 70, power: 0.8);
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Target misi tercapai. Siap checkout.',
        Directionality.of(context),
      ),
    );
  }

  Future<void> _maybeCelebrate() async {
    if (!mounted || _celebrating) return;
    final MissionCelebration? celebration = _controller.state.celebration;
    if (celebration == null) return;
    _celebrating = true;
    _controller.acknowledgeCelebration();
    emitCue(_controller.playCue, GameCue.missionDone);
    await showMissionCompleteSheet(
      context,
      celebration: celebration,
      onSeeVoucher: _scrollToVouchers,
      onNextStage: celebration.nextStage == null ? null : _scrollToTop,
    );
    _celebrating = false;
  }

  void _scrollToVouchers() {
    final BuildContext? target = _voucherPanelKey.currentContext;
    if (target == null) {
      _controller.openVouchers();
      return;
    }
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: reduceMotionOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    if (reduceMotionOf(context)) {
      _scroll.jumpTo(0);
    } else {
      unawaited(
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  GlobalKey _addKeyFor(String code) =>
      _addKeys.putIfAbsent(code, () => GlobalKey(debugLabel: 'add-$code'));

  Offset? _centerOf(GlobalKey key) {
    final RenderObject? box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Future<void> _add(MissionProduct product) async {
    final Offset? from = _centerOf(_addKeyFor(product.code));
    final bool added = await _controller.addToCart(product.code);
    if (!mounted) return;
    if (!added) {
      emitCue(_controller.playCue, GameCue.softError);
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Jumlah produk ini sudah maksimal di keranjang. '
              'Pilih produk misi lain ya, Babes.',
            ),
          ),
        );
      return;
    }
    emitCue(_controller.playCue, GameCue.tap);
    if (from != null && _cartTargetKey.currentContext != null) {
      unawaited(
        _flight.fly(
          fromGlobal: from,
          toKey: _cartTargetKey,
          count: 3,
          duration: const Duration(milliseconds: 620),
          stagger: const Duration(milliseconds: 70),
        ),
      );
    }
  }

  Future<void> _setQuantity(MissionProduct product, int quantity) async {
    emitCue(_controller.playCue, GameCue.tap);
    await _controller.setQuantity(product.code, quantity);
  }

  void _openRules() {
    final MissionViewState state = _controller.state;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext sheet) => _RulesSheet(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MissionViewState state = _controller.state;
    final bool? soundOn = state.soundOn;
    return CoinFlight(
      controller: _flight,
      image: MissionArt.bag,
      coinSize: 34,
      child: ConfettiBurst(
        controller: _confetti,
        child: GameScaffold(
          title: widget.title,
          onBack: widget.onBack,
          showBack: widget.showBack,
          scrollController: _scroll,
          actions: <Widget>[
            if (soundOn != null)
              GameBarAction(
                icon: soundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                tooltip: soundOn ? 'Matikan suara' : 'Nyalakan suara',
                onPressed: () => _controller.setSoundOn(!soundOn),
              ),
            GameBarAction.text(label: 'Aturan', onPressed: _openRules),
          ],
          hero: _MissionHero(state: state),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _ActiveStagePanel(
                  state: state,
                  onLogin: _controller.openLogin,
                ),
              ),
            ),
            if (!state.allDone)
              ..._productSlivers(state)
            else
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Tahapan dan hadiah',
                child: MissionLadder(
                  stages: state.stages,
                  issuedCount: state.issuedCount,
                  pendingNote: _pendingNote(state),
                  activeStatus: _phaseLabel(state),
                  activeTone: _phaseTone(state.phase),
                  showTrack: false,
                ),
              ),
            ),
            if (state.signedIn && state.vouchers.isNotEmpty)
              SliverToBoxAdapter(
                child: _Section(
                  key: _voucherPanelKey,
                  title: 'Voucher kamu',
                  trailing: TextButton(
                    onPressed: _controller.openVouchers,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Lihat semua'),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (final MissionVoucher voucher in state.vouchers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: VoucherCard(
                            voucher: voucher,
                            today: state.today,
                            onUse: () => _controller.useVoucher(voucher.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Cara main',
                trailing: TextButton(
                  onPressed: _openRules,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Syarat & ketentuan'),
                ),
                child: MissionHowTo(
                  targetLabel: rupiah(
                    (state.activeStage ?? _lastStage(state))
                            ?.minOrderSubtotal ??
                        0,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          bottomBar: _BottomBar(
            state: state,
            cartTargetKey: _cartTargetKey,
            onLogin: _controller.openLogin,
            onCart: _controller.openCart,
            onCheckout: _controller.openCheckout,
            onShop: _controller.openShop,
            onOrder: _controller.openOrder,
          ),
        ),
      ),
    );
  }

  List<Widget> _productSlivers(MissionViewState state) {
    final List<String> categories = state.categories;
    final String? category = categories.contains(_category) ? _category : null;
    final List<MissionProduct> visible = <MissionProduct>[
      for (final MissionProduct product in state.products)
        if (category == null || product.category == category) product,
    ];
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < visible.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: _card(state, visible[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < visible.length
                      ? _card(state, visible[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: _SectionHeader(
            title: 'Produk misi',
            trailing: state.products.isEmpty
                ? null
                : Text(
                    '${state.products.length} produk',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
      if (categories.length > 1)
        SliverToBoxAdapter(
          child: _CategoryChips(
            categories: categories,
            selected: category,
            onSelected: (String? value) => setState(() => _category = value),
          ),
        ),
      if (state.products.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyProducts(onShop: _controller.openShop),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(children: rows),
        ),
    ];
  }

  Widget _card(MissionViewState state, MissionProduct product) {
    return MissionProductCard(
      product: product,
      quantity: state.quantityOf(product.code),
      addButtonKey: _addKeyFor(product.code),
      onAdd: state.busy ? null : () => unawaited(_add(product)),
      onQuantityChanged: (int quantity) =>
          unawaited(_setQuantity(product, quantity)),
      onOpen: () => _controller.openProduct(product.code),
    );
  }
}

MissionStage? _lastStage(MissionViewState state) =>
    state.stages.isEmpty ? null : state.stages.last;

String? _pendingNote(MissionViewState state) {
  final MissionPendingOrder? order = state.pendingOrder;
  if (order == null) return null;
  final String? status = order.statusLabel;
  return 'Pesanan ${order.orderId} (produk misi '
      '${rupiah(order.missionSubtotal)})'
      '${status == null ? '' : ' sedang ${status.toLowerCase()}'}. '
      'Voucher terbit setelah pesanan Selesai.';
}

String _phaseLabel(MissionViewState state) {
  if (!state.signedIn) return 'Aktif';
  return switch (state.phase) {
    MissionPhase.notStarted => 'Belum mulai',
    MissionPhase.inCart => 'Di keranjang',
    MissionPhase.ready => 'Siap checkout',
    MissionPhase.awaitingCompletion => 'Menunggu pesanan selesai',
    MissionPhase.allDone => 'Selesai',
  };
}

StatusTone _phaseTone(MissionPhase phase) => switch (phase) {
  MissionPhase.notStarted => StatusTone.neutral,
  MissionPhase.inCart => StatusTone.brand,
  MissionPhase.ready => StatusTone.success,
  MissionPhase.awaitingCompletion => StatusTone.info,
  MissionPhase.allDone => StatusTone.success,
};

class _MissionHero extends StatelessWidget {
  const _MissionHero({required this.state});

  final MissionViewState state;

  @override
  Widget build(BuildContext context) {
    final MissionStage? stage = state.activeStage;
    final TextScaler scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.5);
    final double width = MediaQuery.sizeOf(context).width;
    final double spriteHeight = width < 380 ? 118 : 132;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: SizedBox(
        height: 176,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Positioned(
              right: 150,
              top: 0,
              child: _Sticker(image: MissionArt.stickerSparkle, size: 26),
            ),
            const Positioned(
              right: 4,
              top: 6,
              child: _Sticker(
                image: MissionArt.stickerHeart,
                size: 34,
                phase: 0.4,
              ),
            ),
            const Positioned(
              right: 118,
              bottom: 8,
              child: _Sticker(
                image: MissionArt.stickerFlower,
                size: 30,
                phase: 0.7,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: spriteHeight * 1.02,
              height: spriteHeight + 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Positioned(
                    left: -36,
                    bottom: 26,
                    child: Bobbing(
                      amplitude: 5,
                      tilt: 0.06,
                      child: Image(
                        image: MissionArt.bag,
                        width: spriteHeight * 0.42,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    top: 0,
                    child: Bobbing(
                      phase: 0.5,
                      tilt: 0.1,
                      child: Image(
                        image: MissionArt.ticket,
                        width: spriteHeight * 0.4,
                      ),
                    ),
                  ),
                  SpriteAnimation(
                    spec: MissionSprites.walk,
                    height: spriteHeight,
                    semanticLabel: 'Bipy berjalan membawa tas belanja',
                  ),
                ],
              ),
            ),
            Positioned.fill(
              right: spriteHeight * 1.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GlassChip(
                    leading: const Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: stage == null
                        ? 'Semua tahap selesai'
                        : 'Tahap ${stage.number} dari ${state.stages.length}',
                  ),
                  const SizedBox(height: 10),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'Misi Belanja',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 26,
                        height: 32 / 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: <Shadow>[
                          Shadow(
                            color: FestivePalette.festDeep,
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage == null
                        ? 'Semua voucher misi sudah kamu kumpulkan.'
                        : 'Belanja produk misi, dapat voucher '
                              '${rupiah(stage.voucherAmount)}.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.image, required this.size, this.phase = 0});

  final ImageProvider image;
  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Bobbing(
        amplitude: 4,
        phase: phase,
        tilt: 0.12,
        child: Image(image: image, width: size, height: size),
      ),
    );
  }
}

class _ActiveStagePanel extends StatelessWidget {
  const _ActiveStagePanel({required this.state, required this.onLogin});

  final MissionViewState state;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    final MissionStage? stage = state.activeStage;
    if (stage == null) {
      return _AllDoneCard(voucherCount: state.activeVoucherCount);
    }
    final MissionPhase phase = state.phase;
    final MissionPendingOrder? pending = state.pendingOrder;
    final Widget body;
    if (!state.signedIn) {
      body = _GuestProgress(onLogin: onLogin);
    } else if (pending != null) {
      body = MissionProgressTrack(
        progress: MissionProgress(
          current: pending.missionSubtotal,
          target: stage.minOrderSubtotal,
        ),
        label: 'Produk misi di pesanan ${pending.orderId}',
        message:
            'Target tercapai. Pesanan ${pending.statusLabel?.toLowerCase() ?? 'diproses'}, '
            'voucher terbit setelah pesanan Selesai.',
        messageIcon: Icons.local_shipping_rounded,
        success: true,
      );
    } else {
      final MissionProgress progress =
          state.progress ??
          MissionProgress(current: 0, target: stage.minOrderSubtotal);
      body = MissionProgressTrack(
        progress: progress,
        label: 'Produk misi di keranjang',
        message: switch (phase) {
          MissionPhase.ready => 'Target tercapai. Siap checkout, Babes!',
          MissionPhase.inCart =>
            'Tambah ${rupiah(progress.remaining)} lagi untuk voucher '
                '${rupiah(stage.voucherAmount)}',
          _ =>
            'Tambah produk misi senilai ${rupiah(progress.target)} '
                'dalam 1 pesanan',
        },
        messageIcon: phase == MissionPhase.ready
            ? Icons.check_circle_rounded
            : Icons.shopping_bag_outlined,
        success: phase == MissionPhase.ready,
      );
    }
    final bool stacked = MediaQuery.textScalerOf(context).scale(16) > 20;
    final Widget target = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              stage.title,
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (state.signedIn)
              StatusPill(label: _phaseLabel(state), tone: _phaseTone(phase)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Produk misi min. ${rupiah(stage.minOrderSubtotal)} '
          'dalam 1 pesanan',
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final Widget coupon = _RewardCoupon(stage: stage, tones: tones);
    return FestivePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MissionStageTrack(
            stages: state.stages,
            issuedCount: state.issuedCount,
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        target,
                        const SizedBox(height: 8),
                        coupon,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(child: target),
                        const SizedBox(width: 10),
                        coupon,
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}

class _RewardCoupon extends StatelessWidget {
  const _RewardCoupon({required this.stage, required this.tones});

  final MissionStage stage;
  final MissionTones tones;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Hadiah: voucher ${rupiah(stage.voucherAmount)}, minimal belanja '
          '${rupiah(stage.voucherMinSpend)}, berlaku '
          '${stage.voucherValidDays} hari',
      excludeSemantics: true,
      child: DecoratedBox(
        key: const ValueKey<String>('mission-reward'),
        decoration: BoxDecoration(
          color: tones.goldTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FestivePalette.gold.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Bobbing(
                amplitude: 2,
                tilt: 0.08,
                child: Image(image: MissionArt.ticket, width: 34, height: 34),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Voucher',
                      style: TextStyle(
                        fontSize: 11,
                        height: 14 / 11,
                        color: tones.onGoldTint,
                      ),
                    ),
                    Text(
                      rupiah(stage.voucherAmount),
                      style: TextStyle(
                        fontSize: 16,
                        height: 20 / 16,
                        fontWeight: FontWeight.w800,
                        color: tones.onGoldTint,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestProgress extends StatelessWidget {
  const _GuestProgress({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            const LivelyPose(image: MissionArt.poseShopping, height: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Masuk dulu, Babes',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    'Progres misi dan voucher tersimpan di akunmu.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: onLogin,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Masuk sekarang'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({required this.voucherCount});

  final int voucherCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return FestivePanel(
      tone: FestivePanelTone.cream,
      child: Row(
        children: <Widget>[
          const LivelyPose(image: MissionArt.poseCheer, height: 112),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Semua tahap selesai, Babes!',
                  style: TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voucherCount > 0
                      ? 'Kamu punya $voucherCount voucher aktif. Tahap '
                            'berikutnya menunggu kampanye.'
                      : 'Tahap berikutnya menunggu kampanye. Pantau terus ya.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return FestivePanel(
      child: Column(
        children: <Widget>[
          const LivelyPose(image: MissionArt.poseCheer, height: 110),
          const SizedBox(height: 8),
          Text(
            'Produk misi sedang disiapkan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sambil menunggu, lihat produk lain di katalog.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onShop,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: const StadiumBorder(),
            ),
            child: const Text('Lihat katalog'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget? end = trailing;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: FestivePalette.candy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        ?end,
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(title: title, trailing: trailing),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Widget chip(String label, String? value) {
      final bool active = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          selected: active,
          button: true,
          label: 'Filter $label',
          excludeSemantics: true,
          child: Pressable(
            onTap: () => onSelected(value),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active ? scheme.primaryContainer : scheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48 + MediaQuery.textScalerOf(context).scale(13) - 13,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
        children: <Widget>[
          chip('Semua', null),
          for (final String category in categories) chip(category, category),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.cartTargetKey,
    required this.onLogin,
    required this.onCart,
    required this.onCheckout,
    required this.onShop,
    required this.onOrder,
  });

  final MissionViewState state;
  final GlobalKey cartTargetKey;
  final VoidCallback onLogin;
  final VoidCallback onCart;
  final VoidCallback onCheckout;
  final VoidCallback onShop;
  final ValueChanged<String> onOrder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final MissionTones tones = MissionTones.of(context);
    if (!state.signedIn) {
      return Row(
        children: <Widget>[
          _CartBadge(key: cartTargetKey, count: _cartCount(state)),
          const SizedBox(width: 12),
          Expanded(
            child: CandyButton(
              label: 'Masuk untuk ikut misi',
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              onPressed: onLogin,
            ),
          ),
        ],
      );
    }
    if (state.allDone) {
      return CandyButton(
        key: cartTargetKey,
        label: 'Belanja lagi',
        variant: CandyVariant.tonal,
        onPressed: onShop,
      );
    }
    final MissionPendingOrder? pending = state.pendingOrder;
    if (pending != null) {
      return CandyButton(
        key: cartTargetKey,
        label: 'Lihat pesanan',
        sublabel: 'Menunggu pesanan selesai',
        variant: CandyVariant.tonal,
        onPressed: () => onOrder(pending.orderId),
      );
    }
    final MissionProgress? progress = state.progress;
    final bool ready = state.phase == MissionPhase.ready;
    final int current = progress?.current ?? 0;
    final bool large = MediaQuery.textScalerOf(context).scale(16) > 20;
    final int count = _cartCount(state);
    final Widget action = CandyButton(
      label: ready ? 'Checkout' : 'Keranjang',
      semanticLabel: ready ? null : 'Lihat keranjang',
      icon: Badge(
        key: cartTargetKey,
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: FestivePalette.gold,
        textColor: FestivePalette.festDeep,
        offset: const Offset(8, -6),
        child: Icon(
          ready
              ? Icons.shopping_cart_checkout_rounded
              : Icons.shopping_cart_outlined,
          size: 20,
          color: Colors.white,
        ),
      ),
      pulse: ready,
      onPressed: ready ? onCheckout : onCart,
    );
    final Widget summary = Row(
      children: <Widget>[
        Expanded(
          child: Semantics(
            container: true,
            label: 'Produk misi di keranjang',
            value: ready
                ? '${rupiah(current)}, target tercapai'
                : '${rupiah(current)}, tambah '
                      '${rupiah(progress?.remaining ?? 0)} lagi, '
                      '$count produk di keranjang',
            excludeSemantics: true,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            Text(
                              'Di keranjang',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            CountUpText(
                              value: current,
                              prefix: 'Rp',
                              bump: true,
                              style: TextStyle(
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          ready
                              ? 'Target tercapai'
                              : 'Tambah ${rupiah(progress?.remaining ?? 0)} '
                                    'lagi',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w800,
                            color: ready ? tones.success : scheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final Widget content = large
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[summary, const SizedBox(height: 8), action],
          )
        : Row(
            children: <Widget>[
              Expanded(child: summary),
              const SizedBox(width: 10),
              Expanded(child: action),
            ],
          );
    final double fraction = progress?.fraction ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        content,
        Positioned(
          top: -_barInset.top,
          left: -_barInset.left,
          right: -_barInset.right,
          height: 4,
          child: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              key: const ValueKey<String>('mission-bar-progress'),
              tween: Tween<double>(end: fraction),
              duration: reduceMotionOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? child) =>
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: ready ? tones.success : scheme.primary,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  /// Padding bilah bawah `GameScaffold`; garis progres menempel di tepi atas.
  static const EdgeInsets _barInset = EdgeInsets.fromLTRB(16, 10, 16, 10);
}

int _cartCount(MissionViewState state) {
  int count = 0;
  for (final MissionOrderLine line in state.cartLines) {
    count += line.quantity;
  }
  return count;
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Image(image: MissionArt.bag, fit: BoxFit.contain),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RulesSheet extends StatelessWidget {
  const _RulesSheet({required this.state});

  final MissionViewState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> rules = <String>[
      'Hanya produk berpita Misi yang dihitung. Subtotalnya dihitung dari '
          'harga barang sebelum potongan Kelopak dan tanpa ongkir.',
      'Target harus tercapai dalam 1 pesanan. Satu pesanan menyelesaikan '
          'paling banyak 1 tahap.',
      'Voucher terbit setelah pesanan berstatus Selesai. Pesanan yang '
          'dibatalkan tidak dihitung.',
      'Tahap berikutnya terbuka setelah voucher tahap sebelumnya terbit.',
      'Voucher yang terpakai di pesanan yang kemudian dibatalkan kembali '
          'bisa dipakai selama masa berlakunya.',
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: <Widget>[
            Text(
              'Syarat & ketentuan Misi Belanja',
              style: TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            for (final MissionStage stage in state.stages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${stage.title}: belanja produk misi min. '
                  '${rupiah(stage.minOrderSubtotal)} dalam 1 pesanan, hadiah '
                  'voucher ${rupiah(stage.voucherAmount)} (min. belanja '
                  '${rupiah(stage.voucherMinSpend)}, berlaku '
                  '${stage.voucherValidDays} hari).',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            for (int i = 0; i < rules.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rules[i],
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
