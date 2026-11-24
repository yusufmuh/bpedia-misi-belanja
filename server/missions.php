<?php

declare(strict_types=1);

/*
 * Misi Belanja bertahap - referensi server (PHP 8.2+).
 * Cermin aturan paket Dart misi_belanja 2.0.0 (lib/src/mission_stage.dart,
 * mission_order.dart, mission_voucher.dart). Nominal dalam rupiah (int).
 * Hari = hari WIB sejak 1 Jan 1970: intdiv(unix + 25200, 86400).
 * Voucher berlaku sampai akhir hari expiresDay = issuedDay + voucherValidDays.
 */

const MISSION_DEMO_STAGES = [
    ['number' => 1, 'minOrderSubtotal' => 75000, 'voucherAmount' => 10000, 'voucherMinSpend' => 100000, 'voucherValidDays' => 30],
    ['number' => 2, 'minOrderSubtotal' => 100000, 'voucherAmount' => 5000, 'voucherMinSpend' => 100000, 'voucherValidDays' => 30],
];

function missionWibDay(int $unixSeconds): int
{
    return intdiv($unixSeconds + 25200, 86400);
}

function missionRupiah(int $amount): string
{
    return ($amount < 0 ? '-Rp' : 'Rp') . number_format(abs($amount), 0, ',', '.');
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
 */
function recordDemoOrder(array &$state, int $subtotal, string $order, bool $completed, ?int $today = null): string
{
    $today ??= missionWibDay(time());
    $vouchers = missionVouchersOf($state, $today);
    $counted = missionCountedOrdersOf($state, $vouchers);
    $decision = missionEvaluateOrder(MISSION_DEMO_STAGES, count($vouchers), $counted, $order, $subtotal, $completed);
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
        $stage = MISSION_DEMO_STAGES[count($vouchers)];
        return 'Pesanan dicatat · subtotal ' . missionRupiah($subtotal)
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
 * Bagian misi untuk respons state API: tahap + status, voucher + status.
 *
 * @return array{missions: list<array>, allStagesDone: bool, vouchers: list<array>}
 */
function missionSnapshot(array $state, int $today): array
{
    $vouchers = missionVouchersOf($state, $today);
    $issued = count($vouchers);
    $missions = [];
    foreach (MISSION_DEMO_STAGES as $index => $stage) {
        $missions[] = $stage + ['status' => missionStageStatus($index, $issued)];
    }
    return [
        'missions' => $missions,
        'allStagesDone' => missionAllStagesDone(MISSION_DEMO_STAGES, $issued),
        'vouchers' => array_map(
            static fn (array $voucher): array => $voucher + ['status' => missionVoucherStatus($voucher, $today)],
            $vouchers,
        ),
    ];
}
