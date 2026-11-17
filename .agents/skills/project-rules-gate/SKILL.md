---
name: project-rules-gate
description: Use when initializing a new project, setting up or auditing project governance rules (.agents/rules/project-master-rules.md), or enforcing the Mandatory Pre-Action Skill Gate, Engineering Harness (reuse /common, dependency lock, 500-LOC confirmation gate), Design System Contract, and Mentor Mode explanations.
---

# Project Rules Gate (Konstitusi Wajib, Engineering Harness, Design System & Mentor Mode)

`project-rules-gate` adalah skill penjaga gerbang utama (*Hard Gate & Governance Bootstrapper*) untuk memastikan setiap proyek di ekosistem pengguna memiliki `.agents/rules/project-master-rules.md` yang aktif dan dipatuhi tanpa kompromi oleh seluruh agen AI.

---

## 1. Sumber Master Rules & Codebase Registry di Brain
- **File Template Master Rules:** `C:\fadli\Antigravity-Skill-Brain\Agent-Rules\project-master-rules.md`
- **File Template Codebase Registry:** `C:\fadli\Antigravity-Skill-Brain\Agent-Rules\CODEBASE-REGISTRY-TEMPLATE.md`
- **Target Lokasi di Proyek Aktif:**
  - `.agents\rules\project-master-rules.md`
  - `.agents\CODEBASE-REGISTRY.md`

---

## 2. SOP Pemasangan ke Proyek Baru / Existing (Bootstrap Workflow)

Setiap kali skill ini dipanggil untuk menyiapkan aturan di proyek baru atau proyek yang belum memiliki rules:

1. **Salin File Master Rules & Codebase Registry ke Proyek Aktif:**
   ```powershell
   New-Item -ItemType Directory -Force -Path ".agents\rules"
   Copy-Item -Path "C:\fadli\Antigravity-Skill-Brain\Agent-Rules\project-master-rules.md" -Destination ".agents\rules\project-master-rules.md" -Force
   if (-not (Test-Path ".agents\CODEBASE-REGISTRY.md")) {
       Copy-Item -Path "C:\fadli\Antigravity-Skill-Brain\Agent-Rules\CODEBASE-REGISTRY-TEMPLATE.md" -Destination ".agents\CODEBASE-REGISTRY.md" -Force
   }
   ```
2. **Inisiasi Isi `.agents/CODEBASE-REGISTRY.md` (Jika Proyek Sudah Punya Kode):**
   - Jika proyek sudah memiliki isi di dalam `/core`, `/common`, atau `Services`, catat daftarnya ke dalam 4 tabel di `.agents/CODEBASE-REGISTRY.md` dengan format padat **1 baris per item** (`Nama | Lokasi File | Signature | Kegunaan 1 Kalimat`).
3. **Sesuaikan Spesifikasi Tech Stack Proyek (Opsional tapi Direkomendasikan):**
   - Periksa manifest proyek (`pubspec.yaml`, `package.json`, dll.) dan struktur folder (`/core`, `/common`, `/shared`).
   - Jika proyek sudah memiliki state management atau palet warna di `DESIGN.md`, tambahkan catatan spesifik proyek tersebut ke dalam `.agents/rules/project-master-rules.md` tanpa menghapus ke-4 pilar utama.
4. **Pastikan Kontrak `DESIGN.md` Tersedia:**
   - Jika proyek memiliki antarmuka (UI) namun belum memiliki `DESIGN.md` (atau `docs/DESIGN.md`), gunakan skill `design-md` dan `ui-ux-pro-max` untuk menginisiasinya.

---

## 3. Keempat Pilar Wajib yang Ditegakkan Skill Ini

### Pilar 1 — Gerbang Wajib Sebelum Ngoding (Mandatory Pre-Action Skill Gate)
- **DILARANG KERAS** menulis (`write_file`), mengedit (`edit_file`), merombak, atau mengaudit kode sebelum:
  1. Mengidentifikasi domain tugas.
  2. Membaca (`read_file`) `SKILL.md` yang relevan dengan domain tugas tersebut.
  3. Membaca `.agents/rules/project-master-rules.md` dan **`.agents/CODEBASE-REGISTRY.md`**.

### Pilar 2 — Batasan Rekayasa, Write-Through Registry & Anti-Overengineering (Engineering Harness)
- **Dependency Lock:** Wajib gunakan library yang sudah ada di repo (`pubspec.yaml` / `package.json`). Dilarang menambah package baru tanpa izin eksplisit pengguna.
- **Arsitektur `/core` vs `/common` & Write-Through `.agents/CODEBASE-REGISTRY.md`:**
  - `/core` khusus mesin & pondasi aplikasi (*Theme, Network/API client, Error/Result wrapper, Routing, Localization*).
  - `/common` khusus komponen & alat pakai ulang lintas fitur (`/common/widgets`, `/common/utils`, `/common/services`).
  - **Baca Registry Dulu (Hemat Token):** Wajib membaca `.agents/CODEBASE-REGISTRY.md` sebelum membuat fungsi/service/widget baru agar tidak perlu scan/baca puluhan file di `/core` atau `/common`.
  - **Wajib Catat (Write-Through Sync):** Setiap kali menambah, mengubah signature, atau menghapus item di `/core`, `/common`, atau `Services/Repositories`, agen **WAJIB langsung memperbarui tabel 1-baris di `.agents/CODEBASE-REGISTRY.md` pada giliran yang sama**.
- **Zero Over-Engineering & Zero Hallucination:** Jangan membuat abstraksi/wrapper baru jika pola yang ada sudah mencukupi. Jangan mengarang API/method fiktif.
- **Gerbang Konfirmasi 500 Baris (500-LOC Confirmation Gate):**
  - Jika sebuah file sudah mencapai atau akan melewati **$\pm 500$ baris kode (LOC)**, agen **WAJIB berhenti dan bertanya kepada pengguna terlebih dahulu**:
    > *"File `[nama_file]` saat ini sudah/akan lebih dari 500 baris karena logic / page ini panjang. Apakah tidak apa-apa saya tambah lebih dari 500 baris di file ini, atau Anda ingin saya pecah menjadi sub-komponen/file terpisah?"*

### Pilar 3 — Kontrak Design System Universal
- **Single Source of Truth:** Seluruh warna dan tipografi wajib memanggil token dari `DESIGN.md` & file tema tunggal (`AppColors`/`AppTypography` atau CSS Variables/Tailwind tokens). **Dilarang keras menulis raw hex color atau raw TextStyle langsung di widget/komponen.**
- **Responsif Multi-Device & Anti-Overflow:** Wajib tampil proporsional di Mobile (Compact), Tablet/Foldable (Medium), dan Desktop (Expanded) dengan perlindungan terhadap *RenderFlex overflow*.
- **6 UI States:** Wajib menangani state *Loading, Empty, Error (+ Retry), Success, Offline,* dan *Long Content*.
- **Anti-AI-Slop:** Bebas dari estetika gradien ungu klise AI dan teks robotik.

### Pilar 4 — Mode Mentor Bahasa Awam ("🎓 Pojok Mentor")
- Di akhir **setiap** respons pembuatan/perubahan kode atau keputusan arsitektur, agen **WAJIB** menampilkan blok **`### 🎓 Pojok Mentor: Kenapa Solusi Ini Dipilih?`** yang berisi:
  1. **Analogi Sederhana (Bahasa Awam):** Analogi sehari-hari agar konsepnya langsung terbayang.
  2. **Bagaimana Kode Ini Bekerja (Step-by-Step):** Urutan aliran data/logika dari input hingga output.
  3. **Kenapa Pakai Cara Ini? (Alasan & Trade-off):** Alasan memilih solusi ini dibanding alternatif lain (performa, keamanan, reuse `/common`, dan kesederhanaan).
