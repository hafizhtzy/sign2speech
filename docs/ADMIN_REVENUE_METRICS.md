# Definisi Metrik Pendapatan & Integritas Laporan Keuangan Admin

Dokumen ini mendefinisikan rumus dan aturan akuntansi yang diterapkan pada **Admin Dashboard** dan **Sales Reports** (`rpc_admin_dashboard_metrics` di [20261118000000_three_role_rbac_and_erp_schema.sql](file:///c:/fadli/project/sign2speech/supabase/migrations/20261118000000_three_role_rbac_and_erp_schema.sql)).

---

## 1. Zona Waktu Bisnis Resmi (`Asia/Jakarta`)

- Seluruh kolom waktu di database (`created_at`, `paid_at`, `completed_at`, `expires_at`) disimpan secara konsisten dalam **UTC (`TIMESTAMPTZ`)**.
- Perhitungan filter rentang tanggal laporan (Hari Ini, Kemarin, 7 Hari Terakhir, 30 Hari Terakhir, Bulan Ini, Rentang Kustom) dilakukan di PostgreSQL menggunakan konversi eksplisit:
  ```sql
  (o.paid_at AT TIME ZONE 'Asia/Jakarta')::date BETWEEN p_start_date AND p_end_date
  ```
- Jam lokal perangkat Flutter **tidak** dijadikan sumber kebenaran agregasi laporan.

---

## 2. Definisi Metrik Keuangan

1. **Penjualan Kotor (`Gross Sales`):**
   - Total nilai `grand_total` dari pesanan yang pembayarannya telah terverifikasi berhasil (`payment_status IN ('paid', 'refunded', 'partially_refunded')`).
   - Pesanan berstatus `unpaid`, `pending`, `failed`, `expired`, atau `cancelled` **tidak pernah** dihitung sebagai penjualan.
2. **Total Refund (`Refunded Amount`):**
   - Jumlah nominal `amount` pada tabel `public.refunds` yang berstatus `completed` dalam periode laporan.
3. **Penjualan Bersih (`Net Sales`):**
   $$\text{Net Sales} = \max(\text{Gross Sales} - \text{Refunded Amount}, 0)$$
4. **Rata-rata Nilai Transaksi (`Average Order Value / AOV`):**
   $$\text{AOV} = \frac{\text{Net Sales}}{\text{Jumlah Transaksi Berhasil}}$$
   Jika belum ada transaksi berhasil (`success_count = 0`), maka $\text{AOV} = 0$.
5. **Laba Bersih / Kotor Berbasis HPP (`Net Profit`):**
   - Hanya dihitung apabila **seluruh** item yang terjual pada periode laporan memiliki nilai snapshot harga modal (`cost_price_snapshot IS NOT NULL`).
   - Jika terdapat satu saja item terjual yang belum memiliki harga modal (`cost_price` kosong), database mengembalikan `has_complete_cost_data = false` dan `net_profit = null`.
   - Aplikasi **dilarang mengarang angka keuntungan** atau menyamakan omzet (`Gross/Net Sales`) dengan keuntungan bersih.

---

## 3. Snapshot Harga Historis & Isolasi Simulasi

- Setiap saat pesanan dibuat, `rpc_create_order_with_reservation` menyalin `unit_price_snapshot` dan `cost_price_snapshot` ke tabel `public.cafe_order_items`.
- Mengubah harga jual atau HPP produk di kemudian hari **tidak mengubah** total penjualan maupun laporan historis transaksi lama.
- Transaksi simulasi sandbox (`is_simulation = true`) dipisahkan secara default (`p_include_simulations = false`) agar data pengujian tidak mencemari laporan keuangan operasional riil.
