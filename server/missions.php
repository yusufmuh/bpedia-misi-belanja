<?php

declare(strict_types=1);

/*
 * Misi Belanja bertahap - referensi server (PHP 8.2+).
 * Cermin aturan paket Dart misi_belanja 3.0.0 (lib/src/mission_stage.dart,
 * mission_order.dart, mission_products.dart, mission_voucher.dart).
 * Nominal dalam rupiah (int).
 * Hari = hari WIB sejak 1 Jan 1970: intdiv(unix + 25200, 86400).
 * Voucher berlaku sampai akhir hari expiresDay = issuedDay + voucherValidDays.
 *
 * Tahap boleh punya daftar produk misi (productCodes). Bila diisi, yang
 * dinilai adalah subtotal produk misi (harga x jumlah baris yang kodenya ada
 * di daftar) dalam satu pesanan Selesai; bila kosong, semua produk dihitung.
 * id dan title opsional: tanpa nilai menjadi "tahap-N" dan "Tahap N".
 *
 * `php server/missions.php` menjalankan swa-uji dengan tabel yang sama
 * seperti tes Dart. Di SAPI web berkas ini tidak mengeluarkan apa pun.
 */

/* Tahap 2 adalah nilai demo. Daftar produk misi diisi kampanye host. */
const MISSION_DEMO_STAGES = [
    ['number' => 1, 'minOrderSubtotal' => 75000, 'voucherAmount' => 10000, 'voucherMinSpend' => 100000, 'voucherValidDays' => 30, 'productCodes' => []],
    ['number' => 2, 'minOrderSubtotal' => 100000, 'voucherAmount' => 15000, 'voucherMinSpend' => 150000, 'voucherValidDays' => 30, 'productCodes' => []],
];

function missionWibDay(int $unixSeconds): int
{
    return intdiv($unixSeconds + 25200, 86400);
}

function missionRupiah(int $amount): string
{
    return ($amount < 0 ? '-Rp' : 'Rp') . number_format(abs($amount), 0, ',', '.');
}

/** ID tahap yang stabil; tanpa nilai eksplisit: tahap-1, tahap-2, ... */
function missionStageId(array $stage): string
{
    return (string) ($stage['id'] ?? ('tahap-' . $stage['number']));
}

/** Judul tahap di layar; tanpa nilai eksplisit: "Tahap 1". */
function missionStageTitle(array $stage): string
{
    return (string) ($stage['title'] ?? ('Tahap ' . $stage['number']));
}

/** Apakah produk $productCode dihitung untuk $stage (daftar kosong = semua). */
function missionCountsProduct(array $stage, string $productCode): bool
{
    $codes = $stage['productCodes'] ?? [];
    return $codes === [] || in_array($productCode, $codes, true);
}

/**
 * Harga x jumlah satu baris {productCode, unitPrice, quantity}. Baris dengan
 * harga atau jumlah yang tidak positif bernilai 0.
 */
function missionLineTotal(array $line): int
{
    $unitPrice = (int) ($line['unitPrice'] ?? 0);
    $quantity = (int) ($line['quantity'] ?? 0);
    return $unitPrice > 0 && $quantity > 0 ? $unitPrice * $quantity : 0;
}

/**
 * Subtotal yang dihitung untuk $stage: jumlah harga x jumlah dari baris yang
 * produknya termasuk produk misi tahap itu.
 *
 * @param list<array{productCode: string, unitPrice: int, quantity: int}> $lines
 */
function missionSubtotal(array $stage, array $lines): int
{
    $subtotal = 0;
    foreach ($lines as $line) {
        if (missionCountsProduct($stage, (string) ($line['productCode'] ?? ''))) {
            $subtotal += missionLineTotal($line);
        }
    }
    return $subtotal;
}

/**
 * Kemajuan $stage bila $lines dipesan dalam satu pesanan.
 *
 * @return array{current: int, target: int, remaining: int, reached: bool}
 */
function missionProgress(array $stage, array $lines): array
{
    $current = missionSubtotal($stage, $lines);
    $target = (int) $stage['minOrderSubtotal'];
    return [
        'current' => $current,
        'target' => $target,
        'remaining' => max(0, $target - $current),
        'reached' => $current >= $target,
    ];
}

/** Status tahap ke-$stageIndex (mulai 0): completed | active | locked. */
function missionStageStatus(int $stageIndex, int $issuedCount): string
{
    if ($stageIndex < $issuedCount) {
        return 'completed';
    }
    return $stageIndex === $issuedCount ? 'active' : 'locked';
}

function missionAllStagesDone(array $stages, int $issuedCount): bool
{
    return $issuedCount >= count($stages);
}

/**
 * Urutan pemeriksaan sama dengan evaluateOrder di Dart:
 * notCompleted, alreadyCounted, allStagesDone, belowThreshold.
 *
 * @param list<array{number: int, minOrderSubtotal: int, voucherAmount: int, voucherMinSpend: int, voucherValidDays: int}> $stages
 * @param list<string> $countedOrderIds
 * @return array{issuedStage: ?array, rejection: ?string}
 */
function missionEvaluateOrder(
    array $stages,
    int $issuedCount,
    array $countedOrderIds,
    string $orderId,
    int $eligibleSubtotal,
    bool $completed,
): array {
    if (!$completed) {
        return missionRejected('notCompleted');
    }
    if (in_array($orderId, $countedOrderIds, true)) {
        return missionRejected('alreadyCounted');
    }
    $active = max(0, $issuedCount);
    if (missionAllStagesDone($stages, $active)) {
        return missionRejected('allStagesDone');
    }
    $stage = $stages[$active];
    if ($eligibleSubtotal < $stage['minOrderSubtotal']) {
        return missionRejected('belowThreshold');
    }
    return ['issuedStage' => $stage, 'rejection' => null];
}

/**
 * Padanan missionEvaluateOrder untuk pesanan berisi $lines: yang dinilai
 * adalah subtotal produk misi tahap aktif. Sama dengan evaluateOrderLines di
 * Dart; satu pesanan menyelesaikan paling banyak satu tahap.
 *
 * @param list<array{productCode: string, unitPrice: int, quantity: int}> $lines
 * @return array{issuedStage: ?array, rejection: ?string}
 */
function missionEvaluateOrderLines(
    array $stages,
    int $issuedCount,
    array $countedOrderIds,
    string $orderId,
    array $lines,
    bool $completed,
): array {
    $active = max(0, $issuedCount);
    $subtotal = isset($stages[$active]) ? missionSubtotal($stages[$active], $lines) : 0;
    return missionEvaluateOrder($stages, $issuedCount, $countedOrderIds, $orderId, $subtotal, $completed);
}

/** @return array{issuedStage: null, rejection: string} */
function missionRejected(string $reason): array
{
    return ['issuedStage' => null, 'rejection' => $reason];
}

/** Voucher baru dengan kunci yang sama seperti MissionVoucher.toJson() di Dart. */
function missionIssueVoucher(array $stage, string $voucherId, string $sourceOrderId, int $issuedDay): array
{
    return [
        'id' => $voucherId,
        'stageNumber' => $stage['number'],
        'sourceOrderId' => $sourceOrderId,
        'amount' => $stage['voucherAmount'],
        'minSpend' => $stage['voucherMinSpend'],
        'issuedDay' => $issuedDay,
        'expiresDay' => $issuedDay + $stage['voucherValidDays'],
        'usedOnOrderId' => null,
    ];
}

/**
 * Voucher kembali bisa dipakai setelah pesanan pemakainya batal; masa berlaku
 * tidak berubah. Sama dengan MissionVoucher.release() di Dart.
 */
function missionReleaseVoucher(array $voucher): array
{
    $voucher['usedOnOrderId'] = null;
    return $voucher;
}

/** Status voucher: used | expired | active (terpakai lebih diutamakan). */
function missionVoucherStatus(array $voucher, int $today): string
{
    if ($voucher['usedOnOrderId'] !== null) {
        return 'used';
    }
    return $today > $voucher['expiresDay'] ? 'expired' : 'active';
}

/**
 * Urutan pemeriksaan sama dengan redeemProblem di Dart:
 * alreadyUsed, expired, sameOrder, belowMinimum. Null = boleh dipakai.
 */
function missionRedeemProblem(array $voucher, string $orderId, int $subtotal, int $today): ?string
{
    if ($voucher['usedOnOrderId'] !== null) {
        return 'alreadyUsed';
    }
    if ($today > $voucher['expiresDay']) {
        return 'expired';
    }
    if ($orderId === $voucher['sourceOrderId']) {
        return 'sameOrder';
    }
    if ($subtotal < $voucher['minSpend']) {
        return 'belowMinimum';
    }
    return null;
}

function missionRedeemMessage(string $problem, array $voucher, int $subtotal): string
{
    return match ($problem) {
        'alreadyUsed' => 'Voucher ini sudah dipakai.',
        'expired' => 'Voucher sudah kedaluwarsa.',
        'sameOrder' => 'Voucher berlaku untuk pesanan berikutnya, bukan pesanan yang menerbitkannya.',
        'belowMinimum' => 'Belanja ' . missionRupiah($voucher['minSpend'] - $subtotal) . ' lagi untuk memakai voucher ini.',
        default => 'Voucher tidak bisa dipakai di pesanan ini.',
    };
}

/**
 * Voucher misi pada state demo dalam bentuk JSON paket Dart. Entri format lama
 * {source, amount, minimum, spentOn} dipetakan agar sesi demo lama tetap terbaca.
 *
 * @return list<array>
 */
function missionVouchersOf(array $state, int $today): array
{
    $stored = $state['vouchers'] ?? [];
    if (!is_array($stored)) {
        throw new RuntimeException('Data voucher demo rusak.');
    }
    $vouchers = [];
    foreach (array_values($stored) as $index => $raw) {
        if (!is_array($raw)) {
            throw new RuntimeException('Data voucher demo rusak.');
        }
        if (array_key_exists('sourceOrderId', $raw)) {
            $vouchers[] = $raw;
            continue;
        }
        $stage = MISSION_DEMO_STAGES[$index] ?? MISSION_DEMO_STAGES[array_key_last(MISSION_DEMO_STAGES)];
        $source = (string) ($raw['source'] ?? '');
        $vouchers[] = [
            'id' => 'vch-' . ($index + 1) . '-' . $source,
            'stageNumber' => $index + 1,
            'sourceOrderId' => $source,
            'amount' => (int) ($raw['amount'] ?? $stage['voucherAmount']),
            'minSpend' => (int) ($raw['minimum'] ?? $stage['voucherMinSpend']),
            'issuedDay' => $today,
            'expiresDay' => $today + $stage['voucherValidDays'],
            'usedOnOrderId' => isset($raw['spentOn']) ? (string) $raw['spentOn'] : null,
        ];
    }
    return $vouchers;
}

/**
 * Pesanan yang sudah dievaluasi misi, termasuk sumber setiap voucher.
 *
 * @param list<array> $vouchers
 * @return list<string>
 */
function missionCountedOrdersOf(array $state, array $vouchers): array
{
    $stored = $state['countedOrders'] ?? [];
    $counted = is_array($stored) ? array_values(array_filter($stored, 'is_string')) : [];
    foreach ($vouchers as $voucher) {
        $counted[] = (string) $voucher['sourceOrderId'];
    }
    return array_values(array_unique($counted));
}

/**
 * Pesanan demo selesai -> evaluasi tahap aktif. Setiap pesanan selesai dicatat
 * sekali di countedOrders (terbit atau tidak), jadi tidak pernah dihitung dua kali.
 * Signature kompatibel dengan router hub (server/index.php); kirim $today
 * (hari WIB termasuk offset demo) agar masa berlaku mengikuti kalender demo.
 *
 * Bila $lines diisi ({productCode, unitPrice, quantity} per baris), yang
 * dinilai adalah subtotal produk misi tahap aktif dan $subtotal diabaikan.
 * $stages mengganti kampanye demo (misalnya tahap dengan productCodes).
 */
function recordDemoOrder(
    array &$state,
    int $subtotal,
    string $order,
    bool $completed,
    ?int $today = null,
    ?array $lines = null,
    ?array $stages = null,
): string {
    $today ??= missionWibDay(time());
    $stages ??= MISSION_DEMO_STAGES;
    $vouchers = missionVouchersOf($state, $today);
    $counted = missionCountedOrdersOf($state, $vouchers);
    $issued = count($vouchers);
    if ($lines !== null) {
        $subtotal = isset($stages[$issued]) ? missionSubtotal($stages[$issued], $lines) : 0;
    }
    $decision = missionEvaluateOrder($stages, $issued, $counted, $order, $subtotal, $completed);
    $rejection = $decision['rejection'];
    if ($rejection === 'notCompleted') {
        throw new DomainException('Pesanan belum selesai, jadi belum dihitung untuk misi.');
    }
    if ($rejection === 'alreadyCounted') {
        throw new DomainException('Pesanan ini sudah dihitung untuk misi.');
    }
    $state['countedOrders'] = [...$counted, $order];
    $state['vouchers'] = $vouchers;
    if ($rejection === 'allStagesDone') {
        return 'Pesanan dicatat · semua tahap selesai, tahap berikutnya menunggu kampanye';
    }
    if ($rejection === 'belowThreshold') {
        $stage = $stages[$issued];
        $what = ($lines !== null && ($stage['productCodes'] ?? []) !== []) ? 'subtotal produk misi ' : 'subtotal ';
        return 'Pesanan dicatat · ' . $what . missionRupiah($subtotal)
            . ' belum mencapai min. ' . missionRupiah($stage['minOrderSubtotal']);
    }
    $stage = $decision['issuedStage'];
    $state['vouchers'][] = missionIssueVoucher($stage, 'vch-' . $stage['number'] . '-' . $order, $order, $today);
    return 'Misi tahap ' . $stage['number'] . ' selesai · voucher ' . missionRupiah($stage['voucherAmount']) . ' terbit';
}

/**
 * Memakai voucher ke-$voucherIndex (0 = voucher Tahap 1) pada pesanan lain.
 * Satu pesanan hanya memakai satu voucher misi (Demo).
 */
function useDemoVoucher(array &$state, int $voucherIndex, int $subtotal, string $order, ?int $today = null): string
{
    $today ??= missionWibDay(time());
    $vouchers = missionVouchersOf($state, $today);
    $voucher = $vouchers[$voucherIndex] ?? null;
    if ($voucher === null) {
        throw new DomainException('Voucher tidak ditemukan.');
    }
    $problem = missionRedeemProblem($voucher, $order, $subtotal, $today);
    if ($problem !== null) {
        throw new DomainException(missionRedeemMessage($problem, $voucher, $subtotal));
    }
    foreach ($vouchers as $other) {
        if ($other['usedOnOrderId'] === $order) {
            throw new DomainException('Satu pesanan hanya bisa memakai satu voucher misi.');
        }
    }
    $vouchers[$voucherIndex]['usedOnOrderId'] = $order;
    $state['vouchers'] = $vouchers;
    return 'Voucher ' . missionRupiah($voucher['amount']) . ' dipakai · total barang '
        . missionRupiah(max(0, $subtotal - $voucher['amount']));
}

/**
 * Pesanan $order batal: voucher misi yang dipakai di pesanan itu kembali bisa
 * dipakai (masa berlaku tetap). Aman dipanggil berulang.
 */
function releaseDemoVoucher(array &$state, string $order, ?int $today = null): string
{
    $today ??= missionWibDay(time());
    $vouchers = missionVouchersOf($state, $today);
    $released = null;
    foreach ($vouchers as $index => $voucher) {
        if ($voucher['usedOnOrderId'] === $order) {
            $vouchers[$index] = missionReleaseVoucher($voucher);
            $released = $voucher;
        }
    }
    $state['vouchers'] = $vouchers;
    return $released === null
        ? 'Tidak ada voucher misi yang dipakai di pesanan ini'
        : 'Voucher ' . missionRupiah($released['amount']) . ' kembali bisa dipakai';
}

/**
 * Bagian misi untuk respons state API: tahap + id, judul, produk misi dan
 * status; voucher + status.
 *
 * @return array{missions: list<array>, allStagesDone: bool, vouchers: list<array>}
 */
function missionSnapshot(array $state, int $today, ?array $stages = null): array
{
    $stages ??= MISSION_DEMO_STAGES;
    $vouchers = missionVouchersOf($state, $today);
    $issued = count($vouchers);
    $missions = [];
    foreach (array_values($stages) as $index => $stage) {
        $missions[] = [
            'id' => missionStageId($stage),
            'title' => missionStageTitle($stage),
            'productCodes' => array_values($stage['productCodes'] ?? []),
            'status' => missionStageStatus($index, $issued),
        ] + $stage;
    }
    return [
        'missions' => $missions,
        'allStagesDone' => missionAllStagesDone($stages, $issued),
        'vouchers' => array_map(
            static fn (array $voucher): array => $voucher + ['status' => missionVoucherStatus($voucher, $today)],
            $vouchers,
        ),
    ];
}

/** Swa-uji aturan; mengembalikan kode keluar 0 bila semua cocok. */
function missionSelfTest(): int
{
    $failures = [];
    $checks = 0;
    $expect = static function (mixed $actual, mixed $expected, string $what) use (&$failures, &$checks): void {
        $checks++;
        if ($actual !== $expected) {
            $failures[] = $what . ': dapat ' . var_export($actual, true) . ', harus ' . var_export($expected, true);
        }
    };
    $rejects = static function (callable $run): bool {
        try {
            $run();
        } catch (DomainException) {
            return true;
        }
        return false;
    };
    $line = static fn (string $code, int $unitPrice, int $quantity = 1): array => [
        'productCode' => $code,
        'unitPrice' => $unitPrice,
        'quantity' => $quantity,
    ];
    $today = 20781;
    $demo = MISSION_DEMO_STAGES;
    $serum = ['number' => 1, 'id' => 'nov-serum', 'title' => 'Paket serum', 'minOrderSubtotal' => 75000, 'voucherAmount' => 10000, 'voucherMinSpend' => 100000, 'voucherValidDays' => 30, 'productCodes' => ['SERUM-A', 'TONER-B']];
    $mask = ['number' => 2, 'minOrderSubtotal' => 100000, 'voucherAmount' => 15000, 'voucherMinSpend' => 150000, 'voucherValidDays' => 30, 'productCodes' => ['MASKER-C']];
    $campaign = [$serum, $mask];

    $expect(missionWibDay((new DateTimeImmutable('2026-11-23T17:00:00Z'))->getTimestamp()), $today, 'hari WIB 24 Nov 2026');
    $expect(missionRupiah(10000), 'Rp10.000', 'format rupiah');
    $expect(missionRupiah(-25000), '-Rp25.000', 'format rupiah negatif');

    $expect([$demo[0]['minOrderSubtotal'], $demo[0]['voucherAmount'], $demo[0]['voucherMinSpend'], $demo[0]['voucherValidDays']], [75000, 10000, 100000, 30], 'tahap 1 demo');
    $expect([$demo[1]['minOrderSubtotal'], $demo[1]['voucherAmount'], $demo[1]['voucherMinSpend'], $demo[1]['voucherValidDays']], [100000, 15000, 150000, 30], 'tahap 2 demo v3');
    $expect([missionStageId($demo[0]), missionStageId($demo[1])], ['tahap-1', 'tahap-2'], 'id bawaan');
    $expect([missionStageTitle($demo[0]), missionStageTitle($demo[1])], ['Tahap 1', 'Tahap 2'], 'judul bawaan');
    $expect([missionStageId($serum), missionStageTitle($serum)], ['nov-serum', 'Paket serum'], 'id dan judul eksplisit');
    $expect(missionCountsProduct($demo[0], 'APA-SAJA'), true, 'daftar kosong: semua produk dihitung');
    $expect(missionCountsProduct($serum, 'SERUM-A'), true, 'produk misi dihitung');
    $expect(missionCountsProduct($serum, 'LIPSTIK-Z'), false, 'produk lain tidak dihitung');
    $expect(missionCountsProduct($serum, 'serum-a'), false, 'kode peka huruf besar');

    $statusTable = [0 => ['active', 'locked'], 1 => ['completed', 'active'], 2 => ['completed', 'completed']];
    foreach ($statusTable as $issued => $expected) {
        $expect([missionStageStatus(0, $issued), missionStageStatus(1, $issued)], $expected, "status tahap, terbit $issued");
    }
    $expect(missionStageStatus(2, 0), 'locked', 'tahap ketiga terkunci');
    $expect([missionAllStagesDone($demo, 1), missionAllStagesDone($demo, 2), missionAllStagesDone([], 0)], [false, true, true], 'allStagesDone');

    $expect(missionLineTotal($line('SERUM-A', 45000, 2)), 90000, 'baris: harga x jumlah');
    $expect(missionLineTotal($line('SERUM-A', 45000, 0)), 0, 'baris: jumlah 0');
    $expect(missionLineTotal($line('SERUM-A', -45000, 2)), 0, 'baris: harga negatif bernilai 0');
    $expect(missionLineTotal($line('SERUM-A', 45000, -2)), 0, 'baris: jumlah negatif bernilai 0');
    $mixed = [$line('SERUM-A', 45000), $line('LIPSTIK-Z', 120000, 2), $line('TONER-B', 15000, 2)];
    $expect(missionSubtotal($serum, $mixed), 75000, 'subtotal: hanya produk misi');
    $expect(missionSubtotal($demo[0], $mixed), 315000, 'subtotal: daftar kosong menghitung semua');
    $expect(missionSubtotal($serum, [$line('SERUM-A', 45000), $line('SERUM-A', 45000, 2)]), 135000, 'subtotal: produk sama di dua baris');
    $expect(missionSubtotal($serum, []), 0, 'subtotal: tanpa baris');
    $expect(missionSubtotal($serum, [$line('LIPSTIK-Z', 120000, 2)]), 0, 'subtotal: tanpa produk misi');
    $both = [$line('SERUM-A', 45000), $line('MASKER-C', 25000, 3)];
    $expect([missionSubtotal($serum, $both), missionSubtotal($mask, $both)], [45000, 75000], 'subtotal: tiap tahap daftar sendiri');

    $expect(missionProgress($serum, [$line('SERUM-A', 45000), $line('LIPSTIK-Z', 90000)]), ['current' => 45000, 'target' => 75000, 'remaining' => 30000, 'reached' => false], 'progres Rp45.000 dari Rp75.000');
    $expect(missionProgress($serum, [$line('SERUM-A', 25000, 3)]), ['current' => 75000, 'target' => 75000, 'remaining' => 0, 'reached' => true], 'progres tepat di ambang');
    $expect(missionProgress($serum, [$line('SERUM-A', 45000, 4)]), ['current' => 180000, 'target' => 75000, 'remaining' => 0, 'reached' => true], 'progres di atas ambang');
    $expect(missionProgress($serum, []), ['current' => 0, 'target' => 75000, 'remaining' => 75000, 'reached' => false], 'progres keranjang kosong');

    $evaluate = static fn (int $subtotal, int $issued = 0, array $counted = [], string $order = 'BP-1001', bool $completed = true): array
        => missionEvaluateOrder($demo, $issued, $counted, $order, $subtotal, $completed);
    $expect($evaluate(74999)['rejection'], 'belowThreshold', 'Rp74.999 ditolak');
    $expect($evaluate(75000)['issuedStage'], $demo[0], 'Rp75.000 menerbitkan tahap 1');
    $expect($evaluate(99999, 1, ['BP-1001'], 'BP-1002')['rejection'], 'belowThreshold', 'tahap 2: Rp99.999 ditolak');
    $expect($evaluate(100000, 1, ['BP-1001'], 'BP-1002')['issuedStage']['voucherAmount'] ?? null, 15000, 'tahap 2: voucher Rp15.000');
    $expect($evaluate(500000)['issuedStage']['number'] ?? null, 1, 'satu pesanan paling banyak satu tahap');
    $expect($evaluate(500000, 0, [], 'BP-1001', false)['rejection'], 'notCompleted', 'belum selesai');
    $expect($evaluate(500000, 0, ['BP-1001'])['rejection'], 'alreadyCounted', 'sudah dihitung');
    $expect($evaluate(500000, 2, ['BP-1001', 'BP-1002'], 'BP-1003')['rejection'], 'allStagesDone', 'semua tahap selesai');
    $expect($evaluate(0, 2, ['BP-1001'], 'BP-1001', false)['rejection'], 'notCompleted', 'urutan: notCompleted dulu');
    $expect($evaluate(0, 2, ['BP-1001'])['rejection'], 'alreadyCounted', 'urutan: alreadyCounted sebelum allStagesDone');

    $evaluateLines = static fn (array $lines, int $issued = 0, array $counted = [], string $order = 'BP-2001', bool $completed = true): array
        => missionEvaluateOrderLines($campaign, $issued, $counted, $order, $lines, $completed);
    $expect($evaluateLines([$line('SERUM-A', 45000), $line('TONER-B', 15000, 2)])['issuedStage'], $serum, 'baris: produk misi Rp75.000 menerbitkan tahap 1');
    $expect($evaluateLines([$line('SERUM-A', 74999), $line('LIPSTIK-Z', 250000, 2)])['rejection'], 'belowThreshold', 'baris: pesanan besar tanpa cukup produk misi');
    $expect($evaluateLines([$line('SERUM-A', 200000)], 1, ['BP-2001'], 'BP-2002')['rejection'], 'belowThreshold', 'baris: tahap 2 tidak menilai produk tahap 1');
    $expect($evaluateLines([$line('MASKER-C', 25000, 4)], 1, ['BP-2001'], 'BP-2002')['issuedStage'], $mask, 'baris: produk misi tahap 2');
    $expect($evaluateLines([$line('SERUM-A', 300000), $line('MASKER-C', 300000)])['issuedStage'], $serum, 'baris: paling banyak satu tahap');
    $expect($evaluateLines([$line('SERUM-A', 300000)], 0, [], 'BP-2001', false)['rejection'], 'notCompleted', 'baris: belum selesai');
    $expect($evaluateLines([$line('SERUM-A', 300000)], 0, ['BP-2001'])['rejection'], 'alreadyCounted', 'baris: sudah dihitung');
    $expect($evaluateLines([$line('MASKER-C', 300000)], 2, ['BP-2001', 'BP-2002'], 'BP-2003')['rejection'], 'allStagesDone', 'baris: semua tahap selesai');
    $parity = true;
    foreach ([0, 1, 2] as $issued) {
        foreach ([0, 74999, 75000, 99999, 100000] as $subtotal) {
            foreach ([true, false] as $completed) {
                $parity = $parity && missionEvaluateOrderLines($demo, $issued, [], 'BP-2001', [$line('APA-SAJA', $subtotal)], $completed)
                    === missionEvaluateOrder($demo, $issued, [], 'BP-2001', $subtotal, $completed);
            }
        }
    }
    $expect($parity, true, 'tanpa daftar produk misi: sama dengan missionEvaluateOrder');

    $voucher = missionIssueVoucher($demo[0], 'vch-1-BP-1001', 'BP-1001', $today);
    $expect(array_keys($voucher), ['id', 'stageNumber', 'sourceOrderId', 'amount', 'minSpend', 'issuedDay', 'expiresDay', 'usedOnOrderId'], 'kunci voucher stabil');
    $expect([$voucher['amount'], $voucher['minSpend'], $voucher['expiresDay']], [10000, 100000, $today + 30], 'voucher tahap 1');
    $expect(missionRedeemProblem($voucher, 'BP-1001', 150000, $today), 'sameOrder', 'pesanan asal');
    $expect(missionRedeemProblem($voucher, 'BP-1002', 99999, $today), 'belowMinimum', 'Rp99.999');
    $expect(missionRedeemProblem($voucher, 'BP-1002', 100000, $today), null, 'Rp100.000 boleh');
    $expect(missionRedeemProblem($voucher, 'BP-1002', 100000, $today + 31), 'expired', 'lewat masa berlaku');
    $expect(missionRedeemProblem($voucher, 'BP-1002', 100000, $today + 30), null, 'tepat di expiresDay');
    $used = $voucher;
    $used['usedOnOrderId'] = 'BP-1002';
    $expect(missionRedeemProblem($used, 'BP-1001', 0, $today + 99), 'alreadyUsed', 'urutan: alreadyUsed dulu');
    $expect(missionVoucherStatus($used, $today + 99), 'used', 'status terpakai diutamakan');
    $released = missionReleaseVoucher($used);
    $expect($released === $voucher, true, 'release: kembali seperti voucher baru');
    $expect($used['usedOnOrderId'], 'BP-1002', 'release: aslinya tidak berubah');
    $expect(missionReleaseVoucher($voucher) === $voucher, true, 'release: voucher belum dipakai tetap');
    $expect(missionRedeemProblem($released, 'BP-1003', 100000, $today + 5), null, 'release: boleh dipakai lagi');
    $expect(missionRedeemProblem($released, 'BP-1003', 100000, $today + 31), 'expired', 'release: masa berlaku tidak bertambah');
    $expect(missionRedeemProblem($released, 'BP-1001', 500000, $today), 'sameOrder', 'release: tetap bukan untuk pesanan asal');
    $second = missionIssueVoucher($demo[1], 'vch-2-BP-1002', 'BP-1002', $today);
    $expect([$second['amount'], $second['minSpend']], [15000, 150000], 'voucher tahap 2 v3');
    $expect(missionRedeemProblem($second, 'BP-1003', 149999, $today), 'belowMinimum', 'tahap 2: Rp149.999');
    $expect(missionRedeemProblem($second, 'BP-1003', 150000, $today), null, 'tahap 2: Rp150.000 boleh');

    $state = [];
    $expect(recordDemoOrder($state, 60000, 'BP-1', true, $today), 'Pesanan dicatat · subtotal Rp60.000 belum mencapai min. Rp75.000', 'alur: di bawah ambang');
    $expect($rejects(static function () use (&$state, $today): void {
        recordDemoOrder($state, 500000, 'BP-1', true, $today);
    }), true, 'alur: pesanan yang sama ditolak');
    $expect($rejects(static function () use (&$state, $today): void {
        recordDemoOrder($state, 500000, 'BP-2', false, $today);
    }), true, 'alur: belum selesai ditolak');
    $expect(recordDemoOrder($state, 80000, 'BP-2', true, $today), 'Misi tahap 1 selesai · voucher Rp10.000 terbit', 'alur: tahap 1 terbit');
    $expect(recordDemoOrder($state, 120000, 'BP-3', true, $today + 1), 'Misi tahap 2 selesai · voucher Rp15.000 terbit', 'alur: tahap 2 terbit');
    $expect(recordDemoOrder($state, 900000, 'BP-4', true, $today + 1), 'Pesanan dicatat · semua tahap selesai, tahap berikutnya menunggu kampanye', 'alur: semua tahap selesai');
    $expect(count($state['vouchers']), 2, 'alur: dua voucher');
    $expect($state['countedOrders'], ['BP-1', 'BP-2', 'BP-3', 'BP-4'], 'alur: tiap pesanan dicatat sekali');
    $expect($rejects(static function () use (&$state, $today): void {
        useDemoVoucher($state, 0, 150000, 'BP-2', $today + 2);
    }), true, 'alur: voucher tidak untuk pesanan asal');
    $expect(useDemoVoucher($state, 0, 150000, 'BP-5', $today + 2), 'Voucher Rp10.000 dipakai · total barang Rp140.000', 'alur: voucher dipakai');
    $expect($rejects(static function () use (&$state, $today): void {
        useDemoVoucher($state, 1, 150000, 'BP-5', $today + 2);
    }), true, 'alur: satu pesanan satu voucher misi');
    $expect($rejects(static function () use (&$state, $today): void {
        useDemoVoucher($state, 1, 149999, 'BP-6', $today + 2);
    }), true, 'alur: voucher tahap 2 butuh Rp150.000');
    $expect(releaseDemoVoucher($state, 'BP-5', $today + 3), 'Voucher Rp10.000 kembali bisa dipakai', 'alur: pesanan batal melepas voucher');
    $expect($state['vouchers'][0]['usedOnOrderId'], null, 'alur: voucher lepas');
    $expect(releaseDemoVoucher($state, 'BP-5', $today + 3), 'Tidak ada voucher misi yang dipakai di pesanan ini', 'alur: lepas berulang aman');
    $expect(useDemoVoucher($state, 0, 100000, 'BP-7', $today + 3), 'Voucher Rp10.000 dipakai · total barang Rp90.000', 'alur: voucher dipakai lagi');
    $snapshot = missionSnapshot($state, $today + 3);
    $expect(array_column($snapshot['missions'], 'status'), ['completed', 'completed'], 'snapshot: status tahap');
    $expect(array_column($snapshot['missions'], 'id'), ['tahap-1', 'tahap-2'], 'snapshot: id tahap');
    $expect(array_column($snapshot['missions'], 'title'), ['Tahap 1', 'Tahap 2'], 'snapshot: judul tahap');
    $expect($snapshot['allStagesDone'], true, 'snapshot: semua tahap selesai');
    $expect(array_column($snapshot['vouchers'], 'status'), ['used', 'active'], 'snapshot: status voucher');

    $products = [];
    $expect(
        recordDemoOrder($products, 0, 'BP-A', true, $today, [$line('SERUM-A', 45000), $line('LIPSTIK-Z', 250000)], $campaign),
        'Pesanan dicatat · subtotal produk misi Rp45.000 belum mencapai min. Rp75.000',
        'produk misi: pesanan besar tanpa cukup produk misi',
    );
    $expect(
        recordDemoOrder($products, 0, 'BP-B', true, $today, [$line('SERUM-A', 45000), $line('TONER-B', 15000, 2)], $campaign),
        'Misi tahap 1 selesai · voucher Rp10.000 terbit',
        'produk misi: tahap 1 terbit',
    );
    $expect(
        recordDemoOrder($products, 999999, 'BP-C', true, $today, [$line('SERUM-A', 300000)], $campaign),
        'Pesanan dicatat · subtotal produk misi Rp0 belum mencapai min. Rp100.000',
        'produk misi: subtotal argumen diabaikan bila baris dikirim',
    );
    $expect(
        recordDemoOrder($products, 0, 'BP-D', true, $today, [$line('MASKER-C', 25000, 4)], $campaign),
        'Misi tahap 2 selesai · voucher Rp15.000 terbit',
        'produk misi: tahap 2 terbit',
    );
    $productSnapshot = missionSnapshot($products, $today, $campaign);
    $expect(array_column($productSnapshot['missions'], 'id'), ['nov-serum', 'tahap-2'], 'snapshot produk misi: id');
    $expect(array_column($productSnapshot['missions'], 'productCodes'), [['SERUM-A', 'TONER-B'], ['MASKER-C']], 'snapshot produk misi: daftar produk');

    $legacy = ['vouchers' => [['source' => 'BP-9', 'amount' => 10000, 'minimum' => 100000, 'spentOn' => 'BP-10']]];
    $migrated = missionVouchersOf($legacy, $today);
    $expect([$migrated[0]['id'], $migrated[0]['sourceOrderId'], $migrated[0]['usedOnOrderId']], ['vch-1-BP-9', 'BP-9', 'BP-10'], 'voucher format lama terbaca');

    foreach ($failures as $failure) {
        fwrite(STDERR, 'GAGAL ' . $failure . PHP_EOL);
    }
    fwrite(STDOUT, sprintf('missions.php swa-uji: %d cek, %d gagal', $checks, count($failures)) . PHP_EOL);
    return $failures === [] ? 0 : 1;
}

if (PHP_SAPI === 'cli' && realpath((string) ($_SERVER['SCRIPT_FILENAME'] ?? '')) === __FILE__) {
    exit(missionSelfTest());
}
