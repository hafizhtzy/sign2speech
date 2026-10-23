# Design System: Sign2Speech — Cafe Warm Oat Milk / Espresso Playful Editorial

**Purpose:** Single source of truth for Google Stitch and Antigravity AI to generate a consistent, accessible, Flutter-ready mobile UI for Sign2Speech.

**Status:** Visual design specification based on the approved 12-screen reference and the existing Sign2Speech `DESIGN.md`, PRD, implementation plan, and Sign-to-Speech / Speech-to-Sign logic. Synchronized directly with the authoritative Single Source of Truth in `lib/core/theme/app_colors.dart`.

## 1. Visual Theme & Atmosphere

Sign2Speech is a welcoming two-way communication bridge between Teman Tuli and Teman Dengar. The interface blends **warm human-centered editorial illustration** with **warm cafe minimalism**: friendly hand-drawn characters with rich espresso linework; open breathing room; precise typography; large comfortable controls; a soothing warm oat milk canvas; and deep espresso brown accents with warm caramel highlights.

- **Design density:** 4/10 — airy and readable, not empty or decorative for its own sake.
- **Composition variance:** 4/10 — offset illustrations and dynamic shapes in onboarding; reliable, predictable alignments in tools, camera, and settings.
- **Motion intensity:** 4/10 — subtle, purposeful, accessible. Active microphone waveforms and sign confirmation rings are functional; decorative perpetual motion is not required.
- **Emotional character:** optimistic, playful, gentle, credible, reassuring, inclusive; never childish or over-technical.
- **Reference priority:** 1) Approved 12-screen storyboard/reference image, 2) Single Source of Truth in AppColors (`lib/core/theme/app_colors.dart`), 3) original two-card role-selection reference, 4) Sign2Speech PRD/functionality, 5) this document for detailed consistency.
- **No new visual identity.** Refine and continue the approved art direction rather than inventing an unrelated app aesthetic.

### Illustration language

Draw a consistent small cast of editorial 2D human characters: a young woman with curly hair in a bun, and a young man with short hair. Render faces, hands, and clothing with **Rich Espresso (#2C1E18)** outlines, warm white fills, slightly imperfect human strokes, expressive gestures, and minimal warm oat milk mark-making on dark shirts. Favor isolated illustrated components; never flatten a whole functional screen into one picture. Hands and gestures are educational/contextual illustrations only, **not verified representations of a BISINDO/SIBI word**. Live translation and sign playback must be visibly distinct from decorative artwork.

Decorative sparkles, curved arrow doodles, speech bubbles, simple organic blobs, and sound-wave motifs are permitted sparingly. Decorative colors must stay inside the warm espresso / caramel / latte foam family. No decorative pink, purple, neon, or rainbow palette. Characters can change pose from screen to screen but not identity, rendering style, or visual weight.

## 2. Color Palette & Roles

Use **the unified Cafe Warm Oat Milk / Espresso palette** defined in `lib/core/theme/app_colors.dart`. No competing random accent hues.

| Semantic token | Dart Token (`AppColors`) | Name and Hex | Use |
| --- | --- | --- | --- |
| `primary` | `AppColors.primary` | Rich Espresso Brown `#2C1E18` | Strong primary CTA, hero cards, selected navigation, dark feature card |
| `secondary` | `AppColors.secondary` | Warm Caramel / Cinnamon `#8C5A3C` | Waveforms, confirmation ring, secondary action card, active token |
| `canvas` | `AppColors.canvas` | Warm Oat Milk / Cream `#FDFBF7` | Main app background, splash and onboarding base |
| `surface` | `AppColors.surface` | Pure Warm White `#FFFFFF` | Elevated cards, search inputs, dialogs, sheet surfaces |
| `bgSurface` / `soft` | `AppColors.bgSurface` / `paleMist` | Soft Latte Foam `#F4EFE6` | Secondary card background, category chips, subtle banners, badge surfaces |
| `border` | `AppColors.border` | Warm Sand Border `#E6DCD2` | Fine dividers, card outlines, input borders |
| `border_dashed` | `AppColors.borderDashed` | Cafe Dashed Line `#D5C7B8` | Ticket-style perforated divider lines |
| `ink` | `AppColors.ink` | Rich Espresso Brown `#2C1E18` | All primary headings, titles, and editorial character linework |
| `muted` | `AppColors.muted` | Roasted Mocha `#6E5A4F` | Body copy, secondary labels, and supporting subtitles |
| `text_muted` | `AppColors.textMuted` | Warm Taupe `#9A8679` | Placeholders, captions, and hints |
| `text_on_dark` | `AppColors.textOnDark` | Warm Oat Milk White `#FDFBF7` | Text on dark espresso cards and primary buttons |
| `matcha` | `AppColors.matcha` | Matcha Sage `#4A6B53` | Offline status indicator, success badges & positive feedback |
| `amber` | `AppColors.amber` | Amber Gold `#D97724` | Highlights, warning banners & accent badges |
| `camera_dark` | `AppColors.cameraDark` | Deep Espresso Dark `#191210` | Camera viewports and dark overlay backgrounds |

**Color allocation:** roughly 70% Warm Oat Milk (`#FDFBF7`) & Pure White (`#FFFFFF`), 20% Rich Espresso visual anchors (`#2C1E18`), 10% Warm Caramel (`#8C5A3C`), Soft Latte Foam (`#F4EFE6`), and Matcha/Amber accents. On dark espresso surfaces use `#FDFBF7` text. On pale surfaces use `#2C1E18` or `#6E5A4F` text. Never use low-contrast gray text for critical instructions.

**Semantic state colors, only for genuine system feedback:** success `#4A6B53` (Matcha Sage), warning `#D97724` (Amber Gold), error `#BA1A1A`. These are not decorative accents. Live recording status may use red only when recording or stopping.

**Camera & dark surface appearance:** camera canvas `#191210` (`AppColors.cameraDark`), elevated camera container `#231B17` (`AppColors.cameraDarkElevated`), overlays tinted `rgba(44,30,24,0.40)`. Preserve all structures and label clarity.

## 3. Typography Rules

**Font:** Plus Jakarta Sans for headings, body, UI labels, numbers, and buttons. This font is part of the approved original design system; do not replace it with Inter. Avoid generic serif and decorative display fonts. All UI copy is **Bahasa Indonesia**, except approved product names (Sign2Speech, BISINDO, SIBI, Sign to Speech, Speech to Sign).

| Style | Size / weight | Line height | Behavior |
| --- | --- | --- | --- |
| Display / hero | 32 px, 700 | 1.20 | Compact, track -0.5 px, 1–2 lines |
| Page heading | 24 px, 600–700 | 1.30 | Left aligned unless a splash-specific centered lockup |
| Card title | 18 px, 600 | 1.40 | Usually one or two lines |
| Body | 15–16 px, 400 | 1.50 | Comfortable, avoid lines > 65 characters |
| Supporting | 13–14 px, 400–500 | 1.45 | Readable muted color |
| Label | 12 px, 600 | 1.40 | Only where contextual; essential controls larger |

Favor hierarchy by weight, content, and spacing rather than huge lettering. Do not use microscopic captions to cram complex controls into small cards. No gradient-filled heading text.

## 4. Component Stylings

### Primary button

Rich Espresso `AppColors.primary` (`#2C1E18`), warm oat milk Plus Jakarta Sans semibold label (`#FDFBF7`), pill radius, minimum 48 dp height, comfortable 16–24 dp horizontal padding, optional clear arrow. On press: subtle 1 px downward movement or brief scale `0.98`, returning within 150 ms. Do not add neon outlines or harsh black shadows. One primary CTA per view.

### Secondary button

Warm White (`#FFFFFF`) or Soft Latte Foam (`#F4EFE6`), Rich Espresso text (`#2C1E18`), thin Warm Sand outline (`#E6DCD2`), pill shape, 48 dp target. Disabled state uses reduced emphasis and descriptive disabled text if necessary.

### Illustrated selection / feature card

A rounded rectangle with 16–24 px radius, Rich Espresso or Warm Caramel background, warm oat milk type, and a localized editorial character. Preserve the storyboard's memorable integration between portrait, short label, and card negative space. Ensure illustration does not occlude words or touch zones. Role-selection cards can be tall and visually dramatic; tool/dashboard cards remain concise.

### Camera preview

The camera preview is the actual visual priority. Use a large inset frame with 16–20 px corners; minimal HUD tinted `rgba(44,30,24,0.40)` or deep espresso dark (`#191210`) with optional blur sigma 16 px only in noncritical overlay areas. Frame corners should guide posing without appearing as AI accuracy proof. Show *explicit text status*: `Kamera siap`, `Mendeteksi gestur`, `Mengenali`, `Isyarat belum dikenali`, or `Cahaya kurang`. A progress ring in Warm Caramel (`#8C5A3C`) communicates hold-to-confirm; do not infer success merely from motion. Keep face, hands, and upper body unobstructed.

### Transcript card

High contrast Warm White (`#FFFFFF`) surface with label `Teks Terdeteksi`, recognized words, clearly visible speaker replay, `Spasi`, `Reset`, and relevant copy/history affordances where required. Transcript persists when switching language models unless user explicitly resets it, as required by the product spec.

### Microphone / STT card

Large tactile centered microphone on a restrained Rich Espresso circle (`#2C1E18`). Five thin Warm Caramel responsive waveform bars (`#8C5A3C`); only animate while `Mendengarkan...`. Text is the primary status signal; waveform is supplementary. Provide `Mulai mendengarkan`, `Berhenti`, `Memproses`, `Izin mikrofon dibutuhkan`, and `Tidak ada ucapan terdeteksi` states.

### Sign-language video player

Wide rounded media surface with readable playback controls: play/pause, replay, playback speed `0.75× / 1.0× / 1.25×`, and progress. Sequential video word chips in Soft Latte Foam (`#F4EFE6`) highlight the active token in Warm Caramel (`#8C5A3C`). Controls must have 48 dp targets. Show one of `Tersimpan offline`, `Mengunduh`, `Memerlukan internet`, or `Video tidak tersedia` honestly; never imply every word is supported. Example artwork is **placeholder only** until verified sign video replaces it.

### Category / history / settings rows

Warm White surface (`#FFFFFF`) or simple Warm Sand divider-based grouping (`#E6DCD2`), minimal depth, small illustrated thumbnail where it adds meaning, title + supporting text + clear arrow/action. Use tinted icon circles only as needed. For history, show the translation direction and locally stored text; never fabricate a measured accuracy metric.

### Inputs and empty states

Inputs: label above, thin Warm Sand border (`#E6DCD2`), medium radius 10 px, single caramel/espresso-colored focus indication; error beneath field. Empty state: one editorial illustration and one actionable sentence (`Belum ada riwayat. Mulai penerjemahan untuk menyimpan percakapan.`). Loading: matching skeleton rows for lists and contextual progress/waveform for camera/STT; no default spinner on every surface.

## 5. Layout Principles

- Android-first reference artboard: **393 × 852 px**; maintain safe areas, and adapt to other common phone sizes rather than baking all components into one raster.
- Primary content in a single column; horizontal page gutters 16–24 px.
- Spacing scale: `4, 8, 16, 24, 32, 48` px. Keep baseline spacing consistent on all screens.
- Screen headers typically left aligned; branded splash may center the logotype and a distinct hand-to-waveform mark.
- Illustration-led onboarding should have obvious breathing room and a stable bottom action zone.
- Nav uses 4 labeled actions: `Beranda`, `Riwayat`, `Perpustakaan`, `Pengaturan`; use Rich Espresso / Warm Caramel for active state, not color alone (also shape/weight).
- High-trust tools (camera, STT, player) are structured rather than whimsically asymmetric; decorative doodles appear off to the side, away from meaningful instructions.
- No overlapping text and illustration. No horizontal viewport overflow. No fake desktop chrome wrapped around a mobile app.
- Cards are chosen to establish meaningful functional groupings, not as universal filler.
- Reusable editable components are mandatory. Decorative illustrations are separate image assets, **not flattened backgrounds containing all text and controls**.

## 6. Motion & Interaction

- All transitions are purposeful; consistent `easeInOutCubic` with durations: microfeedback 150 ms, regular state 250 ms, emphasized progress 400 ms.
- Optional spring for card interaction: stiffness 100, damping 20, with a measured translation or transform-only scale.
- For onboarding, gentle sequential entrance (one short stagger sequence), not constant bouncing attention grabbers.
- The live camera ring may progress from 0–100% only during actual confirmation; waveform moves only during listening; playback progress is shown only when media plays.
- Use compositor-friendly `transform` and `opacity`, avoid animating layout width/height or creating expensive perpetual effects while the camera runs.
- Honor reduced-motion settings: freeze decor, replace waveform movement with a static `Mendengarkan...` label, maintain functional status and progress text.
- Haptic feedback supplements rather than replaces visible confirmation.

## 7. Screen Blueprint and Content Contract

Keep the approved storyboard structure and screen order. If a user flow requires extra sheets, place them after core screens rather than replacing approved layouts. Each screen is a **separate, editable mobile artboard**.

| No. | Screen | Layout contract & must-have |
| --- | --- | --- |
| 01 | Splash | Distinct mark: expressive hands becoming speech waveform; Sign2Speech wordmark; `Berkomunikasi Tanpa Batas`; restrained loading dots. Do not reuse the role-selection two-person hero. |
| 02 | Onboarding 1 | `Komunikasi lebih mudah`; explanation of sign→text→speech and speech→sign video; woman character with isolated organic Soft Latte Foam (`#F4EFE6`) shape; steps and next action. |
| 03 | Onboarding 2 | `Untuk semua kesempatan`; public service, daily life, school context; expressive man with open-hand gestures; matching step indicators. |
| 04 | Pilih Peran | Two **stacked** large illustrated cards, `Teman Tuli` and `Teman Dengar`, separated by `atau`; short clear value proposition and `Mulai Sekarang`. Preserve reference card proportions. |
| 05 | Pilih Bahasa Isyarat | Selectable BISINDO and SIBI cards with correct expanded names, graphic hand symbols, radio states; `Lanjut`. |
| 06 | Beranda | Greeting and two prominent feature cards in Rich Espresso (`#2C1E18`) and Warm Caramel (`#8C5A3C`); four-item bottom navigation. |
| 07 | Sign to Speech Camera | Camera preview; BISINDO/SIBI switch; recognition status; confirmation ring; transcript, speaker, pause/stop, spasi, and reset controls. |
| 08 | Hasil Sign to Speech | Sample transcribed words, speaker replay, full text, `Ulangi`, `Simpan`, `Kembali ke Kamera`. Decorative character is not actual sign accuracy validation. |
| 09 | Speech to Sign Microphone | Large central microphone and conditional animated waveform; `Mendengarkan...`; partial transcript; Indonesian locale, stop control, permission states. |
| 10 | Hasil Speech to Sign | Recognized spoken phrase; verified-video player placeholder; active word chips; replay, speed, `Ulangi Kata`, `Putar Semua`; offline indication. |
| 11 | Perpustakaan Isyarat | Search, category chips, `Salam`, `Keluarga`, `Kesehatan`, `Belanja`, `Darurat`, `Layanan Publik`; per-category download states. |
| 12 | Pengaturan | Bahasa Isyarat, Bahasa Suara (id-ID), video speed, offline content, theme, history, about, accessible grouping. |
| 13 | Riwayat | Local translation entries with time and direction, filters (`Semua`, `Sign to Speech`, `Speech to Sign`), replay and delete-confirmation affordance. |

**Functional truth:** Sign to Speech = live camera → detection/AI transcript → Indonesian TTS. Speech to Sign = spoken Indonesian microphone → STT → hierarchical sign matching → sequential sign video. These are not symmetric text-entry features. Do not invent manual typing as the main flow.

**Demonstration copy:** use real Indonesian text such as `Halo`, `Terima kasih`, `Saya mau beli tiket`, `Silakan tunjukkan KTP asli Anda`. These are **sample values**, not claims of completed real-time recognition or dictionary coverage.

### Additional state artboards (after core 13)

- Camera: permission denied, poor lighting, hand out of frame, gesture ambiguous, paused, confirmed.
- Microphone: permission denied, idle, listening, processing, no speech.
- Video: loading, playable offline, online-only, unavailable, media error.
- Downloads: not downloaded, partial progress, downloaded, interrupted.
- Empty history and delete confirmation.

## 8. Accessibility, Privacy, and Trust

- Minimum tap target **48 × 48 dp** for all meaningful actions; every audio-only event also has a visible indicator.
- Aim for WCAG AA or better on all essential text; the main Rich Espresso ink on Warm Oat Milk pairing is intentionally high contrast ($13.8:1$). Do not assume all muted combinations meet every contrast target; test them.
- Use real status words rather than color alone. Example: a confirmation ring should also show `Menunggu konfirmasi` rather than silently implying detection.
- Do not show fake prediction percentages, detection latency, measured frame rates, guaranteed translation accuracy, or unverified numbers.
- Do not present decorative hand poses as authentic reference language signs. Use validated video content where semantics matter.
- Only request camera/microphone permissions in context; provide an explanatory screen. Communicate that camera AI runs on-device, but do not claim unsupported guarantees about the OS-level speech engine's network behavior.
- For offline content distinguish built-in assets, downloaded cache, and internet-only video honestly.
- Data about people's signing, faces, speech, or conversation must not be accidentally represented as publicly uploaded.

## 9. Anti-Patterns (Never Do)

- Never use purple/violet gradients, neon glows, or the typical generic "AI dashboard" aesthetic.
- Never introduce decorative rainbow/pink/blue/yellow accent colors unrelated to brand roles.
- Never use Inter, generic serif fonts, all-caps long headings, or giant gradient text.
- Never replace the drawn characters with 3D avatars, glossy stock photos, or generic AI humans.
- Never use pure black `#000000` where the approved Rich Espresso ink (`#2C1E18`) would work.
- Never use emoji as navigation icons, filler microcopy, or bouncing scroll hints.
- Never cram 3 tiny equal feature cards across one phone viewport.
- Never overlap a character with explanatory text or layer HUD on top of signing hands.
- Never use empty decorative cards or fake generic marketing text ("Next-Gen", "Unleash", "Seamless").
- Never show imaginary user data, fake data-backed accuracy scores, or fake counts of offline videos.
- Never flatten interactive controls into an illustration image; retain editable hierarchy.
- Never modify approved Batch 1 layouts when generating Batch 2 unless a specific screen is requested for targeted revision.

## 10. Stitch Prompting Protocol

**Upload before prompting:**
1. Approved 12-screen storyboard/reference artboard.
2. Approved Cafe Warm Oat Milk / Espresso design system reference (`AppColors`).
3. Brand palette reference.
4. Optionally, isolated transparent illustrated character/hand assets.

**Batch A:** screens 01–05 only (splash, onboarding 1, onboarding 2, role, language). Request one screen per editable artboard, 393 × 852 px.

**Batch B:** screens 06–10 only (home, live camera, sign result, microphone, video result). Instruct Stitch to continue the *existing same project*, not start new brand exploration.

**Batch C:** screens 11–13 (library, settings, history) and relevant functional states.

**Review gates:** visual identity, accurate copy, correct palette, character continuity, 48dp touch controls, text fitting, real app editability, honest status. Approve one batch before continuing.

### Copy-ready Stitch master directive

> Use the uploaded Sign2Speech reference storyboard AND this DESIGN.md as the single visual source of truth. Create separate editable 393 × 852 px mobile screens preserving the approved warm editorial hand-drawn illustration style, Plus Jakarta Sans typography, two recurring espresso-and-white illustrated characters, generous Warm Oat Milk (#FDFBF7) whitespace, Soft Latte Foam (#F4EFE6), and the Cafe Warm Oat Milk / Espresso family (Primary Espresso #2C1E18, Secondary Caramel #8C5A3C, Matcha Sage #4A6B53, Amber Gold #D97724, Warm Sand Border #E6DCD2). Keep the specific user flows and screen numbers from section 7. All UI copy in natural Bahasa Indonesia. No purple, no decorative neon, no Inter, no stock 3D art, no fake AI accuracy, and no flattened screenshot-as-UI. Keep camera and microphone screens functionally realistic, give users clearly labeled states, and use editable reusable cards, word chips, video controls, status messages, and navigation components. Generate only the requested batch; preserve previously approved screens exactly unless asked to revise them.

---

**Source alignment:** Sign2Speech authoritative `AppColors` (`lib/core/theme/app_colors.dart`), `2026-10-13-sign-and-speech-prd.md` product scope, `logic-sign.md` camera/microphone constraints, `2026-10-13-sign-and-speech-plan.md` control states and offline playback, and the approved user-provided UI references. This document intentionally prioritizes their established branding over generic taste-template defaults.
