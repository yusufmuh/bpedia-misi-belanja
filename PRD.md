# PRD 03 · Misi Belanja Bertahap / Suf (Bpedia Kelopak)

**Versi 1.0 (Final & Resmi) · 24 November 2026 · Owner: Muhammad Yusuf (Bpedia)**  
Dokumen spesifikasi teknis dan aturan bisnis modul Misi Belanja Bertahap Bpedia Kelopak.  
Induk acuan: `bpedia-kelopak-hub/PRD.md`.

---

## 1. Tujuan & Nilai bagi Pengguna
Mendorong transaksi riil dan pesanan berulang (*repeat purchase*) di platform Bpedia. Pembeli yang menyelesaikan transaksi belanja berhak atas voucher diskon yang dapat digunakan pada transaksi berikutnya.

---

## 2. Struktur Misi Bertingkat (Suf / Tiered Levels)

| Tahap (Suf) | Syarat Belanja Pesanan | Hadiah yang Diterbitkan | Syarat Penggunaan Voucher |
|---|---|---|---|
| **Tahap 1** | Selesaikan 1 pesanan **≥ Rp75.000** | **Voucher Rp10.000** | Belanja berikutnya **minimal Rp100.000** |
| **Tahap 2** | Selesaikan 1 pesanan **≥ Rp100.000** | **Voucher Rp5.000** | Belanja berikutnya **minimal Rp100.000** |
| **Tahap Selanjutnya** | Dikonfigurasi dinamis via server | Voucher diskon / Kelopak | Sesuai konfigurasi kampanye aktif |

### Aturan Bisnis & Validasi Pesanan:
1. **Status Wajib Selesai**: Hanya pesanan yang telah berstatus **SELESAI (`completed`)** oleh sistem logistik/order Bpedia yang berhak memicu hadiah. Pesanan dalam status checkout, dibayar, dikirim, dibatalkan, atau diretur tidak berlaku.
2. **Perhitungan Subtotal**: Nilai yang diperiksa adalah subtotal harga produk (sesudah diskon produk, sebelum ongkir, biaya layanan, dan sebelum voucher misi ini).
3. **Mekanisme Berantai (Unlock)**: Tahap 2 hanya terbuka setelah voucher Tahap 1 berhasil diterbitkan.
4. **Anti-Self-Loop**: Voucher tidak dapat digunakan pada nomor pesanan yang menerbitkan voucher tersebut.
5. **Satu Pesanan Satu Tahap**: Satu pesanan belanja besar (misal Rp200.000) hanya menyelesaikan 1 tahap aktif saat itu.

---

## 3. Komponen Antarmuka & Aksesibilitas
1. **Kartu Tahap Misi**:
   - Menampilkan status: *"Tercapai"*, *"Aktif"*, atau *"Terkunci"*.
   - Rincian syarat belanja dan nominal voucher dalam format mata uang Rupiah (`Rp75.000`, `Rp10.000`).
2. **Tombol Penggunaan / Pengujian Voucher**:
   - Menampilkan status: *"Uji voucher di pesanan berikutnya"* atau *"Voucher sudah dipakai"*.
3. **Aksesibilitas**:
   - Semua teks nominal dan status menggunakan widget teks berbobot semantik tinggi untuk pembaca layar.

---

## 4. Integrasi Order Webhook & Checkout
- **Webhook Order Selesai**: `POST /v1/orders/completed`
  ```json
  {
    "eventId": "evt-77123",
    "userId": "usr-001",
    "orderId": "ORD-20261124-77",
    "completedAt": "2026-11-24T19:00:00+07:00",
    "eligibleSubtotal": 75000
  }
  ```
- **Validasi Checkout**: Backend checkout Bpedia memvalidasi apakah voucher milik pengguna yang sama, belum pernah dipakai, pesanan bukan pesanan asal, dan subtotal pesanan baru ≥ Rp100.000.

---

## 5. Pengujian Mutu (Test Scenarios)
1. Pesanan Rp74.999 tidak menyelesaikan Tahap 1.
2. Pesanan Rp75.000 yang berstatus selesai menerbitkan voucher Rp10.000 dan membuka Tahap 2.
3. Pesanan belum selesai (status pending/processing) tidak menerbitkan voucher.
4. Voucher Rp10.000 ditolak jika dicoba pada pesanan dengan subtotal di bawah Rp100.000.
5. Voucher Rp10.000 berhasil diterapkan pada pesanan baru senilai Rp100.000, menghasilkan subtotal akhir Rp90.000.
