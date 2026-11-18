# Laporan Verifikasi End-to-End, Keamanan & Regresi (Addendum V3)

Dokumen ini mencatat bukti verifikasi aktual untuk implementasi **Sign2Speech Master Prompt Addendum V3** (Sistem Tiga Peran: `CUSTOMER`, `CASHIER`, `ADMIN`, Dashboard Admin, Inventory Ledger & Stock Opname, Midtrans Core API QRIS, Manajemen Video Bahasa Isyarat, Manajemen Kasir, dan Audit Log).

---

## 1. Ringkasan Hasil Pengujian Otomatis & Static Analysis

| Kategori Verifikasi | Perintah | Hasil Aktual |
| :--- | :--- | :--- |
| **Static Analysis (`dart analyze`)** | `analyze_files` (Dart MCP) | **PASS (`No errors`)** |
| **Unit, Widget, Kontrak & Regression Suite** | `flutter test` | **PASS (`294/294 tests passed, 0 failures`)** |
| **Android APK Build (`x86_64` Debug)** | `flutter build apk --debug --target-platform android-x64 --dart-define-from-file=.env` | **PASS (`Built build\app\outputs\flutter-apk\app-debug.apk`)** |
| **Android Security Manifest Hardening** | Audit `AndroidManifest.xml` & `build.gradle.kts` | **PASS (`allowBackup="false"`, `usesCleartextTraffic="false"`, `isMinifyEnabled = true`)** |

---

## 2. Rincian Pengujian Tiga Peran & Kontrak Keamanan

### Test A — CUSTOMER (`test/features/customer/customer_order_and_qris_test.dart` & `test/core/auth/auth_rbac_and_storage_test.dart`)
- **Registrasi & Login:** Formulir `RegisterCustomerScreen` hanya membuat akun `CUSTOMER` tanpa opsi pemilihan role `CASHIER`/`ADMIN`.
- **Proteksi Stok Belum Opname:** Produk lama dengan `is_stock_initialized = false` menampilkan badge `Stok Belum Diopname`, tombol `+ Keranjang` dinonaktifkan (`onPressed == null`), dan `CustomerOrderController.addToCart` menolak penambahan ke keranjang.
- **Perhitungan Stok & Anti-Overselling:** `availableStock = stock_on_hand - stock_reserved` ditegakkan baik di controller maupun di dalam PostgreSQL `rpc_create_order_with_reservation` menggunakan row-level locking (`SELECT ... FOR UPDATE ORDER BY product_id`).
- **Midtrans Core API QRIS:** `QrisPaymentRecord` mengekstrak URL QR dari array `actions` (`generate-qr-code-v2` / `generate-qr-code`) tanpa mengasumsikan `qr_string` selalu ada, serta membedakan transaksi simulasi (`isSimulation = true`).

### Test B — CASHIER (`test/features/cafe_pos/cashier_rbac_and_low_stock_test.dart`)
- **Pembatasan Hak Akses Kasir:** Kasir diizinkan membuka `CafeCashierCounterScreen` (termasuk mode komunikasi Dual-View `Sisi Kasir | Sisi Pembeli` dan rotasi layar 180° untuk tamu *walk-in*), namun dilarang mengakses `/admin-dashboard` dan dilarang mengubah foto produk di `CoffeeDetailScreen` (`onEditPhoto == null`).
- **Laporan Stok Menipis (`ReportLowStockDialog`):** Kasir hanya melihat stok secara *read-only* dan mengirimkan laporan stok menipis ke tabel `public.low_stock_reports` untuk ditindaklanjuti Admin.

### Test C — ADMIN (`test/features/admin/admin_dashboard_and_erp_test.dart`)
- **13 Bagian Navigasi Admin Dashboard:** Terverifikasi navigasi responsif antara Overview, Products, Categories, Inventory, Orders, Transactions, Sales Reports, Sign Language Videos, Staff Management, Activity Logs, Settings, Profile, dan Logout.
- **Integritas Keuangan (`Asia/Jakarta`):** `AdminDashboardMetrics` menghitung `netSales = grossSales - refundedAmount` dalam zona waktu `Asia/Jakarta` dan memastikan `netProfit == null` ketika `has_complete_cost_data == false` (tidak pernah mengarang angka laba bersih).
- **Export Laporan:** `AdminReportExporterService` menghasilkan CSV RFC-4180 dan dokumen PDF (`%PDF-`) yang valid.

### Test D — Pencegahan Eskalasi Role & Pencabutan Sesi Kasir Instan
- `UserProfile.toSelfEditableMap()` menghapus field `role`, `status`, dan `email`.
- Trigger PostgreSQL `prevent_profile_role_escalation()` menolak setiap `UPDATE` kolom `role` atau `status` dari sesi client.
- Saat Admin menonaktifkan akun kasir (`AccountStatus.disabled`), `AuthController.applyProfileUpdate` langsung mencabut sesi autentikasi dan `RoleGuardMiddleware` mengalihkan pengguna ke `/login`.

### Test E & F — Kontrak SQL Concurrency & Validasi Video Bahasa Isyarat
- `test/core/supabase/three_role_migration_contract_test.dart` memverifikasi ketiadaan stok default fiktif (`DEFAULT 25`), penerapan `SECURITY DEFINER SET search_path = ''`, constraint deduplikasi webhook `dedup_key`, serta pencabutan `UPDATE/DELETE` pada `public.audit_logs`.
- `SupabaseAdminSignVideoService.validateVideoFile` memvalidasi ekstensi `.mp4`, batas ukuran $\le 50\text{ MB}$, dan *magic bytes* ISO-BMFF `ftyp`, dilengkapi *compensation delete* Storage jika penyimpanan metadata gagal serta banner eksplisit pemisahan perpustakaan video referensi dari pipeline training AI MotionGRU.

---

## 3. Panduan Deployment Supabase Cloud (Staging/Dev) & Provisioning Admin Pertama

Sesuai aturan keamanan nomor 5, migrasi SQL dan Edge Functions telah disiapkan secara lokal dan terkontrol versi. Untuk men-deploy ke proyek Supabase Cloud staging/dev Anda:

1. **Jalankan Migrasi Database:**
   ```bash
   npx supabase db push
   ```
2. **Deploy Empat Edge Functions:**
   ```bash
   npx supabase functions deploy admin-manage-cashier
   npx supabase functions deploy payment-create-qris
   npx supabase functions deploy payment-webhook --no-verify-jwt
   npx supabase functions deploy admin-process-refund
   ```
3. **Provisioning Akun ADMIN Pertama (Server-Side Trusted CLI):**
   Pastikan `SUPABASE_URL` dan `SUPABASE_SERVICE_ROLE_KEY` tersimpan di `.env.server.secret`, lalu jalankan:
   ```bash
   node supabase/scripts/provision_admin.mjs --email admin@sign2speech.id --name "Admin Utama" --password "<PasswordKuatMinimal8Karakter>"
   ```
