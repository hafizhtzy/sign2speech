---
name: ci-cd-release-ready
description: Production release automation and CI/CD workflow guide. Covers GitHub Actions/GitLab CI pipeline generation, environment variable management, versioning and changelog verification, App Store and Play Store submission readiness, Web hosting deployment, and Sentry observability setup. Use when setting up automated release pipelines or preparing applications for production cutover.
---

# CI/CD Release Readiness Guide (Workflows, Store Readiness, & Sentry)

Panduan operasional automasi rilis produksi dan penyiapan pipeline CI/CD untuk aplikasi Web, Backend, dan Mobile (Flutter / iOS / Android / Expo). Memastikan seluruh tahapan mulai dari validasi kode, versioning, deployment, hingga monitoring kesalahan berjalan secara konsisten, aman, dan dapat dipulihkan (*rollback-ready*).

---

## 1. Blueprint Workflow GitHub Actions Produksi

Gunakan konfigurasi pipeline yang mengadopsi prinsip pengerasan keamanan (*pipeline hardening*):

```yaml
# .github/workflows/release-pipeline.yml
name: Release Production Pipeline

on:
  push:
    tags:
      - 'v*.*.*'

# 1. Terapkan prinsip Least Privilege pada GITHUB_TOKEN
permissions:
  contents: read
  packages: write
  id-token: write

jobs:
  validate-and-gate:
    name: 1. Quality & Security Gate
    runs-on: ubuntu-latest
    steps:
      # Pin Action ke commit SHA atau versi terverifikasi
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Runtime
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Secret Scan (Gitleaks)
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Run Linter & Tests
        run: |
          npm run lint
          npm test -- --coverage

  build-and-deploy:
    name: 2. Build & Production Deploy
    needs: validate-and-gate
    runs-on: ubuntu-latest
    environment:
      name: production
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Build Production Assets
        env:
          NODE_ENV: production
          NEXT_PUBLIC_API_URL: ${{ secrets.PROD_API_URL }}
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
        run: npm run build

      - name: Upload Sourcemaps to Sentry
        run: |
          npx @sentry/cli releases new "${{ github.ref_name }}"
          npx @sentry/cli releases set-commits "${{ github.ref_name }}" --auto
          npx @sentry/cli releases finalize "${{ github.ref_name }}"
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
          SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
```

---

## 2. Manajemen Environment Variables & Secrets

Aturan wajib penanganan variabel lingkungan produksi:

1. **Pemisahan Environment Stric:**
   - Pisahkan secrets untuk `development`, `staging`, dan `production` menggunakan GitHub Environments.
   - Jangan gunakan kredensial database produksi di lingkungan staging/pengujian lokal.
2. **Larangan Hardcoding:**
   - Dilarang menyematkan token autentikasi atau private keys ke dalam file konfigurasi Git.
   - File `.env` lokal wajib diblokir oleh `.gitignore`.
3. **Validasi Skema Environment Saat Runtime:**
   - Gunakan schema validator (misal `t3-oss/env-nextjs` atau `zod`) untuk memvalidasi ketersediaan variabel lingkungan saat build.

---

## 3. Versioning, Tagging, & Changelog Verification

Sebelum melakukan rilis produksi, pastikan konsistensi versi metadata:

- [ ] **Semantic Versioning (SemVer):** Format `vMAJOR.MINOR.PATCH` (misal: `v1.2.0`).
- [ ] **Sinkronisasi File Versi Proyek:**
  - **Web / Node.js:** Periksa `"version"` di `package.json`.
  - **Flutter:** Periksa `version: 1.2.0+42` di `pubspec.yaml` (angka setelah tanda `+` adalah build number).
  - **iOS Native:** Periksa `MARKETING_VERSION` dan `CURRENT_PROJECT_VERSION` di Xcode project.
  - **Android Native:** Periksa `versionName` dan `versionCode` di `build.gradle`.
- [ ] **Pembaruan `CHANGELOG.md`:**
  - Dokumentasikan ringkasan fitur baru (`Added`), perbaikan bug (`Fixed`), dan keamanan (`Security`).
  - Sediakan commit hash tautan rilis.

---

## 4. Kesiapan Rilis Berdasarkan Platform Target

### A. Target Web Hosting (Cloudflare Pages, Vercel, Docker)
- [ ] Build produksi menggunakan konfigurasi minified bundle dan tree shaking aktif.
- [ ] Route caching dan CDN cache-invalidation dikonfigurasi dengan benar.
- [ ] Uji Health Check endpoint publik (`curl -f https://app.example.com/api/health`).

### B. Target iOS (TestFlight & App Store Submission)
- [ ] Icon aplikasi tersedia lengkap tanpa transparansi (PNG 1024x1024).
- [ ] File `PrivacyInfo.xcprivacy` terpasang dengan alasan API deklaratif yang sah.
- [ ] String deskripsi izin di `Info.plist` menjelaskan kegunaan nyata bagi pengguna.
- [ ] Akun demo aktif disiapkan untuk tim peninjau Apple App Store Connect.
- [ ] Pengiriman otomatis via Fastlane (`bundle exec fastlane beta`) atau EAS Submit.

### C. Target Android (Google Play Console)
- [ ] Format build menggunakan Android App Bundle (`.aab`), bukan APK mentah.
- [ ] Keystore penandatanganan rilis (`upload-keystore.jks`) tersimpan aman via CI secrets (Base64 encoded).
- [ ] Target SDK level memenuhi persyaratan minimal Google Play (API Level 34+).

---

## 5. Konfigurasi Monitoring & Observability Sentry

Langkah mengaktifkan penjejakan error produksi:

1. **Inisialisasi Sentry SDK:**
   ```typescript
   import * as Sentry from "@sentry/nextjs";

   Sentry.init({
     dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
     environment: process.env.NODE_ENV,
     release: process.env.NEXT_PUBLIC_APP_VERSION,
     tracesSampleRate: 0.1, // Sample 10% transaksi untuk efisiensi kuota
   });
   ```
2. **Upload Sourcemaps / dSYM:**
   - Web: Unggah sourcemaps saat proses CI build agar stack trace menampilkan file asli TypeScript, bukan minified code.
   - Flutter / iOS: Unggah file dSYM dan ProGuard mapping file agar crash report symbolicated.
3. **Pemeriksaan Pasca-Deploy:**
   - Buka dashboard Sentry dan amati selama 15-30 menit setelah rilis live.
   - Target Crash-Free Sessions: $\ge 99.5\%$.

---

## 6. Protokol Rollback Rilis

Rencana pemulihan instan jika terjadi kegagalan sistem di produksi:

| Platform | Metode Rollback | Durasi Target |
|---|---|---|
| **Web (Cloudflare / Vercel)** | Instant Deployment Revert ke deployment hash sebelumnya | $< 2\text{ menit}$ |
| **Backend / Docker** | Repoint image tag ke tag stabil sebelumnya (`v1.1.9`) | $< 5\text{ menit}$ |
| **Mobile App (iOS/Android)** | Nonaktifkan fitur via Remote Config / Feature Flags | $< 1\text{ menit}$ |
| **Database** | Eksekusi rollback script sesuai prinsip *Expand-Contract* | Terjadwal |
