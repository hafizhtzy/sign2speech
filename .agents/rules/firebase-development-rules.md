# Aturan Pengembangan Firebase & Firestore (Best Practice & Security Gate)

Dokumen ini adalah aturan resmi tingkat proyek (*Project Rule*) untuk pengembangan, modifikasi, integrasi, dan audit backend **Firebase** dalam aplikasi **Sign2Speech**.

Setiap kali agen AI atau pengembang berinteraksi dengan konfigurasi Firebase, database Cloud Firestore, autentikasi, Crashlytics, atau Security Rules, **WAJIB mematuhi seluruh protokol berikut**.

---

## 1. Pemanggilan Skill Wajib Berdasarkan Domain Tugas

Agen dilarang memodifikasi Firebase berdasarkan asumsi. Agen **WAJIB membaca dan menerapkan skill resmi** yang telah terpasang di `.agents/skills/` sesuai domain tugas:

| Domain Tugas | Skill Wajib | Path Skill | Trigger & Tanggung Jawab |
| :--- | :--- | :--- | :--- |
| **CLI, Setup, & Config** | `firebase-basics` | [.agents/skills/firebase-basics](file:///c:/fadli/project/sign2speech/.agents/skills/firebase-basics/SKILL.md) | Setup CLI, `firebase use`, verifikasi `google-services.json`, sinkronisasi `firebase_options.dart`. |
| **Database & Queries** | `firebase-firestore` | [.agents/skills/firebase-firestore](file:///c:/fadli/project/sign2speech/.agents/skills/firebase-firestore/SKILL.md) | Deteksi instance edition (STANDARD/ENTERPRISE), pemodelan dokumen/koleksi, optimasi query `where()` / `orderBy()`, pagination, dan batch write. |
| **Pembuatan Security Rules** | `firestore-rules-creation` | [.agents/skills/firestore-rules-creation](file:///c:/fadli/project/sign2speech/.agents/skills/firestore-rules-creation/SKILL.md) | Merancang dan menulis `firestore.rules` standar produksi dengan validasi skema ketat. |
| **Audit Keamanan Rules** | `firebase-security-rules-auditor` | [.agents/skills/firebase-security-rules-auditor](file:///c:/fadli/project/sign2speech/.agents/skills/firebase-security-rules-auditor/SKILL.md) | Memindai celah keamanan rules, validasi otorisasi user (`request.auth.uid`), penegakan immutability, dan mitigasi DoS. |
| **Autentikasi Pengguna** | `firebase-auth-basics` | [.agents/skills/firebase-auth-basics](file:///c:/fadli/project/sign2speech/.agents/skills/firebase-auth-basics/SKILL.md) | Implementasi sign-in (Email, Google, Anonymous), manajemen session, token claims, dan integrasi Auth State ke GetX. |
| **Monitoring & Crashlytics** | `firebase-crashlytics` | [.agents/skills/firebase-crashlytics](file:///c:/fadli/project/sign2speech/.agents/skills/firebase-crashlytics/SKILL.md) | Pelaporan error tak tertangani, kustom key logging, dan instrumen breadcrumbs. |
| **Integrasi Gemini AI** | `firebase-ai-logic-basics` | [.agents/skills/firebase-ai-logic-basics](file:///c:/fadli/project/sign2speech/.agents/skills/firebase-ai-logic-basics/SKILL.md) | Client-side LLM multimodal inference & streaming via Vertex AI / Firebase AI Logic. |

---

## 2. Aturan Baku Arsitektur di Flutter (Clean Architecture + GetX)

1. **Isolasi 3-Lapisan (Presentation, Domain, Data):**
   - **Data Layer Only:** Seluruh panggilan `FirebaseFirestore`, `FirebaseAuth`, dan dependensi SDK pihak ketiga **HANYA boleh berada di Data Layer** (`lib/features/<feature>/services/` atau `lib/data/datasources/`).
   - **Dilarang di UI:** Dilarang mengimpor `cloud_firestore` atau `firebase_auth` secara langsung ke dalam Screen, Widget, atau Dialog.
   - **Komunikasi ke Controller:** View berkomunikasi hanya melalui `GetxController`, dan Controller memanggil Service/Repository.

2. **Pemodelan State Menggunakan Dart 3 `sealed class`:**
   - Setiap operasi asinkron Firestore **WAJIB** dimodelkan dengan `sealed class` (mengadopsi `kevmoo-dash-skills` & `flutter-state-navigation-pro`):
     ```dart
     sealed class FirestoreResult<T> {
       const FirestoreResult();
     }
     final class FirestoreSuccess<T> extends FirestoreResult<T> {
       final T data;
       const FirestoreSuccess(this.data);
     }
     final class FirestoreFailure<T> extends FirestoreResult<T> {
       final String errorMessage;
       final Object? error;
       const FirestoreFailure(this.errorMessage, [this.error]);
     }
     ```
   - Di Controller, gunakan **exhaustive pattern matching (`switch (result)`)** tanpa default fallback yang menutupi error.

3. **Ketahanan Lingkungan Pengujian (Defensive Test Isolation):**
   - Setiap service Firestore wajib mengimplementasikan **lazy getter** atau fallback null-safe untuk `FirebaseFirestore.instance`.
   - Hal ini menjamin bahwa **widget test** dan **unit test** tetap dapat berjalan cepat tanpa *mocking overhead* berat dan tidak melempar eksepsi `[core/no-app]`.

4. **Injeksi Dependensi via GetX:**
   - Semua service Firestore didaftarkan secara terpusat di [lib/presentation/navigation/app_binding.dart](file:///c:/fadli/project/sign2speech/lib/presentation/navigation/app_binding.dart) menggunakan `Get.put<T>(..., permanent: true)` atau `Get.lazyPut<T>(...)`.

---

## 3. Standar Keamanan Mutlak Firestore (Security Rules Zero-Trust)

1. **Larangan Aturan Terbuka Publik (*Zero Open Access*):**
   - **Dilarang Keras** menulis aturan `allow read, write: if true;` pada koleksi data pengguna atau data sensitif dalam `firestore.rules`.
   - Dokumen pengguna (`/users/{userId}`) **wajib** dilindungi dengan pemeriksaan kepemilikan:
     ```javascript
     allow read, write: if request.auth != null && request.auth.uid == userId;
     ```

2. **Validasi Skema Dokumen pada Setiap Operasi Write:**
   - Operasi `create` dan `update` harus memvalidasi tipe data yang masuk, batas panjang karakter, serta kelengkapan field wajib:
     ```javascript
     function isValidHistory(data) {
       return data.originalContent is string && data.originalContent.size() <= 1000
           && data.signLanguageType in ['BISINDO', 'SIBI']
           && data.direction is string;
     }
     ```

3. **Integritas Waktu Server (Server Timestamps):**
   - Field `createdAt` atau `timestamp` harus mewajibkan `request.time` agar data tidak dapat dimanipulasi oleh client palsu.

4. **Verifikasi Rules Sebelum Deploy:**
   - Setiap kali `firestore.rules` diubah, lakukan kompilasi dan uji deploy ke Firebase project:
     ```bash
     firebase deploy --only firestore:rules --project sign2speech-937e2
     ```
   - Pastikan rules terbebas dari peringatan dan lulus evaluasi `firebase-security-rules-auditor`.

---

## 4. Checklist Eksekusi Agen Sebelum Menyatakan Pekerjaan Selesai

Setiap agen yang membuat atau memodifikasi fitur Firebase wajib memenuhi checklist:
- [ ] Telah membaca dan mengacu pada file `SKILL.md` yang relevan di `.agents/skills/`.
- [ ] Kode implementasi berada di Data Layer dan terbebas dari coupling `BuildContext`.
- [ ] UI State ditangani dengan pola Dart 3 `sealed class` dan pattern matching.
- [ ] Inisialisasi Firebase aman terhadap pengujian headless/widget test.
- [ ] Aturan `firestore.rules` membatasi akses sesuai prinsip *least-privilege*.
- [ ] Menjalankan `flutter analyze` dan memastikan 0 warning / 0 error.
- [ ] Menjalankan pengujian otomatis (`flutter test`) dan memastikan seluruh test suite berwarna hijau.
