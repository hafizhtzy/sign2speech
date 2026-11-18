# Arsitektur Manajemen Inventaris, Stock Opname & Integrasi QRIS

Dokumen ini menjelaskan desain integritas stok, pencegahan *overselling*, dan alur rekonsiliasi pembayaran QRIS pada Sign2Speech Addendum V3.

---

## 1. Formula Stok & Wajib Stock Opname Awal

Pada tabel `public.cafe_menus`, setiap produk memiliki:
- `is_stock_initialized` (`BOOLEAN`, default `false`)
- `stock_on_hand` (`INTEGER >= 0`, stok fisik di kafe)
- `stock_reserved` (`INTEGER >= 0`, stok yang sedang ditahan oleh pesanan QRIS aktif)
- `low_stock_threshold` (`INTEGER >= 0`, batas peringatan stok menipis)

$$\text{Available Stock} = \text{stock\_on\_hand} - \text{stock\_reserved}$$

> **Aturan Tanpa Stok Fiktif:**
> Produk lama hasil migrasi tidak diberikan angka stok karangan (seperti default 25). Produk dengan `is_stock_initialized = false` berstatus **"Stok Belum Diinisialisasi (Wajib Stock Opname)"** dan ditolak oleh `rpc_create_order_with_reservation` sampai Admin melakukan **Stock Opname Awal (`initial_opname`)** melalui UI.

---

## 2. Inventory Ledger (`public.inventory_movements`)

Seluruh perubahan stok tidak pernah dilakukan dengan `UPDATE` mentah dari Flutter, melainkan melalui fungsi atomik PostgreSQL yang mencatat jejak audit di `public.inventory_movements`:

- **Jenis Pergerakan (`movement_type`):**
  - `initial_opname`: Inisialisasi stok awal oleh Admin.
  - `restock`: Penambahan stok masuk.
  - `adjustment_in` / `adjustment_out`: Koreksi stok manual dengan alasan wajib.
  - `damage` / `loss`: Pencatatan barang rusak atau hilang.
  - `reserve`: Reservasi stok otomatis saat order dibuat.
  - `release`: Pelepasan reservasi saat pembayaran QRIS gagal/expired/dibatalkan.
  - `sale`: Penyelesaian reservasi menjadi pengurangan stok fisik saat pembayaran terverifikasi.
  - `refund_restock`: Pengembalian stok dari proses refund yang memilih opsi restock.
- **Idempotensi Database:** Constraint unik `UNIQUE (reference_type, reference_id, product_id, movement_type)` menjamin satu event transaksi tidak pernah memotong atau melepaskan stok dua kali.

---

## 3. Siklus Hidup Stok & Pembayaran QRIS (Anti-Overselling)

1. **Checkout & Reservasi Atomik (`rpc_create_order_with_reservation`):**
   - Membersihkan reservasi QRIS yang sudah kedaluwarsa (`rpc_expire_stale_qris_reservations()`).
   - Mengunci baris produk (`SELECT ... FOR UPDATE ORDER BY product_id`) untuk mencegah *race condition* dan *deadlock* ketika dua pelanggan membeli stok terakhir secara bersamaan.
   - Memastikan `available_stock >= quantity`, lalu menambah `stock_reserved`.
2. **Pembuatan Charge QRIS (`payment-create-qris`):**
   - Menghubungi Midtrans Core API `/v2/charge` (atau simulator terkontrol khusus non-production) dengan `Idempotency-Key`.
3. **Penyelesaian Pembayaran (`payment-webhook` -> `rpc_finalize_payment_stock`):**
   - Memverifikasi signature SHA-512 Midtrans, mengunci baris `payments` (`FOR UPDATE`), mengecek deduplikasi `dedup_key`, lalu mengurangi `stock_on_hand` sekaligus `stock_reserved` tepat satu kali.
4. **Pembayaran Kedaluwarsa / Gagal (`rpc_release_stock_reservation`):**
   - Jika webhook mengirimkan `expire`, `cancel`, atau `deny`, atau waktu `expires_at` terlewati, `stock_reserved` dilepaskan kembali ke `available_stock`.
