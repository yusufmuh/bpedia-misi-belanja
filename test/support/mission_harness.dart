import 'dart:io';

import 'package:flutter/material.dart';
import 'package:misi_belanja/misi_belanja.dart';

import 'host_theme.dart';

/// Kamis, 26 November 2026 (hari WIB).
final int demoToday = DateTime.utc(
  2026,
  11,
  26,
).difference(DateTime.utc(1970)).inDays;

MissionProduct _product(
  String code,
  String name,
  int price, {
  String category = 'Skincare',
  int? strikePrice,
  int? maxQuantity,
}) => MissionProduct(
  code: code,
  name: name,
  image: FileImage(File('example/assets/products/$code.webp')),
  price: price,
  strikePrice: strikePrice,
  category: category,
  maxQuantity: maxQuantity,
);

/// Produk misi tahap 1 (Animate, katalog potret 25 Nov 2026).
final List<MissionProduct> stageOneProducts = <MissionProduct>[
  _product('P39A06S01000021', 'Animate Brightening Facial Wash 100 ml', 17800),
  _product('P39A06S01000044', 'Animate Glowing Barrier Day Cream 10 g', 24800),
  _product('P39A06S01000089', 'Animate Whitening Day Cream 10 g', 19900),
  _product(
    'P39A06S01000003',
    'Animate Acne Care Serum 20 ml',
    20500,
    maxQuantity: 1,
  ),
  _product('P39A06S01000007', 'Animate Acne Solution Night Cream 10 g', 26000),
  _product('P39A06S01000032', 'Animate Facial Essence 60 Kapsul', 16000),
];

/// Produk misi tahap 2 (Pinkflash dan Focallure).
final List<MissionProduct> stageTwoProducts = <MissionProduct>[
  _product(
    'P21F02S01000024',
    'Focallure Acne Pimple Patch Fa186 - 1',
    10000,
    strikePrice: 11500,
  ),
  _product(
    'P21F02C01000026',
    'Focallure Air Fit Matte Liquid Lipstick Fa417 - 001',
    49091,
    category: 'Makeup',
  ),
  _product(
    'P21P03C01000082',
    'Pinkflash Duo Lipgloss Pf-L13 - D02',
    23230,
    category: 'Makeup',
  ),
  _product(
    'P21P03M01000068',
    'Pinkflash Double Head Eyeshadow Brush Pf-T04 #02',
    19720,
    category: 'Lashes & Tools',
  ),
];

/// Tahap demo dengan daftar produk misi (nilai `demoMissionStages`).
final List<MissionStage> harnessStages = <MissionStage>[
  for (final (int index, MissionStage stage) in demoMissionStages.indexed)
    MissionStage(
      number: stage.number,
      minOrderSubtotal: stage.minOrderSubtotal,
      voucherAmount: stage.voucherAmount,
      voucherMinSpend: stage.voucherMinSpend,
      voucherValidDays: stage.voucherValidDays,
      productCodes: <String>[
        for (final MissionProduct product
            in index == 0 ? stageOneProducts : stageTwoProducts)
          product.code,
      ],
    ),
];

/// Pengendali lokal dengan data demo.
LocalMissionController localController({
  bool signedIn = true,
  int issuedCount = 0,
  Map<String, int> cart = const <String, int>{},
  List<MissionVoucher> vouchers = const <MissionVoucher>[],
  bool? soundOn = true,
  bool withProducts = true,
  Duration latency = Duration.zero,
}) {
  return LocalMissionController(
    stages: harnessStages,
    today: demoToday,
    stageProducts: withProducts
        ? <int, List<MissionProduct>>{0: stageOneProducts, 1: stageTwoProducts}
        : const <int, List<MissionProduct>>{},
    signedIn: signedIn,
    issuedCount: issuedCount,
    cart: cart,
    vouchers: vouchers,
    soundOn: soundOn,
    latency: latency,
  );
}

/// Aplikasi uji yang memasang [child] dengan tema host.
Widget missionApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: hostTheme(Brightness.light),
    darkTheme: hostTheme(Brightness.dark),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child,
      ),
    ),
  );
}

/// Halaman Misi Belanja lengkap di atas [controller].
Widget missionPageApp(
  MissionController controller, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return missionApp(
    MissionsPage(controller: controller),
    brightness: brightness,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
}
