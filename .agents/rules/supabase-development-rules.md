# Aturan Pengembangan Supabase, PostgreSQL, & Storage (Cloud-to-Local Ready & Security Gate)

Dokumen ini adalah aturan resmi tingkat proyek (*Project Rule*) untuk pengembangan, modifikasi, integrasi, dan audit backend **Supabase (PostgreSQL, Realtime, Storage)** dalam aplikasi **Sign2Speech (`speech2sign`)**.

Setiap kali agen AI atau pengembang berinteraksi dengan konfigurasi Supabase, skema database PostgreSQL, Row Level Security (RLS), Realtime, atau Storage Buckets, **WAJIB mematuhi seluruh protokol berikut**.

---

## 1. Pemanggilan Skill Wajib Berdasarkan Domain Tugas

Agen dilarang memodifikasi skema PostgreSQL atau kode Supabase berdasarkan asumsi. Agen **WAJIB membaca dan menerapkan skill resmi** yang telah terpasang di `.agents/skills/` sesuai domain tugas:

| Domain Tugas | Skill Wajib | Path Skill | Trigger & Tanggung Jawab |
| :--- | :--- | :--- | :--- |
| **PostgreSQL Schema, RLS, & Indexing** | `supabase-postgres-best-practices` | [.agents/skills/supabase-postgres-best-practices](file:///c:/fadli/project/sign2speech/.agents/skills/supabase-postgres-best-practices/SKILL.md) | Pembuatan tabel, pemilihan tipe data, migrasi SQL, RLS policies, optimasi indeks, dan performa query. |
| **Arsitektur Flutter & Clean Code** | `flutter-apply-architecture-best-practices` | [.agents/skills/flutter-apply-architecture-best-practices](file:///c:/fadli/project/sign2speech/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md) | Isolasi 3-lapisan (Presentation, Domain, Data), injeksi dependensi GetX, dan pemisahan UI dari logika bisnis. |
| **Audit Keamanan Pra-Rilis** | `security-predeploy-gate` | [.agents/skills/security-predeploy-gate](file:///c:/fadli/project/sign2speech/.agents/skills/security-predeploy-gate/SKILL.md) | Validasi RLS, pencegahan kebocoran `service_role` key di client, dan pemeriksaan celah OWASP Mobile. |

---

## 2. Aturan Baku Arsitektur di Flutter (Clean Architecture + GetX)

1. **Isolasi 3-Lapisan (Presentation, Domain, Data):**
   - **Data Layer Only:** Seluruh panggilan `SupabaseClient`, `SupabaseStorageClient`, dan `RealtimeChannel` **HANYA boleh berada di Data Layer** (`lib/features/<feature>/data/datasources/` atau `lib/features/<feature>/services/`).
   - **Dilarang Keras di UI:** **Presentation Layer (Views, Screens, Widgets, Dialogs) DILARANG KERAS** mengimpor `package:supabase_flutter/supabase_flutter.dart` secara langsung.
   - **Komunikasi ke Controller:** View berkomunikasi hanya melalui `GetxController`, dan Controller memanggil Service/Data Source.

2. **Desain Cloud-to-Local Ready (1-Line Switchable):**
   - Seluruh URL dan Anon Key Supabase wajib dikonfigurasi terpusat di [`lib/core/constants/app_constants.dart`](file:///c:/fadli/project/sign2speech/lib/core/constants/app_constants.dart) menggunakan `String.fromEnvironment`.
   - Kode di Service, Controller, maupun UI **dilarang keras** meng-hardcode domain Supabase Cloud, sehingga perpindahan dari **Supabase Cloud** ke **Self-Hosted Supabase Docker di Mini PC Lokal (On-Premise)** cukup dilakukan dengan mengganti 1 baris `supabaseUrl`.

3. **Pemodelan State Menggunakan Dart 3 `sealed class`:**
   - Setiap operasi asinkron database dan storage **WAJIB** mengembalikan `sealed class` (`SupabaseResult<T>`):
     ```dart
     sealed class SupabaseResult<T> {
       const SupabaseResult();
     }
     final class SupabaseSuccess<T> extends SupabaseResult<T> {
       final T data;
       const SupabaseSuccess(this.data);
     }
     final class SupabaseFailure<T> extends SupabaseResult<T> {
       final String errorMessage;
       final Object? error;
       const SupabaseFailure(this.errorMessage, [this.error]);
     }
     ```
   - Di Controller, gunakan **exhaustive pattern matching (`switch (result)`)** tanpa default fallback yang menyembunyikan error.

4. **Ketahanan Lingkungan Pengujian (Defensive Lazy Getter):**
   - Setiap service Supabase **WAJIB** mengimplementasikan **Defensive Lazy Getter** untuk `Supabase.instance.client`:
     ```dart
     SupabaseClient? get _supabase {
       if (_customSupabase != null) return _customSupabase;
       try {
         return Supabase.instance.client;
       } catch (_) {
         return null;
       }
     }
     ```
   - Jika `_supabase == null`, kembalikan `SupabaseFailure('SupabaseClient is not initialized')` atau `Stream.value([])` secara aman.
   - Hal ini menjamin bahwa *headless widget test* dan *unit test* dapat berjalan 100% lulus tanpa mengalami crash ketika `Supabase.initialize()` belum dipanggil.

5. **Injeksi Dependensi via GetX:**
   - Semua service didaftarkan secara terpusat di [`lib/presentation/navigation/app_binding.dart`](file:///c:/fadli/project/sign2speech/lib/presentation/navigation/app_binding.dart) menggunakan `Get.put<T>(..., permanent: true)` atau `Get.lazyPut<T>(...)`.

---

## 3. Standar Database PostgreSQL, RLS, & Storage

1. **Row Level Security (RLS) Wajib Aktif:**
   - Setiap tabel di schema `public` wajib mengaktifkan `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`.
   - Tabel `counter_sessions` wajib memiliki policy RLS yang mengizinkan operasi baca/tulis sinkronisasi 2 tablet (`KAFE-01`) agar tidak terkena blokir `permission-denied`.
2. **Validasi Kontrak Skema (CHECK Constraints):**
   - Gunakan `CHECK` constraints di level tabel PostgreSQL untuk membatasi panjang string, nilai enum (`status`, `payment_method`, `stage`, `sign_language_type`), serta nilai numerik (`price >= 0`, `stamps_count >= 0`).
3. **Manajemen Storage & Kompresi Gambar Menu:**
   - Setiap unggahan foto ke bucket `menu-photos` wajib dikompres terlebih dahulu menggunakan `flutter_image_compress` (maksimal 800x800 px, kualitas 75%) agar hemat ruang penyimpanan dan bandwidth lokal/cloud.
   - Saat mengubah atau menghapus foto menu, file foto lama di bucket `menu-photos` **wajib dihapus** berdasarkan `image_path` untuk mencegah penumpukan file yatim (*orphan files*).

---

## 4. Checklist Eksekusi Agen Sebelum Menyatakan Pekerjaan Selesai

- [ ] Telah membaca dan mengacu pada `supabase-postgres-best-practices` dan aturan ini.
- [ ] Tidak ada impor `supabase_flutter` di dalam folder `screens/` atau `widgets/`.
- [ ] Semua service mengimplementasikan Defensive Lazy Getter dan mengembalikan `sealed class` result.
- [ ] Konfigurasi URL mendukung perpindahan 1 baris dari Cloud ke Mini PC Lokal.
- [ ] Menjalankan `flutter analyze` dan memastikan 0 warning / 0 error.
- [ ] Menjalankan `flutter test` dan memastikan seluruh unit & widget test 100% lulus.
