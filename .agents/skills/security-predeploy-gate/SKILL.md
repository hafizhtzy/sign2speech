---
name: security-predeploy-gate
description: Pre-deployment security audit gate combining Trail of Bits static analysis, Supabase and Firebase security rules validation, and OWASP Mobile/Web/iOS verification. Use before declaring an application ready for production deployment, staging release, or final pull request merge.
---

# Security Pre-Deploy Gate (Trail of Bits, Supabase/Firebase Rules, & OWASP)

Panduan checklist dan gerbang audit keamanan otomatis (*blocking security gate*) yang wajib dievaluasi oleh coding agent sebelum kode dinyatakan siap rilis ke lingkungan produksi (*production ready*). Mengintegrasikan metodologi Trail of Bits, pengamanan database Supabase & Firebase, serta standar OWASP Web & Mobile (MASVS).

---

## 1. Aturan Gerbang Utama (Blocking Criteria)

Aplikasi **DILARANG KERAS** dinyatakan siap deploy jika terdapat salah satu dari pelanggaran kritis berikut:
1. **Secret Leak:** Ada private API key, service account JSON, private key, atau database password di repo atau binary.
2. **Database Vulnerability:** Ada tabel Supabase PostgreSQL tanpa Row Level Security (RLS), atau rule Firebase yang mengizinkan akses terbuka (`allow read, write: if true;`).
3. **Transport Security:** HTTP plaintext diizinkan pada aplikasi mobile atau endpoint API produksi tanpa enkripsi TLS 1.3.
4. **Insecure Storage:** Token autentikasi pengguna disimpan di storage plaintext (`UserDefaults`, `SharedPreferences`, `localStorage` untuk token sensitif).
5. **High/Critical CVE:** Dependensi eksternal memiliki kerentanan dengan skor CVSS $\ge 7.0$ tanpa mitigasi.

---

## 2. Gate 1: Trail of Bits Code & Secret Audit

Menerapkan pembuktian berbasis bukti (*evidence-led verification*):

### A. Scanning Kredensial & Secrets
```bash
# Jalankan pemindaian regex cepat untuk pola secret umum
rg -n -i "(api[_-]?key|secret|password|access[_-]?token|private[_-]?key)\s*[:=]\s*['\"][^'\"]{8,}['\"]" \
  --glob "!*.lock" --glob "!*.csv" --glob "!*.json"
```
- [ ] Pisahkan **Client Identifiers** (Firebase Web API Key, Supabase Anon Key) dari **Private Backend Secrets** (Stripe Secret, DB Admin Pass, Service Role Key).
- [ ] Pastikan `.env`, `.env.local`, dan file credentials terdaftar di `.gitignore`.

### B. Insecure Defaults & Semgrep Scan
- [ ] Dilarang menggunakan konfigurasi fallback `ALLOW_ALL_ORIGINS = true` atau `cors({origin: "*", credentials: true})`.
- [ ] Parameterized query untuk semua operasi SQL (tidak ada string concatenation pada ORM raw query).
- [ ] Nonaktifkan debugging endpoints (`/debug`, `/__test_login`, Swagger/OpenAPI terbuka di produksi tanpa auth).

---

## 3. Gate 2: Supabase PostgreSQL & Row Level Security (RLS) Gate

Pemeriksaan wajib untuk backend berbasis Supabase / PostgreSQL:

- [ ] **RLS Wajib Aktif pada Semua Tabel Publik:**
  ```sql
  -- Pastikan RLS diaktifkan untuk setiap tabel
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
  ```
- [ ] **Kebijakan Akses Berbasis Autentikasi:**
  ```sql
  -- Contoh: Pengguna hanya boleh membaca & mengubah datanya sendiri
  CREATE POLICY "Users can only access their own profile"
  ON public.profiles
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
  ```
- [ ] **Proteksi `service_role_key`:**
  - `service_role_key` hanya boleh digunakan di server terisolasi (Next.js Server Actions / Edge Functions).
  - Dilarang mengimpor client Supabase dengan service role di kode yang dikompilasi ke browser atau mobile app.
- [ ] **Secure Schema Function Search Path:**
  - Tambahkan `SECURITY DEFINER SET search_path = ''` pada database functions untuk mencegah search path hijacking.

---

## 4. Gate 3: Firebase Security Rules & App Check Gate

Pemeriksaan wajib untuk aplikasi berbasis Firebase (Firestore & Cloud Storage):

- [ ] **Larangan Rule Terbuka (Open Rules):**
  ```javascript
  // ❌ DILARANG KERAS DI PRODUKSI:
  match /{document=**} { allow read, write: if true; }

  // ✅ WAJIB: Validasi token autentikasi dan kepemilikan dokumen
  match /users/{userId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  match /posts/{postId} {
    allow read: if true;
    allow create: if request.auth != null && request.resource.data.authorId == request.auth.uid;
    allow update, delete: if request.auth != null && resource.data.authorId == request.auth.uid;
  }
  ```
- [ ] **Validasi Skema & Ukuran Data di Security Rules:**
  - Periksa tipe data (`request.resource.data.title is string`) dan batasi panjang karakter (`request.resource.data.title.size() < 100`).
- [ ] **Firebase App Check:**
  - Aktifkan App Check untuk API kritis menggunakan Play Integrity (Android), DeviceCheck / App Attest (iOS), dan reCAPTCHA Enterprise (Web).

---

## 5. Gate 4: OWASP Top 10 Web & API Security Checklist

- [ ] **Security Headers:**
  - `Content-Security-Policy`: Batasi domain script dan style eksternal.
  - `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
- [ ] **Rate Limiting & Auth Hardening:**
  - Batasi percobaan login gagal (maksimal 5 percobaan per IP/akun sebelum cooldown).
  - Cookie sesi menggunakan flag `HttpOnly`, `Secure`, dan `SameSite=Lax/Strict`.
- [ ] **SSRF & Input Escaping:**
  - Validasi URL input dari pengguna terhadap IP lokal (`127.0.0.1`, `169.254.169.254`, subnet privat).
  - Sanitasi rendering teks untuk mencegah Stored & Reflected XSS.

---

## 6. Gate 5: OWASP MASVS Mobile & iOS Security Checklist

- [ ] **Secure Storage (Keychain / Keystore):**
  - iOS: Simpan kredensial di Apple Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
  - Android: Gunakan `EncryptedSharedPreferences` atau Android Keystore via `flutter_secure_storage`.
  - Nonaktifkan backup file sensitif (`android:allowBackup="false"`).
- [ ] **Network Security Configuration:**
  - Nonaktifkan cleartext traffic:
    - Android: `android:usesCleartextTraffic="false"` di `AndroidManifest.xml`.
    - iOS: `NSAllowsArbitraryLoads = false` di `Info.plist`.
- [ ] **Privacy Manifest (`PrivacyInfo.xcprivacy`):**
  - Wajib menyertakan deklarasi alasan penggunaan API sensitif Apple (iOS 17+).
- [ ] **Code Obfuscation:**
  - Android release build mengaktifkan R8/ProGuard (`minifyEnabled true`, `shrinkResources true`).
- [ ] **Deep Link / Universal Link Validation:**
  - Validasi domain dan sanitasi parameter deep link sebelum mengeksekusi navigasi atau pemrosesan data.

---

## 7. Pre-Deploy Sign-Off Checklist (GO / NO-GO)

Sebelum mengumumkan rilis produksi siap:

- [ ] **Scan Rahasia:** Lulus (0 secret leaks terdeteksi).
- [ ] **Audit Dependensi:** 0 Critical, 0 High vulnerability.
- [ ] **Database Rules:** RLS / Firestore rules telah diuji dengan emulator test suite.
- [ ] **Transport:** 100% endpoint menggunakan HTTPS/TLS.
- [ ] **Verdict:** **PASS (GO)** $\rightarrow$ Lanjutkan ke tahap `ci-cd-release-ready`.
