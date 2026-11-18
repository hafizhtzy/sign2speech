# Kebijakan Pencatatan & Keamanan Audit Log (`public.audit_logs`)

Dokumen ini menjelaskan kebijakan pencatatan jejak audit operasional pada Sign2Speech Addendum V3 (`Phase 7`).

---

## 1. Peristiwa yang Wajib Dicatat

Setiap operasi sensitif pada sistem dicatat ke dalam tabel `public.audit_logs`:
- **Manajemen Produk & Kategori:** `product_created`, `product_updated`, `product_price_updated`, `product_archived`, `product_reactivated`, `category_upserted`.
- **Manajemen Inventaris:** `inventory_initial_opname`, `inventory_restock`, `inventory_adjustment_in`, `inventory_adjustment_out`, `inventory_damage`, `inventory_loss`.
- **Manajemen Konten Video:** `sign_video_uploaded`, `sign_video_published`, `sign_video_archived`, `sign_video_draft`.
- **Manajemen Staf & Akun:** `trusted_admin_provisioned`, `cashier_invited`, `cashier_activated`, `cashier_disabled`.
- **Operasional Transaksi & Pembayaran:** `payment_settled`, `order_status_preparing`, `order_status_readyForPickup`, `order_status_completed`, `order_status_cancelled`, `order_refunded`.

---

## 2. Imutabilitas & Perlindungan Akses

1. **Append-Only (Immutable):**
   - Perintah `UPDATE`, `DELETE`, dan `TRUNCATE` pada `public.audit_logs` dicabut (`REVOKE`) dari `anon` dan `authenticated`.
   - Trigger `trg_audit_logs_immutable` (`prevent_audit_log_mutation()`) memblokir setiap upaya pengubahan atau penghapusan baris audit log, bahkan oleh pengguna `ADMIN`.
2. **Hak Baca Khusus Admin:**
   - Policy RLS `audit_logs_admin_select` membatasi akses `SELECT` hanya kepada pengguna aktif dengan role `ADMIN` (`public.is_admin()`).
   - `CUSTOMER` dan `CASHIER` tidak memiliki akses baca maupun tulis langsung ke `public.audit_logs`.

---

## 3. Sanitasi Data Sensitif

Audit log **dilarang keras** mencatat:
- Kata sandi (*password*) pengguna atau kasir.
- `SUPABASE_SERVICE_ROLE_KEY`, `MIDTRANS_SERVER_KEY`, atau `SANDBOX_WEBHOOK_SECRET`.
- Token sesi JWT (`access_token` / `refresh_token`).
- Payload mentah kartu/kredensial pembayaran yang belum disanitasi.
