import 'package:flutter/widgets.dart';
import 'package:misi_belanja/misi_belanja.dart';

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
  image: AssetImage('assets/products/$code.webp'),
  price: price,
  strikePrice: strikePrice,
  category: category,
  maxQuantity: maxQuantity,
);

/// Produk misi tahap 1 (demo): Animate skincare, harga dari katalog Bpedia
/// potret 25 Nov 2026.
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
  _product(
    'P39A06S01000046',
    'Animate Glowing Barrier Facial Wash 100 ml',
    22200,
  ),
  _product('P39A06S01000090', 'Animate Whitening Facial Serum 20 ml', 20500),
];

/// Produk misi tahap 2 (demo): Pinkflash dan Focallure.
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
    'P21P03C01000149',
    'Pinkflash L01 Lasting Matte Lipcream - N01',
    11439,
    category: 'Makeup',
  ),
  _product(
    'P21P03C01000171',
    'Pinkflash L02 Lasting Glossy Lipgloss - G03',
    11439,
    category: 'Makeup',
  ),
  _product(
    'P21F02C01000536',
    'Focallure Volumizing Mascara Fa44',
    28000,
    category: 'Makeup',
  ),
  _product(
    'P21P03C01000184',
    'Pinkflash Lasting Matte Loose Pressed Powder - 000',
    37240,
    category: 'Makeup',
  ),
  _product(
    'P21P03M01000068',
    'Pinkflash Double Head Eyeshadow Brush Pf-T04 #02',
    19720,
    category: 'Lashes & Tools',
  ),
];

/// Tahap demo modul (`demoMissionStages`) dengan daftar produk misi.
final List<MissionStage> demoStages = <MissionStage>[
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

/// Hari WIB saat ini.
int wibToday([DateTime? now]) {
  final DateTime wib = (now ?? DateTime.now()).toUtc().add(
    const Duration(hours: 7),
  );
  return DateTime.utc(
    wib.year,
    wib.month,
    wib.day,
  ).difference(DateTime.utc(1970)).inDays;
}

/// Pengendali demo dengan semua produk contoh.
LocalMissionController demoController({int? today}) => LocalMissionController(
  stages: demoStages,
  today: today ?? wibToday(),
  stageProducts: <int, List<MissionProduct>>{
    0: stageOneProducts,
    1: stageTwoProducts,
  },
  soundOn: true,
);
