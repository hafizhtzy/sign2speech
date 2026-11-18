# Manajemen Konten Video Bahasa Isyarat & Pemisahan Pipeline AI

Dokumen ini menjelaskan arsitektur pengelolaan video bahasa isyarat di dalam aplikasi (`Phase 5`) serta batas tegas antara katalog video referensi dengan pelatihan model AI MotionGRU.

---

## 1. Alur Publikasi Video (`Sign Language Content Management`)

```text
ADMIN PILIH FILE MP4 -> VALIDASI (MIME, <= 50MB, Header ISO-BMFF 'ftyp')
  -> PREVIEW LOKAL -> UNGGAH KE PRIVATE BUCKET 'sign-language-videos'
  -> SIMPAN METADATA 'public.sign_language_videos' (Status: DRAFT)
  -> ADMIN PUBLISH -> CUSTOMER DAPAT MENONTON MELALUI SIGNED URL
```

- **Sinkronisasi & Kompensasi Kegagalan:**
  Apabila unggah file ke Storage berhasil namun penyimpanan metadata ke PostgreSQL gagal (atau dibatalkan), [SupabaseAdminSignVideoService](file:///c:/fadli/project/sign2speech/lib/features/admin/data/datasources/supabase_admin_sign_video_service.dart) secara otomatis menghapus file dari Storage agar tidak terjadi file *orphan*.
- **Isolasi Akses Pelanggan:**
  Bucket `sign-language-videos` bersifat privat. Policy RLS pada `storage.objects` dan `public.sign_language_videos` memastikan `CUSTOMER` hanya dapat melihat dan memutar video yang berstatus `published`. Video berstatus `draft` atau `archived` tidak dapat diakses oleh pelanggan.

---

## 2. Batas Tegas: Video Referensi Pembelajaran vs Dataset Model AI MotionGRU

> **PENTING (Wajib Dipahami Pengelola & Pengembang):**
> Mengunggah atau mempublikasikan video baru melalui modul **Sign Language Content Management** di Admin Dashboard **HANYA** menambahkan materi video referensi/pembelajaran ke perpustakaan aplikasi (untuk ditonton pengguna dan diputar pada fitur Speech-to-Sign).
>
> **Mengunggah video ke aplikasi TIDAK membuat model AI kamera (MotionGRU / TFLite) otomatis mengenali gestur baru tersebut pada fitur Sign-to-Speech.**

Apabila suatu kosakata baru ingin dikenali oleh kamera AI secara real-time, diperlukan pipeline Machine Learning terpisah di luar CRUD aplikasi:
1. Pengumpulan dataset multi-subjek & multi-sudut pencahayaan.
2. Kurasi kualitas & pelabelan (*labeling* gloss BISINDO/SIBI).
3. Ekstraksi 543 koordinat MediaPipe Holistic menjadi fitur 706-D (353 spasial + 353 delta velocity).
4. Pembagian *train / validation / test split*.
5. Pelatihan ulang (*training*) dan evaluasi akurasi model MotionGRU.
6. Ekspor ke TFLite Float16 beserta verifikasi kontrak label & *rollback versioning*.
