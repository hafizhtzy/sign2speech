# Arsitektur Manajemen In-App Admin & Klasifikasi Data

Dokumen ini menjelaskan arsitektur pengelolaan operasional in-app pada Sign2Speech Addendum V3 (`Phase 9`) agar pemilik kafe tidak perlu menjalankan query SQL manual di Supabase Dashboard untuk kegiatan harian.

---

## 1. Klasifikasi Data dalam Sistem

### A. Data Master (Dikelola Penuh melalui UI Admin Dashboard)
- **Produk (`public.cafe_menus`):** Tambah produk, ubah harga jual, isi harga modal (HPP), unggah/ganti foto terkompresi (`menu-photos`), atur ambang stok minimum, arsipkan/aktifkan kembali.
- **Kategori (`public.product_categories`):** Tambah, edit, dan urutkan kategori menu.
- **Inventaris (`public.inventory_movements` & `public.low_stock_reports`):** Stock opname awal, restock, koreksi stok dengan alasan wajib, serta tindak lanjut laporan stok menipis dari kasir.
- **Video Bahasa Isyarat (`public.sign_language_videos` & bucket `sign-language-videos`):** Unggah MP4, pratinjau, edit metadata, publikasikan (`draft -> published`), dan arsipkan.
- **Akun Kasir (`public.profiles` & Edge Function `admin-manage-cashier`):** Undang kasir baru melalui email aktivasi, lihat status verifikasi & aktivitas transaksi, nonaktifkan/aktifkan kembali akses kasir secara instan.

### B. Data Transaksional (Integritas Dipertahankan, Tidak Boleh Dihapus Bebas)
- `public.cafe_orders` & `public.cafe_order_items` (snapshot harga & kuantitas).
- `public.payments`, `public.payment_events`, & `public.refunds`.
- `public.inventory_movements` & `public.audit_logs`.
- **Aturan:** Data transaksi tidak pernah dihapus dengan `DELETE` biasa. Koreksi bisnis dilakukan melalui alur resmi: **Cancel** (sebelum bayar), **Refund** (`admin-process-refund` setelah bayar), **Stock Adjustment** (untuk selisih fisik), atau **Archive** (untuk menonaktifkan master produk/video yang sudah memiliki referensi historis).

### C. Konfigurasi Infrastruktur & Rahasia Server (Bukan CRUD UI)
- `SUPABASE_SERVICE_ROLE_KEY`, `MIDTRANS_SERVER_KEY`, `SANDBOX_WEBHOOK_SECRET`.
- Dikelola ausschließlich melalui Supabase Secrets / `.env.server.secret` di sisi server dan skrip CLI [provision_admin.mjs](file:///c:/fadli/project/sign2speech/supabase/scripts/provision_admin.mjs).
