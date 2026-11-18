# Matriks Kontrol Akses Tiga Peran (Three-Role Access Control Matrix)

Dokumen ini merupakan spesifikasi resmi otorisasi **Least Privilege** pada aplikasi **Sign2Speech (Addendum V3)** untuk tiga peran: **`CUSTOMER`**, **`CASHIER`**, dan **`ADMIN`**.

---

## 1. Pemisahan Peran Otorisasi vs Mode Komunikasi Aksesibilitas

- **Authorization Role ([AppUserRole](file:///c:/fadli/project/sign2speech/lib/core/auth/models/app_user_role.dart)):**
  - `customer`, `cashier`, `admin`.
  - Disimpan secara otoritatif pada tabel PostgreSQL `public.profiles` dan diverifikasi melalui fungsi `SECURITY DEFINER` (`public.current_active_role()`) serta Edge Function Guard ([auth_guard.ts](file:///c:/fadli/project/sign2speech/supabase/functions/_shared/auth_guard.ts)).
- **Accessibility Communication Mode (`CommunicationMode`):**
  - `Teman Tuli` (`deaf`) dan `Teman Dengar` (`hearing`).
  - Mengatur preferensi komunikasi dua arah (Sign-to-Speech & Speech-to-Sign) tanpa memberikan eskalasi hak akses sistem.

---

## 2. Matriks Izin Fitur & Modul

| Modul / Fitur | CUSTOMER | CASHIER | ADMIN | Penegakan Server & Database |
| :--- | :---: | :---: | :---: | :--- |
| **Login** | Yes | Yes | Yes | Supabase Auth + verifikasi `profiles.status = 'active'` |
| **Register akun sendiri** | Yes | No | No | Trigger `handle_new_auth_user()` memaksa `role = 'customer'` |
| **Profil pengguna** | Own (Safe fields) | Own (Safe fields) | Own + Read Staff | Trigger `prevent_profile_role_escalation()` memblokir ubah `role`/`status` |
| **Katalog produk & harga** | Read Active | Read Active | Full CRUD | RLS `cafe_menus_select_v3` vs `cafe_menus_admin_*_v3` |
| **Membuat pesanan (Order)** | Yes (QRIS) | Walk-In POS | Authorized | RPC `rpc_create_order_with_reservation` |
| **Memproses status pesanan** | No | Yes (Workflow) | Monitor & Override | RPC `rpc_cashier_advance_order_status` |
| **Pembayaran QRIS** | Own Order | Monitor | Monitor | Edge Function `payment-create-qris` & `payment-webhook` |
| **Pembayaran Tunai (Cash)** | No | Yes (POS) | Monitor | RPC `rpc_cashier_complete_cash_order` |
| **Product CRUD & Archive** | No | No | Yes | RLS `public.is_admin()` + Storage `menu-photos` |
| **Category CRUD** | No | No | Yes | RLS `product_categories_admin_*` |
| **Price & Cost (HPP) Management** | No | No | Yes | RLS `public.is_admin()` + snapshot `cafe_order_items` |
| **Stock Opname & Adjustment** | No | No | Yes | RPC `rpc_admin_adjust_stock` (`public.is_admin()`) |
| **Laporan Stok Menipis** | No | Create & Read | Read & Resolve | RLS `low_stock_reports` |
| **Sign Video Library** | Published Only | Published Only | All (`draft`/`published`/`archived`) | RLS `sign_videos_select_published_or_admin` + Private Bucket Signed URLs |
| **Sign Video Upload & CRUD** | No | No | Yes | Storage RLS `sign-language-videos` (`public.is_admin()`) |
| **Cashier Account Management** | No | No | Yes | Edge Function `admin-manage-cashier` |
| **Revenue & Sales Analytics** | No | No | Yes | RPC `rpc_admin_dashboard_metrics` (`public.is_admin()`) |
| **Order Refund** | No | No | Yes | Edge Function `admin-process-refund` |
| **Activity & Audit Logs** | No | No | Read-Only | RLS `audit_logs_admin_select` + `REVOKE UPDATE, DELETE` |
| **Role Assignment** | No | No | Trusted Provisioning | CLI [provision_admin.mjs](file:///c:/fadli/project/sign2speech/supabase/scripts/provision_admin.mjs) & `admin-manage-cashier` (khusus `cashier`) |

---

## 3. Enam Lapisan Penegakan Keamanan

1. **Flutter UI:** Komponen mutasi (edit foto menu, manajemen stok, dashboard admin, FAB kasir) disembunyikan berdasarkan `AuthController.currentRole`.
2. **Flutter Routing:** [RoleGuardMiddleware](file:///c:/fadli/project/sign2speech/lib/core/auth/middlewares/role_guard_middleware.dart) memblokir navigasi lintas role dan mengalihkan pengguna ke halaman sesuai haknya.
3. **Backend Edge Functions:** Setiap fungsi memverifikasi JWT menggunakan `auth.getUser()` lalu memeriksa `profiles.role` dan `profiles.status = 'active'` di database.
4. **PostgreSQL RLS & Triggers:** Seluruh tabel `public.*` mengaktifkan RLS; fungsi `public.current_active_role()` memastikan pencabutan akses instan saat akun kasir dinonaktifkan.
5. **Supabase Storage:** Bucket `sign-language-videos` bersifat privat; `CUSTOMER` hanya dapat mengakses objek dengan `publication_status = 'published'`, dan mutasi `menu-photos`/`sign-language-videos` dibatasi hanya untuk `ADMIN`.
6. **Realtime Subscriptions:** Stream profil mencabut sesi secara otomatis di perangkat jika `status` berubah menjadi `disabled`.
