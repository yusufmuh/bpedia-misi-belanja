# PRD 03 · Misi Belanja Bertahap

**Versi 0.1 · 24 November 2026 · Pemilik keputusan bisnis: tim perdagangan Bpedia**

## Janji kepada pembeli
Selesaikan satu pesanan dengan nilai barang yang memenuhi syarat minimal Rp75.000. Setelah sistem pesanan menyatakan selesai, satu voucher Rp10.000 masuk ke akun. Pengguna dapat memakainya sekali pada pesanan berbeda berikutnya dengan belanja minimal Rp100.000. Tahap berikutnya terbuka sesudah hadiah tahap sebelumnya berhasil diterbitkan.

## Alur dan tahap
| Situasi | Yang terlihat | Keputusan sistem |
|---|---|---|
| Belum memenuhi syarat | Tahap 1 aktif, syarat dan hadiah terbaca | Arahkan ke katalog |
| Sudah dibayar atau dalam pengiriman | Pesanan sedang diproses | Tunggu status selesai dari sumber pesanan |
| Pesanan selesai dan cukup | Voucher tersedia dengan nilai, minimal belanja dan masa berlaku | Terbitkan satu voucher personal dan buka tahap berikutnya |
| Tahap berikutnya belum dikonfigurasi | Tahap berikutnya menunggu kampanye | Simpan progres yang telah diperoleh |
| Checkout baru memenuhi syarat | Diskon Rp10.000 dan total setelah diskon | Reservasi voucher pada checkout lalu konsumsi saat komit order |

Asumsi perhitungan adalah subtotal barang sesudah diskon produk, sebelum ongkir, biaya layanan dan voucher ini. Satu transaksi Rp75.000 memenuhi batas, dua transaksi Rp40.000 dan Rp35.000 terpisah tidak. Satu pesanan hanya memajukan satu tahap. Contoh tahap 2 untuk demo adalah pesanan selesai baru minimal Rp100.000 memberi voucher Rp5.000 dengan minimal penukaran Rp100.000. Tim bisnis menyetujui semua nilai tahap tambahan, stacking, kategori yang dikecualikan, masa berlaku dan biaya kampanye.

## Integrasi pesanan, dompet voucher dan checkout
Order service mengirim event terautentikasi berisi event_id, order_id, akun stabil, status, waktu selesai, mata uang IDR dan subtotal eligible integer. Pemroses mengabaikan duplikat serta event lama yang tiba setelah status baru. Transaksi menyimpan kemajuan, voucher unik (akun, kampanye, tahap), dan aktivasi tahap berikutnya. Validasi waktu penyelesaian terhadap saat tahap dibuka. Backend checkout memvalidasi kepemilikan, masa berlaku, jumlah belanja, order asal dan status voucher pada saat penggunaan. Reservasi memiliki tenggat, commit dapat diulang, pembayaran gagal melepaskan reservasi.

Pesanan dibatalkan sebelum selesai tidak memberi hadiah. Usulan untuk retur setelah hadiah terbit adalah membatalkan voucher yang belum dipakai dan menandai voucher terpakai untuk rekonsiliasi CS. Pemilik kebijakan menetapkan perlakuan retur parsial, retur sesudah penukaran, dan transaksi checkout yang sedang berjalan sebelum rilis.

## Uji penerimaan
1. Rp74.999 gagal dan Rp75.000 lolos hanya pada satu pesanan selesai. Pesanan dibayar, batal, atau berstatus proses belum menerbitkan voucher.
2. Dua salinan webhook atau dua perangkat menghasilkan satu voucher; pesanan yang sama tidak mengisi tahap selanjutnya.
3. Penukaran pada order asal gagal. Order berikutnya Rp99.999 gagal. Rp100.000 lolos dan diskon Rp10.000 terlihat dalam rincian checkout.
4. Satu voucher dipakai dari dua checkout serentak. Satu konsumsi sukses; yang lain menampilkan alasan dan memuat saldo voucher terbaru.
5. Tahap 2 hanya terbuka setelah penerbitan voucher pertama. Menukar voucher pertama bukan prasyarat pembukaan tahap 2. Uji pengembalian dan tertundanya webhook lintas hari.
6. Pengguna yang masuk kembali dari iOS, Android dan web melihat sumber pesanan, status dan voucher yang sama.

## Pengukuran
Product memantau jumlah akun yang masuk tahap, persentase voucher terbit, redemption pada order berbeda, waktu tunda webhook, pesanan ulangan, dan margin sesudah subsidi. Finance merekonsiliasi jumlah/nilai voucher issued, redeemed, expired, revoked, dan reserved dengan transaksi checkout.
