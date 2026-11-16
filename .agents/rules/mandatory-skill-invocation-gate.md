# Gerbang Wajib Sebelum Ngoding, Mengubah, Menambah Fitur, atau Audit Kode (Mandatory Pre-Action Skill & Rule Gate)

Dokumen ini menetapkan **Aturan Mutlak Tingkat Tertinggi (Hard Gate)** bagi seluruh agen AI dan subagen yang bekerja di proyek **Sign2Speech (`speech2sign`)**.

---

## 1. Hukum Utama: DILARANG NGODING SEBELUM MEMBACA SKILL & RULES

> **ATURAN KERAS (ZERO-TOLERANCE GATE):**
> Agen AI **DILARANG KERAS** menulis kode baru (`write_file`), mengedit kode (`edit_file`), merombak arsitektur, memperbaiki bug, menambahkan fitur, atau melakukan audit kode **SEBELUM** terlebih dahulu:
> 1. **Mengidentifikasi domain fitur/tugas** yang diminta pengguna.
> 2. **Membaca (`read_file`) berkas `SKILL.md` yang relevan** dari daftar `.agents/skills/` atau global skills.
> 3. **Membaca (`read_file`) berkas aturan (`.agents/rules/*.md`)** yang mengatur domain tersebut.
> 4. **Menerapkan checklist dan batasan dari skill & rules tersebut** secara ketat selama pengerjaan.

Jika agen belum menemukan skill yang pas di daftar yang dimuat, agen wajib memanggil `skill-advisor` atau memeriksa direktori `.agents/skills/` terlebih dahulu. **Tidak boleh ada satu baris kode pun yang diubah berdasarkan tebakan atau asumsi tanpa pedoman skill dan rules.**

---

## 2. Alur Kerja Wajib 4-Tahap (Mandatory 4-Step Pre-Coding Workflow)

Setiap kali menerima instruksi untuk membuat, mengubah, memperbarui, memperbaiki, atau mengaudit kode, agen **WAJIB** menjalankan urutan ini:

### Tahap 1 — Klasifikasi Domain Tugas
Tentukan domain apa saja yang tersentuh oleh permintaan pengguna (bisa lebih dari satu, misalnya: *UI + Supabase*, atau *Debugging + Kamera BISINDO*).

### Tahap 2 — Panggil & Baca Skill + Rules (`read_file`)
Gunakan tool `read_file` untuk membuka `SKILL.md` dan file aturan `.agents/rules/*.md` sesuai matriks di Bagian 3 di bawah ini.
- **Contoh Kasus Supabase:** Jika ingin mengubah service database, query tabel, storage foto kopi/video isyarat, atau migrasi SQL, agen **WAJIB** membaca [.agents/skills/supabase-postgres-best-practices/SKILL.md](file:///c:/fadli/project/sign2speech/.agents/skills/supabase-postgres-best-practices/SKILL.md) dan [.agents/rules/supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md) **sebelum** menyentuh file `.dart` atau `.sql`.
- **Contoh Kasus UI / Layar / Widget:** Jika ingin membuat atau mengubah tampilan layar, warna, font, kartu, atau tombol, agen **WAJIB** membaca [.agents/rules/ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md) serta skill `flutter-build-responsive-layout` / `ui-ux-pro-max` **sebelum** mengedit widget.
- **Contoh Kasus Bug / Error:** Jika pengguna melaporkan bug, layar putih, atau perilaku tidak sesuai, agen **WAJIB** membaca `.agents/skills/systematic-debugging/SKILL.md` terlebih dahulu.

### Tahap 3 — Eksekusi Sesuai Kontrak Arsitektur & Proyek
Lakukan perubahan kode dengan mematuhi prinsip-prinsip yang telah dikunci di proyek:
- State Management tetap **Flutter + GetX** (`GetxController`, `Bindings`, `Obx`).
- Clean Architecture 3-Lapisan (Presentation, Domain, Data).
- Multi-bahasa dinamis via `AppStrings` & `AppTranslations` (`.tr`).
- Desain warna `AppColors` (Cafe Warm Oat Milk / Espresso & Instagram AMOLED Dark Mode) dan tipografi `AppTypography` (Plus Jakarta Sans).
- Responsif di seluruh ukuran layar (Compact, Medium, Expanded) dan touch target $\ge 48\times 48\text{ dp}$.

### Tahap 4 — Verifikasi Wajib Sebelum Klaim Selesai
Sebelum menyatakan pekerjaan selesai, baca dan jalankan prosedur `verification-before-completion` (`flutter analyze` = 0 issues, `flutter test` = 100% lulus).

---

## 3. Matriks Pemetaan Tugas $\rightarrow$ Skill Wajib & Rules Wajib

Gunakan tabel referensi ini setiap kali akan memulai tugas:

| No | Domain / Fitur yang Dikerjakan | Skill Wajib Dibaca (`read_file` ke `SKILL.md`) | File Rules Wajib Dibaca (`.agents/rules/`) |
| :- | :--- | :--- | :--- |
| **1** | **Supabase, PostgreSQL, RLS, Realtime, Storage Bucket (`menu-photos` / `sign-videos`)** | `supabase-postgres-best-practices`, `flutter-apply-architecture-best-practices`, `security-predeploy-gate` | [supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md), [SUPABASE_ARCHITECTURE.md](file:///c:/fadli/project/sign2speech/SUPABASE_ARCHITECTURE.md) |
| **2** | **UI/UX, Halaman Baru, Komponen Widget, Tema Warna, Dark Mode, Lokalisasi** | `ui-ux-pro-max`, `design-system`, `ui-states`, `agency-ui-designer`, `agency-ux-architect` | [ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md), [DESIGN.md](file:///c:/fadli/project/sign2speech/DESIGN.md) |
| **3** | **Layout Responsif Multi-Device (HP, Tablet, Foldable) & Perbaikan Overflow** | `flutter-build-responsive-layout`, `flutter-responsive`, `flutter-fix-layout-issues` | [ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md) |
| **4** | **Arsitektur Fitur Baru, GetX Controller, Bindings, Clean Architecture** | `flutter-apply-architecture-best-practices`, `flutter-expert`, `agency-software-architect` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **5** | **Debugging Bug, Layar Error/Putih, Race Condition, Crash Runtime** | `systematic-debugging`, `dart-fix-runtime-errors`, `flutter-performance-debug` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **6** | **Kamera Native Android CameraX, MediaPipe Holistic, TFLite & Performa** | `android-dev`, `kotlin-coroutines-expert`, `performance-profiling`, `diagnose-android-overheating` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **7** | **Voice AI, Speech-to-Text (STT `id-ID`), Text-to-Speech (FIFO TTS)** | `agency-voice-ai-integration-engineer`, `voice-ai-engine-development` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **8** | **Unit Test, Widget Test, Integration Test, Mock & TDD** | `test-driven-development`, `flutter-add-widget-test`, `dart-add-unit-test`, `verification-before-completion` | [supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md) |
| **9** | **Audit Kode, Audit Keamanan, Audit Aksesibilitas WCAG** | `agency-code-reviewer`, `code-review-checklist`, `security-predeploy-gate`, `cloudflare-security-audit`, `accessibility-compliance-accessibility-audit` | [ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md), [supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md) |
| **10** | **Perencanaan Fitur Baru / Brainstorming / Copywriting UI** | `brainstorming`, `writing-plans`, `humanizer`, `skill-advisor` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |

---

## 4. Daftar Tanda Bahaya (Red Flags — Wajib Berhenti!)

Jika agen berpikir seperti di bawah ini, agen **WAJIB BERHENTI** dan membaca skill terlebih dahulu:
- ❌ *"Perubahan ini cuma kecil, langsung edit saja tanpa baca skill."* ➔ **SALAH.** Perubahan kecil tanpa membaca aturan sering merusak kontrak arsitektur atau RLS.
- ❌ *"Saya sudah hafal isi skill Supabase / UI rules dari percakapan sebelumnya."* ➔ **SALAH.** Konteks bisa terpotong; wajib verifikasi dan patuhi daftar periksa terbaru.
- ❌ *"Saya koding dulu, nanti baru cek rules."* ➔ **SALAH.** Baca skill dan rules di awal agar desain kode langsung benar sejak baris pertama.
