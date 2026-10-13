# Integrasi Agency Agents & Agentic Awesome Skills — Sign2Speech

Aturan proyek untuk pemanggilan peran spesialis **The Agency Agents** dan **Agentic Awesome Skills** dalam pengembangan aplikasi Sign2Speech.

---

## 1. Prinsip Presedensi & Integritas Proyek (Wajib)

1. **Aturan Proyek Mengesampingkan Persona Pihak Ketiga**:
   - Jika ada arahan umum dari Agency Agents atau AAS yang merekomendasikan migrasi framework/state management (misal memaksakan BLoC, Riverpod, atau React Native), **Dilarang Keras Diikuti**. Proyek ini secara mutlak menggunakan **Flutter + GetX**.
   - Jika persona menyarankan styling CSS/Tailwind/Material 3 generik, **DESIGN.md** tetap menjadi satu-satunya acuan visual (Nordic Ocean Playful Editorial: `#1B3B4B`, `#38687D`, `#F9F9F7`, Plus Jakarta Sans, dan komponen aset `assets/komponen_img/`).
   - Peran audio Voice AI **dilarang** mengganti teknologi ke Whisper atau cloud ASR tanpa instruksi pengguna; gunakan `speech_to_text` (id-ID) dan `flutter_tts` serial FIFO.
   - Kontrak MotionGRU berasal langsung dari model, metadata, labels, dan kode training asli; jangan membuat asumsi fiktif atau klaim akurasi/FPS tanpa pengujian riil.

---

## 2. Matriks Pemanggilan Persona & Skill (Progressive Disclosure)

Muat persona atau skill secara spesifik berdasarkan fase tugas, bukan sekaligus:

| Kategori Tugas | Agency Agent (Persona) | Agentic Awesome Skill (Prosedur) | Panduan Penggunaan Khusus Sign2Speech |
| :--- | :--- | :--- | :--- |
| **Arsitektur & Domain** | `agency-software-architect` | `flutter-apply-architecture-best-practices` | Mengawal isolasi 3-lapisan (Presentation, Domain, Data). Menjamin Domain Layer tidak bergantung pada GetX/UI, dan Controller tidak menyimpan BuildContext. |
| **Mobile & Flutter Development** | `agency-mobile-app-builder` | `flutter-expert`, `mobile-developer`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues` | Implementasi widget reaktif GetX, routing `AppPages`, adaptasi layout responsif artboard 393x852, touch target >= 48 dp, dan bridging CameraX EventChannel. |
| **Voice AI & Speech Pipeline** | `agency-voice-ai-integration-engineer` | `voice-ai-engine-development`, `voice-ai-development` | Mengelola STT Bahasa Indonesia, lifecycle listener `_generation`, buffer ejaan alfabet 1500ms, dan antrean serial FIFO TTS (`_speechChain`) bebas audio clashing. |
| **Desain UI/UX & Layout** | `agency-ui-designer`, `agency-ux-architect` | `ui-ux-pro-max`, `design-system` | Menerapkan palet Nordic Ocean, hierarki Plus Jakarta Sans, pemetaan `AppAssets` dari `assets/komponen_img/`, dan komposisi 13 layar yang disetujui. |
| **Aksesibilitas & Universal UX** | `agency-accessibility-auditor` | `screen-reader-testing`, `accessibility-compliance-accessibility-audit` | Menguji kontras teks WCAG AA/AAA, tactile feedback, dan kompatibilitas pembaca layar (TalkBack / VoiceOver). |
| **Code Review & Mutu Kode** | `agency-code-reviewer` | `code-review-checklist`, `code-review-excellence`, `requesting-code-review` | Meninjau keselamatan thread, pelepasan resource (`onClose()`), race condition guard (`_playSessionId`), dan pencegahan leak memori. |
| **Pengujian Otomatis (QA)** | `agency-test-automation-engineer` | `flutter-add-widget-test`, `flutter-add-integration-test`, `test-driven-development` | Mengembangkan automated unit, widget, dan integration test menggunakan mock fixtures tanpa ketergantungan perangkat fisik. |
| **Performa & Profiling Kinerja** | `agency-performance-benchmarker` | `performance-profiling`, `diagnose-android-overheating` | Mengawal offloading komputasi tensor 353-D/706-D ke background Isolate (`Isolate.run`), throttling CameraX, dan menjaga kelancaran preview camera >= 30-60 FPS. |
