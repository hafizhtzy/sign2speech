---
name: artemis
description: Use when authoring, running, or diagnosing Android UI automation and end-to-end tests on physical devices or emulators, controlling Android apps via natural language, extracting Logcat traces and screenshots, or inspecting mobile app behavior with the Google Artemis framework.
---

# Google Artemis: Autonomous Android Agent & Testing Framework

Artemis adalah framework otomatisasi dan pengujian Android berbasis AI dari Google yang menerjemahkan instruksi bahasa alami menjadi aksi nyata pada perangkat Android fisik maupun emulator (via ADB). 

Skill ini memungkinkan agen AI (seperti Antigravity) untuk mengamati layar (*observe*), berinteraksi dengan widget (*act*), memverifikasi alur bisnis (*verify*), mengumpulkan logcat/screenshot, dan mendiagnosis kendala perangkat secara mandiri.

---

## 1. Arsitektur & Mode Eksekusi

Artemis mendukung dua model eksekusi:

### A. ARTEMIS Flash (Cepat / Reaktif)
- **Karakteristik:** Loop cepat *Observe-Think-Act* (sekitar 3–5 detik per langkah) tanpa overhead multi-node orchestration.
- **Kapan Digunakan:** Tugas UI langsung yang sekuensial, deterministik, dan ringan (misalnya navigasi menu, klik tombol, pengujian input form, alur cepat).

### B. ARTEMIS Pro (Komprehensif / Closed-Loop Graph)
- **Karakteristik:** Memiliki **Planner** (memecah tugas menjadi rencana bertahap), **Operator** (mengeksekusi aksi dengan fallback koordinat), **Checker** (memverifikasi checkpoint dan exit review), serta penanganan insiden otomatis.
- **Kapan Digunakan:** Pengujian alur kompleks multi-layar, monitoring berkelanjutan, validasi data lintas aplikasi, investigasi log sistem mendalam, atau tugas yang membutuhkan laporan pengujian terstruktur.

---

## 2. Model Context Protocol (MCP) Tools

Ketika server Artemis MCP aktif di Antigravity, alat-alat berikut tersedia secara otomatis:

1. **`mobile_run_task`:** Menjalankan tugas otomasi mobile di latar belakang.
   - Parameter: `goal` (instruksi tugas), `model_type` (`"flash"` atau `"pro"`), `device_serial` (opsional), `verification_level` (`"off"`, `"final"`, `"checkpoints"`, `"strict"`).
2. **`mobile_manage_task`:** Mengelola status dan siklus tugas.
   - Parameter: `action` (`"status"`, `"stop"`, `"inject_instruction"`), `trace_id`.
3. **`mobile_get_device_state`:** Mengambil screenshot langsung atau hierarki elemen UI (XML/OCR).
4. **`mobile_inspect_trace`:** Memeriksa detail riwayat langkah eksekusi, screenshot, dan penalaran AI.
5. **`mobile_diagnose`:** Dokter diagnosa mandiri lingkungan Android & MCP server.
   - Parameter: `attempt_fix=True` (memperbaiki kunci RSA ADB yang rusak, merestart ADB server yang macet, atau membersihkan lock perangkat yang ditinggalkan proses crash).

---

## 3. Alur Kerja Standar: Menjalankan Pengujian Mobile

### Langkah 1: Periksa Perangkat Android yang Terhubung
Gunakan perintah shell ADB untuk memastikan perangkat/emulator siap:
```powershell
adb devices -l
```
*Jika lebih dari satu perangkat terhubung, tanyakan kepada pengguna perangkat mana (`device_serial`) yang ingin digunakan.*

### Langkah 2: Diagnosis Mandiri Jika Ada Kendala
Jika alat Artemis error atau perangkat tidak terdeteksi, panggil `mobile_diagnose`:
```json
{
  "attempt_fix": true,
  "probe_device": true
}
```

### Langkah 3: Eksekusi Tugas Otomasi
Luncurkan pengujian menggunakan `mobile_run_task`:
```json
{
  "goal": "Buka aplikasi Sign2Speech, buka menu Kasir Kafe, pilih menu Kopi Susu Oat Milk, dan verifikasi total harga tampil di keranjang.",
  "model_type": "flash"
}
```

### Langkah 4: Terapkan Pola "Dynamic-First, Coordinate-Fallback"
Saat menulis skrip pengujian otomatis (seperti Flutter integration test atau UI automator):
1. **Dinamis Terlebih Dahulu:** Utamakan selektor berbasis Resource ID, Key widget, semantik teks, atau OCR agar tahan terhadap perubahan resolusi layar.
2. **Fallback Koordinat:** Sediakan koordinat layar sebagai pengaman (*fallback*) jika elemen kustom tidak memiliki ID unik.

---

## 4. Setup & Instalasi MCP Server

Jika Artemis belum terkonfigurasi di IDE Antigravity:

1. **Clone & Setup Environment:**
   ```bash
   git clone https://github.com/google/artemis.git
   cd artemis
   uv venv
   uv sync
   ```
2. **Instalasi Otomatis ke Antigravity:**
   ```bash
   uv run artemis mcp --install antigravity
   ```
   *Perintah ini secara otomatis mendaftarkan MCP server ke konfigurasi Antigravity dan mengaktifkan notifikasi balik (reactive wakeup) ke chat.*
3. **Cek Kesehatan:**
   ```bash
   uv run artemis doctor
   ```

---

## 5. Referensi Tambahan
- Panduan Mindset Pengujian: [`references/rules.md`](file:///references/rules.md)
- Konfigurasi Multi-Platform MCP: [`references/mcp-setup.md`](file:///references/mcp-setup.md)
