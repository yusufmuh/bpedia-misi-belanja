import 'package:flutter/painting.dart';

import 'kit/sprite_sheet.dart';

const String _package = 'misi_belanja';

/// Seni 3D, pose Bipy, dan stiker milik modul (dirujuk dengan `package:`).
abstract final class MissionArt {
  /// Tas belanja 3D.
  static const AssetImage bag = AssetImage(
    'assets/art/bag.webp',
    package: _package,
  );

  /// Kupon tiket 3D (hadiah voucher).
  static const AssetImage ticket = AssetImage(
    'assets/art/ticket.webp',
    package: _package,
  );

  /// Bendera target di ujung bar progres.
  static const AssetImage flag = AssetImage(
    'assets/art/flag.webp',
    package: _package,
  );

  /// Koin Kelopak 3D.
  static const AssetImage coin = AssetImage(
    'assets/art/coin.webp',
    package: _package,
  );

  /// Bipy membawa tas belanja (maskot Misi Belanja).
  static const AssetImage poseShopping = AssetImage(
    'assets/bipy/bipy_pose_belanja.webp',
    package: _package,
  );

  /// Bipy melompat dengan tas dan bunga (misi tuntas).
  static const AssetImage poseParty = AssetImage(
    'assets/bipy/bipy_pose_pesta.webp',
    package: _package,
  );

  /// Bipy menyemangati (keadaan kosong, semua tahap selesai).
  static const AssetImage poseCheer = AssetImage(
    'assets/bipy/bipy_pose_semangat.webp',
    package: _package,
  );

  /// Stiker hati.
  static const AssetImage stickerHeart = AssetImage(
    'assets/fx/stiker_hati.webp',
    package: _package,
  );

  /// Stiker kilau empat sudut.
  static const AssetImage stickerSparkle = AssetImage(
    'assets/fx/stiker_kilau.webp',
    package: _package,
  );

  /// Stiker bunga merah.
  static const AssetImage stickerFlower = AssetImage(
    'assets/fx/stiker_bunga_merah.webp',
    package: _package,
  );

  /// Stiker wajah tersenyum.
  static const AssetImage stickerSmile = AssetImage(
    'assets/fx/stiker_senyum.webp',
    package: _package,
  );

  /// Stiker bintang.
  static const AssetImage stickerStar = AssetImage(
    'assets/fx/stiker_bintang.webp',
    package: _package,
  );
}

/// Lembar sprite Bipy milik modul (12 fps, urut baris).
abstract final class MissionSprites {
  /// Bipy berjalan membawa tas belanja sambil melambai (berulang).
  static const SpriteSheetSpec walk = SpriteSheetSpec(
    asset: 'assets/bipy/bipy_jalan.webp',
    package: _package,
    columns: 6,
    rows: 5,
    frameCount: 28,
    frameSize: Size(320, 340),
  );

  /// Bipy melambai (sekali).
  static const SpriteSheetSpec wave = SpriteSheetSpec(
    asset: 'assets/bipy/bipy_sapa.webp',
    package: _package,
    columns: 10,
    rows: 4,
    frameCount: 40,
    frameSize: Size(200, 340),
    loopMode: SpriteLoopMode.once,
  );
}
