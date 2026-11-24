import 'package:flutter/material.dart';

typedef MissionTerms = ({int threshold, int discount, int redeemMinimum});
const demoStages = <MissionTerms>[
  (threshold:75000,discount:10000,redeemMinimum:100000),
  (threshold:100000,discount:5000,redeemMinimum:100000),
];

bool qualifies({required MissionTerms terms, required int subtotal, required bool completed,
  required bool alreadyCounted}) => completed && !alreadyCounted && subtotal >= terms.threshold;

bool mayRedeem({required MissionTerms terms, required int subtotal, required String sourceOrder,
  required String nextOrder, required bool used}) => !used && nextOrder.isNotEmpty &&
  nextOrder != sourceOrder && subtotal >= terms.redeemMinimum;

String rupiah(int amount) => 'Rp${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

class ShoppingMissions extends StatelessWidget {
  const ShoppingMissions({super.key, required this.earned, required this.used,
    required this.onOrder, required this.onRedeem});
  final int earned;
  final Set<int> used;
  final VoidCallback? onOrder;
  final void Function(int index)? onRedeem;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
    for (var i=0;i<demoStages.length;i++) Padding(padding: const EdgeInsets.only(bottom:14),child:
      Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text('Tahap ${i+1} · ${i<earned ? "Tercapai" : i==earned ? "Aktif" : "Terkunci"}',
          style:Theme.of(context).textTheme.titleMedium),
        Text('Selesaikan satu pesanan ${rupiah(demoStages[i].threshold)} untuk voucher ${rupiah(demoStages[i].discount)}.'),
        Text('Minimal belanja berikutnya ${rupiah(demoStages[i].redeemMinimum)}.'),
        if (i==1) const Text('Contoh tahap lanjutan untuk simulasi.', style:TextStyle(fontStyle:FontStyle.italic)),
        if (i<earned) OutlinedButton(onPressed: used.contains(i) || onRedeem==null ? null : ()=>onRedeem!(i),
          child:Text(used.contains(i) ? 'Voucher sudah dipakai' : 'Uji voucher di pesanan berikutnya')),
      ])),
    if (earned<demoStages.length) FilledButton.icon(onPressed:onOrder,icon:const Icon(Icons.shopping_bag_outlined),
      label:const Text('Simulasikan pesanan selesai')),
  ]);
}
