<?php
declare(strict_types=1);

const DEMO_MISSIONS = [[75000, 10000, 100000], [100000, 5000, 100000]];

function recordDemoOrder(array &$state, int $subtotal, string $order, bool $completed): string {
    if (!$completed) throw new DomainException('Pesanan belum selesai.');
    $stage = count($state['vouchers']);
    if (!isset(DEMO_MISSIONS[$stage])) throw new DomainException('Semua tahap demo tercapai.');
    foreach ($state['vouchers'] as $voucher) {
        if ($voucher['source'] === $order) throw new DomainException('Pesanan ini sudah dihitung.');
    }
    [$threshold, $discount, $minimum] = DEMO_MISSIONS[$stage];
    if ($subtotal < $threshold) throw new DomainException('Subtotal belum memenuhi syarat tahap ini.');
    $state['vouchers'][] = ['source'=>$order, 'amount'=>$discount, 'minimum'=>$minimum, 'spentOn'=>null];
    return 'Voucher Rp' . number_format($discount, 0, ',', '.') . ' terbit · tahap ' . ($stage + 1);
}

function useDemoVoucher(array &$state, int $stage, int $subtotal, string $order): string {
    $v = $state['vouchers'][$stage] ?? null;
    if (!$v || $v['spentOn'] !== null || $order === $v['source'] || $subtotal < $v['minimum']) {
        throw new DomainException('Voucher tidak tersedia untuk pesanan ini.');
    }
    $state['vouchers'][$stage]['spentOn'] = $order;
    return 'Voucher digunakan · subtotal akhir Rp' . number_format($subtotal - $v['amount'], 0, ',', '.');
}
