import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'kit/game_cue.dart';
import 'mission_products.dart';
import 'mission_stage.dart';
import 'mission_voucher.dart';

/// Produk misi sebagai data tampilan.
///
/// Modul tidak mengenal katalog: host mengisi nama, foto, harga, dan kategori.
@immutable
final class MissionProduct {
  /// Membuat data tampilan produk misi.
  const MissionProduct({
    required this.code,
    required this.name,
    required this.image,
    required this.price,
    this.strikePrice,
    this.category,
    this.maxQuantity,
  }) : assert(price >= 0, 'price must not be negative');

  /// Kode produk di katalog host.
  final String code;

  /// Nama produk.
  final String name;

  /// Foto produk.
  final ImageProvider image;

  /// Harga jual (rupiah) yang dihitung ke subtotal misi.
  final int price;

  /// Harga sebelum diskon (rupiah), bila ada.
  final int? strikePrice;

  /// Label kategori untuk chip filter (mis. "Skincare"). `null` = tanpa chip.
  final String? category;

  /// Batas jumlah di keranjang (stok atau batas per pesanan). `null` = bebas.
  final int? maxQuantity;

  /// Persen diskon dari [strikePrice], dibulatkan; `null` bila tidak ada.
  int? get discountPercent {
    final int? strike = strikePrice;
    if (strike == null || strike <= price || strike <= 0) return null;
    return ((strike - price) * 100 / strike).round();
  }

  @override
  bool operator ==(Object other) =>
      other is MissionProduct &&
      other.code == code &&
      other.name == name &&
      other.image == image &&
      other.price == price &&
      other.strikePrice == strikePrice &&
      other.category == category &&
      other.maxQuantity == maxQuantity;

  @override
  int get hashCode =>
      Object.hash(code, name, image, price, strikePrice, category, maxQuantity);

  @override
  String toString() => 'MissionProduct($code, $price)';
}

/// Pesanan yang sudah memenuhi target tahap aktif dan menunggu status
/// Selesai sebelum voucher terbit.
@immutable
final class MissionPendingOrder {
  /// Membuat ringkasan pesanan.
  const MissionPendingOrder({
    required this.orderId,
    required this.missionSubtotal,
    this.statusLabel,
  });

  /// Nomor pesanan (mis. `BP-261126-0001`).
  final String orderId;

  /// Subtotal produk misi di pesanan ini (rupiah).
  final int missionSubtotal;

  /// Status pesanan dari host (mis. "Dikemas", "Dikirim"). `null` = tanpa
  /// keterangan.
  final String? statusLabel;

  @override
  bool operator ==(Object other) =>
      other is MissionPendingOrder &&
      other.orderId == orderId &&
      other.missionSubtotal == missionSubtotal &&
      other.statusLabel == statusLabel;

  @override
  int get hashCode => Object.hash(orderId, missionSubtotal, statusLabel);
}

/// Tahap yang baru tuntas dan belum dirayakan di halaman.
@immutable
final class MissionCelebration {
  /// Membuat data perayaan.
  const MissionCelebration({
    required this.stage,
    required this.voucher,
    this.nextStage,
  });

  /// Tahap yang tuntas.
  final MissionStage stage;

  /// Voucher yang terbit.
  final MissionVoucher voucher;

  /// Tahap berikutnya yang kini terbuka, bila ada.
  final MissionStage? nextStage;

  @override
  bool operator ==(Object other) =>
      other is MissionCelebration &&
      other.stage == stage &&
      other.voucher == voucher &&
      other.nextStage == nextStage;

  @override
  int get hashCode => Object.hash(stage, voucher, nextStage);
}

/// Fase tahap aktif, dari sudut pandang pembeli.
enum MissionPhase {
  /// Belum ada produk misi di keranjang.
  notStarted,

  /// Ada produk misi di keranjang, belum mencapai target.
  inCart,

  /// Produk misi di keranjang sudah mencapai target: siap checkout.
  ready,

  /// Pesanan yang memenuhi target sedang menunggu status Selesai.
  awaitingCompletion,

  /// Semua tahap kampanye selesai.
  allDone,
}

/// Keadaan halaman Misi Belanja pada satu saat. Tak-berubah.
///
/// Progres tahap aktif diturunkan dengan aturan murni ([missionProgress])
/// dari [cartLines], jadi host cukup mengirim isi keranjang apa adanya.
@immutable
final class MissionViewState {
  /// Membuat keadaan dari nilai yang sudah dimuat host.
  const MissionViewState({
    required this.signedIn,
    required this.stages,
    required this.issuedCount,
    required this.today,
    this.products = const <MissionProduct>[],
    this.cartLines = const <MissionOrderLine>[],
    this.vouchers = const <MissionVoucher>[],
    this.pendingOrder,
    this.celebration,
    this.soundOn,
    this.busy = false,
  }) : assert(issuedCount >= 0, 'issuedCount must not be negative');

  /// Keadaan tamu: halaman tetap tampil, aksi utama menjadi "Masuk".
  const MissionViewState.guest({
    required this.stages,
    required this.today,
    this.products = const <MissionProduct>[],
    this.cartLines = const <MissionOrderLine>[],
    this.soundOn,
  }) : signedIn = false,
       issuedCount = 0,
       vouchers = const <MissionVoucher>[],
       pendingOrder = null,
       celebration = null,
       busy = false;

  /// Pengguna sudah masuk. Tamu melihat halaman tanpa progres pribadi.
  final bool signedIn;

  /// Tahap kampanye berurutan.
  final List<MissionStage> stages;

  /// Jumlah voucher misi yang sudah terbit (= tahap yang tuntas).
  final int issuedCount;

  /// Hari WIB saat ini (untuk status voucher).
  final int today;

  /// Produk misi tahap aktif.
  final List<MissionProduct> products;

  /// Isi keranjang host (semua produk; aturan murni memilih produk misi).
  final List<MissionOrderLine> cartLines;

  /// Voucher misi milik pengguna, terbaru lebih dulu.
  final List<MissionVoucher> vouchers;

  /// Pesanan yang memenuhi target dan menunggu status Selesai.
  final MissionPendingOrder? pendingOrder;

  /// Tahap yang baru tuntas dan belum dirayakan.
  final MissionCelebration? celebration;

  /// Status suara host. `null` menyembunyikan tombol suara.
  final bool? soundOn;

  /// Sedang memuat atau mengirim aksi.
  final bool busy;

  /// Indeks tahap aktif, atau `null` bila semua tahap selesai.
  int? get activeIndex => issuedCount < stages.length ? issuedCount : null;

  /// Tahap aktif, atau `null` bila semua tahap selesai.
  MissionStage? get activeStage {
    final int? index = activeIndex;
    return index == null ? null : stages[index];
  }

  /// Semua tahap kampanye selesai.
  bool get allDone => allStagesDone(stages: stages, issuedCount: issuedCount);

  /// Progres produk misi di keranjang menuju target tahap aktif.
  MissionProgress? get progress {
    final MissionStage? stage = activeStage;
    return stage == null ? null : missionProgress(stage, cartLines);
  }

  /// Fase tahap aktif.
  MissionPhase get phase {
    if (allDone) return MissionPhase.allDone;
    if (pendingOrder != null) return MissionPhase.awaitingCompletion;
    final MissionProgress? current = progress;
    if (current == null || current.current <= 0) return MissionPhase.notStarted;
    return current.reached ? MissionPhase.ready : MissionPhase.inCart;
  }

  /// Jumlah [code] di keranjang (0 bila tidak ada).
  int quantityOf(String code) {
    int total = 0;
    for (final MissionOrderLine line in cartLines) {
      if (line.productCode == code) total += line.quantity;
    }
    return total;
  }

  /// Label kategori unik dari [products], urut kemunculan.
  List<String> get categories {
    final List<String> result = <String>[];
    for (final MissionProduct product in products) {
      final String? category = product.category;
      if (category != null && !result.contains(category)) {
        result.add(category);
      }
    }
    return result;
  }

  /// Voucher yang masih bisa dipakai hari ini.
  int get activeVoucherCount => vouchers
      .where((MissionVoucher voucher) => voucher.isActiveOn(today))
      .length;

  /// Status tahap ke-[index] memakai aturan murni [stageStatus].
  StageStatus statusOf(int index) =>
      stageStatus(stageIndex: index, issuedCount: issuedCount);

  /// Salinan dengan sebagian nilai diganti. [clearPendingOrder] dan
  /// [clearCelebration] mengosongkan nilai opsional.
  MissionViewState copyWith({
    bool? signedIn,
    List<MissionStage>? stages,
    int? issuedCount,
    int? today,
    List<MissionProduct>? products,
    List<MissionOrderLine>? cartLines,
    List<MissionVoucher>? vouchers,
    MissionPendingOrder? pendingOrder,
    bool clearPendingOrder = false,
    MissionCelebration? celebration,
    bool clearCelebration = false,
    bool? soundOn,
    bool? busy,
  }) {
    return MissionViewState(
      signedIn: signedIn ?? this.signedIn,
      stages: stages ?? this.stages,
      issuedCount: issuedCount ?? this.issuedCount,
      today: today ?? this.today,
      products: products ?? this.products,
      cartLines: cartLines ?? this.cartLines,
      vouchers: vouchers ?? this.vouchers,
      pendingOrder: clearPendingOrder
          ? null
          : pendingOrder ?? this.pendingOrder,
      celebration: clearCelebration ? null : celebration ?? this.celebration,
      soundOn: soundOn ?? this.soundOn,
      busy: busy ?? this.busy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MissionViewState &&
      other.signedIn == signedIn &&
      listEquals(other.stages, stages) &&
      other.issuedCount == issuedCount &&
      other.today == today &&
      listEquals(other.products, products) &&
      listEquals(other.cartLines, cartLines) &&
      listEquals(other.vouchers, vouchers) &&
      other.pendingOrder == pendingOrder &&
      other.celebration == celebration &&
      other.soundOn == soundOn &&
      other.busy == busy;

  @override
  int get hashCode => Object.hash(
    signedIn,
    Object.hashAll(stages),
    issuedCount,
    today,
    Object.hashAll(products),
    Object.hashAll(cartLines),
    Object.hashAll(vouchers),
    pendingOrder,
    celebration,
    soundOn,
    busy,
  );

  @override
  String toString() =>
      'MissionViewState(signedIn: $signedIn, issuedCount: $issuedCount, '
      'phase: ${phase.name}, cart: ${cartLines.length} baris)';
}

/// Jembatan halaman ke sumber data. Halaman hanya membaca [state] dan
/// memanggil aksi; host yang menentukan data datang dari mana.
///
/// Panggil `notifyListeners` tiap kali [state] berubah.
abstract class MissionController extends ChangeNotifier {
  /// Keadaan terkini.
  MissionViewState get state;

  /// Memuat ulang keadaan (mis. saat halaman kembali terlihat).
  Future<void> refresh();

  /// Menambah satu [code] ke keranjang host. `false` bila gagal (mis. stok
  /// habis); halaman lalu memberi umpan balik lembut.
  Future<bool> addToCart(String code);

  /// Mengubah jumlah [code] di keranjang; 0 menghapus barisnya.
  Future<void> setQuantity(String code, int quantity);

  /// Menandai [MissionViewState.celebration] sudah ditampilkan.
  void acknowledgeCelebration();

  /// Membuka halaman Masuk.
  void openLogin();

  /// Membuka katalog belanja.
  void openShop();

  /// Membuka keranjang.
  void openCart();

  /// Membuka checkout (keranjang yang sudah mencapai target).
  void openCheckout();

  /// Membuka detail produk [code].
  void openProduct(String code);

  /// Membuka detail pesanan [orderId].
  void openOrder(String orderId);

  /// Membuka daftar voucher milik pengguna.
  void openVouchers();

  /// Memakai voucher [voucherId] (host membawa ke keranjang/checkout).
  void useVoucher(String voucherId);

  /// Mengganti status suara host. Hanya dipanggil bila
  /// [MissionViewState.soundOn] tidak `null`.
  void setSoundOn(bool on);

  /// Memutar suara game; host yang memetakan ke berkas audionya.
  void playCue(GameCue cue);
}
