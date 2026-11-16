-- =============================================================================
-- MIGRASI SKEMA AWAL SIGN2SPEECH (SUPABASE POSTGRESQL, REALTIME, & STORAGE)
-- Target: Supabase Cloud (Free Tier) & Self-Hosted Supabase Docker (Mini PC)
-- Mengikuti standar: supabase-postgres-best-practices
-- =============================================================================

BEGIN;

-- Pastikan ekstensi UUID tersedia
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. FUNGSI TRIGGER OTOMATIS UNTUK KOLOM updated_at
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =============================================================================
-- 2. TABEL cafe_menus (TABEL BARU - CRUD MENU & FOTO KOPI DINAMIS)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.cafe_menus (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 100),
  category TEXT NOT NULL CHECK (category IN ('coffee', 'non_coffee', 'snack')),
  price INTEGER NOT NULL CHECK (price >= 0),
  description TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  image_path TEXT,
  sign_video_url TEXT,
  is_available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cafe_menus_category_available
  ON public.cafe_menus (category, is_available);

CREATE INDEX IF NOT EXISTS idx_cafe_menus_created_at
  ON public.cafe_menus (created_at DESC);

DROP TRIGGER IF EXISTS trg_cafe_menus_updated_at ON public.cafe_menus;
CREATE TRIGGER trg_cafe_menus_updated_at
  BEFORE UPDATE ON public.cafe_menus
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 3. TABEL cafe_orders (TIKET PESANAN MEJA KASIR & ANTREAN BARISTA)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.cafe_orders (
  order_id TEXT PRIMARY KEY CHECK (char_length(order_id) <= 100),
  queue_number TEXT NOT NULL CHECK (char_length(queue_number) <= 20),
  customer_name TEXT NOT NULL DEFAULT '' CHECK (char_length(customer_name) <= 100),
  customer_notes TEXT NOT NULL DEFAULT '' CHECK (char_length(customer_notes) <= 500),
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (
    status IN ('draft', 'confirmed', 'preparing', 'ready', 'readyForPickup', 'completed', 'cancelled')
  ),
  payment_method TEXT NOT NULL DEFAULT 'qris' CHECK (
    payment_method IN ('qris', 'cash', 'debitCard', 'creditCard', 'eWallet')
  ),
  amount_paid INTEGER NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
  subtotal INTEGER NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  tax_amount INTEGER NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  grand_total INTEGER NOT NULL DEFAULT 0 CHECK (grand_total >= 0),
  change_amount INTEGER NOT NULL DEFAULT 0 CHECK (change_amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cafe_orders_status_created_at
  ON public.cafe_orders (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_cafe_orders_created_at
  ON public.cafe_orders (created_at DESC);

DROP TRIGGER IF EXISTS trg_cafe_orders_updated_at ON public.cafe_orders;
CREATE TRIGGER trg_cafe_orders_updated_at
  BEFORE UPDATE ON public.cafe_orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 4. TABEL counter_sessions (SINKRONISASI DUAL-TABLET MEJA KASIR KAFE-01)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.counter_sessions (
  counter_id TEXT PRIMARY KEY CHECK (char_length(counter_id) <= 50),
  stage TEXT NOT NULL DEFAULT 'ordering' CHECK (
    stage IN ('idle', 'ordering', 'naming', 'pickup')
  ),
  device_mode TEXT NOT NULL DEFAULT 'singleTablet' CHECK (
    device_mode IN ('singleTablet', 'dualTablet', 'singleTabletSwitch', 'singleTabletFlip', 'dualTabletLocked')
  ),
  current_order_id TEXT NOT NULL DEFAULT '' CHECK (char_length(current_order_id) <= 100),
  cashier_tablet_id TEXT NOT NULL DEFAULT '',
  customer_tablet_id TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_counter_sessions_updated_at ON public.counter_sessions;
CREATE TRIGGER trg_counter_sessions_updated_at
  BEFORE UPDATE ON public.counter_sessions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 5. TABEL translations_history (RIWAYAT TERJEMAHAN DUA ARAH)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.translations_history (
  id TEXT PRIMARY KEY CHECK (char_length(id) <= 100),
  original_content TEXT NOT NULL CHECK (char_length(original_content) <= 1000),
  translated_content TEXT NOT NULL CHECK (char_length(translated_content) <= 1000),
  direction TEXT NOT NULL CHECK (direction IN ('signToSpeech', 'speechToSign')),
  sign_language_type TEXT NOT NULL CHECK (sign_language_type IN ('BISINDO', 'SIBI')),
  timestamp TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_translations_history_created_at
  ON public.translations_history (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_translations_history_timestamp
  ON public.translations_history (timestamp DESC);

-- =============================================================================
-- 6. TABEL user_settings (PREFERENSI AKSESIBILITAS PENGGUNA)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id TEXT PRIMARY KEY DEFAULT 'default_user' CHECK (char_length(user_id) <= 100),
  role TEXT NOT NULL DEFAULT 'deaf' CHECK (
    role IN ('deaf', 'hearing', 'cashier') OR char_length(role) <= 50
  ),
  sign_language TEXT NOT NULL DEFAULT 'BISINDO' CHECK (sign_language IN ('BISINDO', 'SIBI')),
  app_language TEXT NOT NULL DEFAULT 'id' CHECK (app_language IN ('id', 'en')),
  theme_mode TEXT NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('system', 'light', 'dark')),
  tts_speed NUMERIC NOT NULL DEFAULT 1.0 CHECK (tts_speed >= 0.25 AND tts_speed <= 3.0),
  video_speed NUMERIC NOT NULL DEFAULT 1.0 CHECK (video_speed >= 0.25 AND video_speed <= 3.0),
  has_completed_onboarding BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER trg_user_settings_updated_at
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 7. TABEL sign_transcripts (ARSIP TOKEN DETEKSI MOTIONGRU)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.sign_transcripts (
  transcript_id TEXT PRIMARY KEY CHECK (char_length(transcript_id) <= 100),
  session_id TEXT NOT NULL CHECK (char_length(session_id) <= 100),
  tokens JSONB NOT NULL DEFAULT '[]'::jsonb,
  full_sentence TEXT NOT NULL DEFAULT '' CHECK (char_length(full_sentence) <= 1000),
  token_count INTEGER NOT NULL DEFAULT 0 CHECK (token_count >= 0),
  language_type TEXT NOT NULL DEFAULT 'BISINDO' CHECK (language_type IN ('BISINDO', 'SIBI')),
  session_notes TEXT NOT NULL DEFAULT '' CHECK (char_length(session_notes) <= 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sign_transcripts_created_at
  ON public.sign_transcripts (created_at DESC);

-- =============================================================================
-- 8. TABEL user_loyalty (STEMPEL LOYALITAS PELANGGAN KAFE)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_loyalty (
  customer_id TEXT PRIMARY KEY CHECK (char_length(customer_id) <= 100),
  stamps_count INTEGER NOT NULL DEFAULT 0 CHECK (stamps_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_user_loyalty_updated_at ON public.user_loyalty;
CREATE TRIGGER trg_user_loyalty_updated_at
  BEFORE UPDATE ON public.user_loyalty
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 9. TABEL test_connection (PROBE DIAGNOSTIK KONEKSI)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.test_connection (
  id TEXT PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'active',
  message TEXT NOT NULL DEFAULT 'Probe active from Flutter client',
  client TEXT NOT NULL DEFAULT 'Sign2Speech Mobile MVP',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- 10. KONFIGURASI ROW LEVEL SECURITY (RLS) UNTUK SEMUA TABEL
-- =============================================================================
ALTER TABLE public.cafe_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.counter_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translations_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sign_transcripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_loyalty ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_connection ENABLE ROW LEVEL SECURITY;

-- Policies untuk cafe_menus
DROP POLICY IF EXISTS "cafe_menus_select_policy" ON public.cafe_menus;
CREATE POLICY "cafe_menus_select_policy" ON public.cafe_menus
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "cafe_menus_insert_policy" ON public.cafe_menus;
CREATE POLICY "cafe_menus_insert_policy" ON public.cafe_menus
  FOR INSERT TO anon, authenticated WITH CHECK (price >= 0 AND char_length(name) <= 100);

DROP POLICY IF EXISTS "cafe_menus_update_policy" ON public.cafe_menus;
CREATE POLICY "cafe_menus_update_policy" ON public.cafe_menus
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (price >= 0 AND char_length(name) <= 100);

DROP POLICY IF EXISTS "cafe_menus_delete_policy" ON public.cafe_menus;
CREATE POLICY "cafe_menus_delete_policy" ON public.cafe_menus
  FOR DELETE TO anon, authenticated USING (true);

-- Policies untuk cafe_orders
DROP POLICY IF EXISTS "cafe_orders_select_policy" ON public.cafe_orders;
CREATE POLICY "cafe_orders_select_policy" ON public.cafe_orders
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "cafe_orders_insert_policy" ON public.cafe_orders;
CREATE POLICY "cafe_orders_insert_policy" ON public.cafe_orders
  FOR INSERT TO anon, authenticated WITH CHECK (amount_paid >= 0 AND grand_total >= 0);

DROP POLICY IF EXISTS "cafe_orders_update_policy" ON public.cafe_orders;
CREATE POLICY "cafe_orders_update_policy" ON public.cafe_orders
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (amount_paid >= 0 AND grand_total >= 0);

DROP POLICY IF EXISTS "cafe_orders_delete_policy" ON public.cafe_orders;
CREATE POLICY "cafe_orders_delete_policy" ON public.cafe_orders
  FOR DELETE TO anon, authenticated USING (true);

-- Policies untuk counter_sessions (Sinkronisasi Dual-Tablet KAFE-01 Bebas Blokir!)
DROP POLICY IF EXISTS "counter_sessions_select_policy" ON public.counter_sessions;
CREATE POLICY "counter_sessions_select_policy" ON public.counter_sessions
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "counter_sessions_insert_policy" ON public.counter_sessions;
CREATE POLICY "counter_sessions_insert_policy" ON public.counter_sessions
  FOR INSERT TO anon, authenticated WITH CHECK (char_length(counter_id) <= 50);

DROP POLICY IF EXISTS "counter_sessions_update_policy" ON public.counter_sessions;
CREATE POLICY "counter_sessions_update_policy" ON public.counter_sessions
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (char_length(counter_id) <= 50);

DROP POLICY IF EXISTS "counter_sessions_delete_policy" ON public.counter_sessions;
CREATE POLICY "counter_sessions_delete_policy" ON public.counter_sessions
  FOR DELETE TO anon, authenticated USING (true);

-- Policies untuk translations_history
DROP POLICY IF EXISTS "translations_history_select_policy" ON public.translations_history;
CREATE POLICY "translations_history_select_policy" ON public.translations_history
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "translations_history_insert_policy" ON public.translations_history;
CREATE POLICY "translations_history_insert_policy" ON public.translations_history
  FOR INSERT TO anon, authenticated WITH CHECK (char_length(original_content) <= 1000);

DROP POLICY IF EXISTS "translations_history_update_policy" ON public.translations_history;
CREATE POLICY "translations_history_update_policy" ON public.translations_history
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (char_length(original_content) <= 1000);

DROP POLICY IF EXISTS "translations_history_delete_policy" ON public.translations_history;
CREATE POLICY "translations_history_delete_policy" ON public.translations_history
  FOR DELETE TO anon, authenticated USING (true);

-- Policies untuk user_settings
DROP POLICY IF EXISTS "user_settings_select_policy" ON public.user_settings;
CREATE POLICY "user_settings_select_policy" ON public.user_settings
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "user_settings_insert_policy" ON public.user_settings;
CREATE POLICY "user_settings_insert_policy" ON public.user_settings
  FOR INSERT TO anon, authenticated WITH CHECK (char_length(user_id) <= 100);

DROP POLICY IF EXISTS "user_settings_update_policy" ON public.user_settings;
CREATE POLICY "user_settings_update_policy" ON public.user_settings
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (char_length(user_id) <= 100);

-- Policies untuk sign_transcripts
DROP POLICY IF EXISTS "sign_transcripts_select_policy" ON public.sign_transcripts;
CREATE POLICY "sign_transcripts_select_policy" ON public.sign_transcripts
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "sign_transcripts_insert_policy" ON public.sign_transcripts;
CREATE POLICY "sign_transcripts_insert_policy" ON public.sign_transcripts
  FOR INSERT TO anon, authenticated WITH CHECK (char_length(session_id) <= 100);

DROP POLICY IF EXISTS "sign_transcripts_update_policy" ON public.sign_transcripts;
CREATE POLICY "sign_transcripts_update_policy" ON public.sign_transcripts
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (char_length(session_id) <= 100);

DROP POLICY IF EXISTS "sign_transcripts_delete_policy" ON public.sign_transcripts;
CREATE POLICY "sign_transcripts_delete_policy" ON public.sign_transcripts
  FOR DELETE TO anon, authenticated USING (true);

-- Policies untuk user_loyalty
DROP POLICY IF EXISTS "user_loyalty_select_policy" ON public.user_loyalty;
CREATE POLICY "user_loyalty_select_policy" ON public.user_loyalty
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "user_loyalty_upsert_policy" ON public.user_loyalty;
CREATE POLICY "user_loyalty_upsert_policy" ON public.user_loyalty
  FOR INSERT TO anon, authenticated WITH CHECK (stamps_count >= 0);

DROP POLICY IF EXISTS "user_loyalty_update_policy" ON public.user_loyalty;
CREATE POLICY "user_loyalty_update_policy" ON public.user_loyalty
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (stamps_count >= 0);

-- Policies untuk test_connection
DROP POLICY IF EXISTS "test_connection_select_policy" ON public.test_connection;
CREATE POLICY "test_connection_select_policy" ON public.test_connection
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "test_connection_upsert_policy" ON public.test_connection;
CREATE POLICY "test_connection_upsert_policy" ON public.test_connection
  FOR INSERT TO anon, authenticated WITH CHECK (char_length(id) <= 100);

DROP POLICY IF EXISTS "test_connection_update_policy" ON public.test_connection;
CREATE POLICY "test_connection_update_policy" ON public.test_connection
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (char_length(id) <= 100);

-- =============================================================================
-- 11. KONFIGURASI SUPABASE REALTIME PUBLICATION
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'cafe_orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.cafe_orders;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'counter_sessions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.counter_sessions;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'cafe_menus'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.cafe_menus;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'translations_history'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.translations_history;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'user_settings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_settings;
  END IF;
END $$;

-- =============================================================================
-- 12. KONFIGURASI SUPABASE STORAGE BUCKETS (menu-photos & sign-videos)
-- =============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'menu-photos',
  'menu-photos',
  true,
  5242880, -- 5 MB max (dikompres di client menjadi ~50-100 KB)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'sign-videos',
  'sign-videos',
  true,
  52428800, -- 50 MB max untuk video MP4 & catalog.json
  ARRAY['video/mp4', 'application/json']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Policies untuk Storage Objects pada bucket menu-photos
DROP POLICY IF EXISTS "menu_photos_public_select" ON storage.objects;
CREATE POLICY "menu_photos_public_select" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'menu-photos');

DROP POLICY IF EXISTS "menu_photos_public_insert" ON storage.objects;
CREATE POLICY "menu_photos_public_insert" ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'menu-photos');

DROP POLICY IF EXISTS "menu_photos_public_update" ON storage.objects;
CREATE POLICY "menu_photos_public_update" ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (bucket_id = 'menu-photos')
  WITH CHECK (bucket_id = 'menu-photos');

DROP POLICY IF EXISTS "menu_photos_public_delete" ON storage.objects;
CREATE POLICY "menu_photos_public_delete" ON storage.objects
  FOR DELETE TO anon, authenticated
  USING (bucket_id = 'menu-photos');

-- Policies untuk Storage Objects pada bucket sign-videos
DROP POLICY IF EXISTS "sign_videos_public_select" ON storage.objects;
CREATE POLICY "sign_videos_public_select" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'sign-videos');

DROP POLICY IF EXISTS "sign_videos_public_insert" ON storage.objects;
CREATE POLICY "sign_videos_public_insert" ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'sign-videos');

DROP POLICY IF EXISTS "sign_videos_public_update" ON storage.objects;
CREATE POLICY "sign_videos_public_update" ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (bucket_id = 'sign-videos')
  WITH CHECK (bucket_id = 'sign-videos');

-- Seed data awal untuk cafe_menus (Menu Default Kafe Sign2Speech)
INSERT INTO public.cafe_menus (id, name, category, price, description, is_available)
VALUES
  ('kopi_susu_oat', 'Kopi Susu Oat', 'coffee', 28000, 'Espresso dengan susu gandum oat pilihan yang ramah lambung', true),
  ('americano', 'Americano', 'coffee', 20000, 'Single origin espresso dengan air hangat atau es', true),
  ('caramel_latte', 'Caramel Latte', 'coffee', 30000, 'Espresso lembut dengan sirup karamel panggang', true),
  ('matcha_latte', 'Matcha Latte', 'non_coffee', 28000, 'Uji matcha Jepang murni dengan susu pilihan', true),
  ('cokelat_klasik', 'Cokelat Klasik', 'non_coffee', 26000, 'Cokelat hitam pekat hangat atau dingin', true)
ON CONFLICT (id) DO NOTHING;

COMMIT;
