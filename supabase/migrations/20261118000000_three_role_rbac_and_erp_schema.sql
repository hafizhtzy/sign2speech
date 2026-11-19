-- =============================================================================
-- MIGRASI ADDENDUM V3: THREE-ROLE RBAC (CUSTOMER, CASHIER, ADMIN),
-- INVENTORY LEDGER (STOCK OPNAME), MIDTRANS QRIS & ADMIN ERP SCHEMA
-- Non-Destructive Upgrade on top of 20261115000000_initial_sign2speech_schema.sql
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Helper trigger function to update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =============================================================================
-- 1. TABEL PROFILES & SERVER-AUTHORITATIVE RBAC HELPERS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL DEFAULT '' CHECK (char_length(full_name) <= 120),
  phone TEXT CHECK (phone IS NULL OR char_length(phone) <= 30),
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'cashier', 'admin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'invited')),
  communication_mode TEXT NOT NULL DEFAULT 'deaf' CHECK (communication_mode IN ('deaf', 'hearing')),
  preferred_sign_system TEXT NOT NULL DEFAULT 'BISINDO' CHECK (preferred_sign_system IN ('BISINDO', 'SIBI')),
  invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  disabled_at TIMESTAMPTZ,
  disabled_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_role_status
  ON public.profiles (role, status);

CREATE INDEX IF NOT EXISTS idx_profiles_email
  ON public.profiles (lower(email));

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Helper: Returns caller's active role ('customer', 'cashier', 'admin') or NULL if unauthenticated/disabled.
-- Reads directly from public.profiles so disabling a cashier revokes DB access immediately
-- even before their JWT expires.
CREATE OR REPLACE FUNCTION public.current_active_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.role
  FROM public.profiles p
  WHERE p.id = auth.uid()
    AND p.status = 'active'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(public.current_active_role() = 'admin', false);
$$;

CREATE OR REPLACE FUNCTION public.is_cashier()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(public.current_active_role() = 'cashier', false);
$$;

CREATE OR REPLACE FUNCTION public.is_cashier_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(public.current_active_role() IN ('cashier', 'admin'), false);
$$;

CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.current_active_role() IS NOT NULL;
$$;

-- Trigger: Automatically provision public.profiles on new auth.users signup.
-- Forces role = 'customer' unless explicitly provisioned by service_role in raw_app_meta_data.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role TEXT;
  v_status TEXT;
  v_name TEXT;
  v_comm TEXT;
  v_sign TEXT;
BEGIN
  v_role := COALESCE(NEW.raw_app_meta_data->>'app_role', 'customer');
  IF v_role NOT IN ('customer', 'cashier', 'admin') THEN
    v_role := 'customer';
  END IF;

  v_status := COALESCE(NEW.raw_app_meta_data->>'account_status', 'active');
  IF v_status NOT IN ('active', 'disabled', 'invited') THEN
    v_status := 'active';
  END IF;

  v_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    split_part(COALESCE(NEW.email, 'Pelanggan'), '@', 1)
  );
  v_comm := COALESCE(NEW.raw_user_meta_data->>'communication_mode', 'deaf');
  IF v_comm NOT IN ('deaf', 'hearing') THEN
    v_comm := 'deaf';
  END IF;

  v_sign := COALESCE(NEW.raw_user_meta_data->>'preferred_sign_system', 'BISINDO');
  IF v_sign NOT IN ('BISINDO', 'SIBI') THEN
    v_sign := 'BISINDO';
  END IF;

  INSERT INTO public.profiles (
    id, email, full_name, phone, role, status, communication_mode, preferred_sign_system
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    left(v_name, 120),
    left(NEW.raw_user_meta_data->>'phone', 30),
    v_role,
    v_status,
    v_comm,
    v_sign
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = now();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Trigger: Block any client-side role or status escalation on public.profiles.
-- Only service_role (Edge Functions / Trusted Server Provisioning) can alter role or status.
CREATE OR REPLACE FUNCTION public.prevent_profile_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_jwt_role TEXT := COALESCE(current_setting('request.jwt.claim.role', true), '');
BEGIN
  IF v_jwt_role IN ('anon', 'authenticated') THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Unauthorized: role cannot be modified from client session.';
    END IF;
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      RAISE EXCEPTION 'Unauthorized: account status cannot be modified from client session.';
    END IF;
    IF NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'Unauthorized: email cannot be modified directly on profiles.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_profile_role_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_profile_role_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_role_escalation();

-- =============================================================================
-- 2. TABEL AUDIT LOGS (APPEND-ONLY, IMMUTABLE)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_role TEXT NOT NULL DEFAULT 'system',
  actor_name TEXT NOT NULL DEFAULT '',
  action TEXT NOT NULL CHECK (char_length(action) <= 100),
  entity_type TEXT NOT NULL CHECK (char_length(entity_type) <= 80),
  entity_id TEXT NOT NULL CHECK (char_length(entity_id) <= 120),
  before_data JSONB,
  after_data JSONB,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'denied', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at
  ON public.audit_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
  ON public.audit_logs (entity_type, entity_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor
  ON public.audit_logs (actor_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.prevent_audit_log_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'Audit logs are immutable and cannot be updated or deleted.';
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_logs_immutable ON public.audit_logs;
CREATE TRIGGER trg_audit_logs_immutable
  BEFORE UPDATE OR DELETE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_log_mutation();

REVOKE UPDATE, DELETE, TRUNCATE ON public.audit_logs FROM anon, authenticated;

-- Helper function to insert server-side audit logs
CREATE OR REPLACE FUNCTION public.write_audit_log(
  p_action TEXT,
  p_entity_type TEXT,
  p_entity_id TEXT,
  p_before JSONB DEFAULT NULL,
  p_after JSONB DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb,
  p_status TEXT DEFAULT 'success'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_role TEXT := 'system';
  v_name TEXT := 'System';
  v_log_id UUID;
BEGIN
  IF v_uid IS NOT NULL THEN
    SELECT p.role, p.full_name
      INTO v_role, v_name
      FROM public.profiles p
     WHERE p.id = v_uid;
  END IF;

  INSERT INTO public.audit_logs (
    actor_id, actor_role, actor_name, action, entity_type, entity_id,
    before_data, after_data, metadata, status
  )
  VALUES (
    v_uid,
    COALESCE(v_role, 'unknown'),
    COALESCE(v_name, ''),
    p_action,
    p_entity_type,
    p_entity_id,
    p_before,
    p_after,
    COALESCE(p_metadata, '{}'::jsonb),
    p_status
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- =============================================================================
-- 3. TABEL PRODUCT CATEGORIES & NON-DESTRUCTIVE UPGRADE cafe_menus
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE CHECK (char_length(slug) >= 1 AND char_length(slug) <= 60),
  name_id TEXT NOT NULL CHECK (char_length(name_id) >= 1 AND char_length(name_id) <= 80),
  name_en TEXT NOT NULL DEFAULT '' CHECK (char_length(name_en) <= 80),
  description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 300),
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_product_categories_updated_at ON public.product_categories;
CREATE TRIGGER trg_product_categories_updated_at
  BEFORE UPDATE ON public.product_categories
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

INSERT INTO public.product_categories (slug, name_id, name_en, description, sort_order, is_active)
VALUES
  ('coffee', 'Kopi Signature', 'Signature Coffee', 'Minuman berbasis espresso dan kopi pilihan', 1, true),
  ('non_coffee', 'Non-Kopi & Matcha', 'Non-Coffee & Matcha', 'Minuman cokelat, teh, matcha, dan susu nabati', 2, true),
  ('snack', 'Camilan & Pastry', 'Snacks & Pastries', 'Pendamping kopi hangat setiap hari', 3, true)
ON CONFLICT (slug) DO NOTHING;

-- Relax old hardcoded category check on cafe_menus so Admin-created categories work
ALTER TABLE public.cafe_menus DROP CONSTRAINT IF EXISTS cafe_menus_category_check;
ALTER TABLE public.cafe_menus
  ADD CONSTRAINT cafe_menus_category_len_check CHECK (char_length(category) >= 1 AND char_length(category) <= 60);

-- Add ERP & Inventory columns to cafe_menus WITHOUT inventing stock=25 for legacy items!
-- Legacy items get is_stock_initialized = false and stock_on_hand = 0 until Admin Stock Opname.
ALTER TABLE public.cafe_menus
  ADD COLUMN IF NOT EXISTS sku TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS cost_price INTEGER CHECK (cost_price IS NULL OR cost_price >= 0),
  ADD COLUMN IF NOT EXISTS is_stock_initialized BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS stock_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (stock_on_hand >= 0),
  ADD COLUMN IF NOT EXISTS stock_reserved INTEGER NOT NULL DEFAULT 0 CHECK (stock_reserved >= 0),
  ADD COLUMN IF NOT EXISTS low_stock_threshold INTEGER NOT NULL DEFAULT 5 CHECK (low_stock_threshold >= 0),
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.cafe_menus DROP CONSTRAINT IF EXISTS chk_cafe_menus_reserved_le_on_hand;
ALTER TABLE public.cafe_menus
  ADD CONSTRAINT chk_cafe_menus_reserved_le_on_hand CHECK (stock_reserved <= stock_on_hand);

-- Link existing cafe_menus rows to product_categories by slug without altering stock
UPDATE public.cafe_menus m
   SET category_id = c.id
  FROM public.product_categories c
 WHERE m.category = c.slug
   AND m.category_id IS NULL;

-- =============================================================================
-- 4. TABEL INVENTORY MOVEMENTS (LEDGER) & LOW STOCK REPORTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.inventory_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id TEXT NOT NULL REFERENCES public.cafe_menus(id) ON DELETE RESTRICT,
  movement_type TEXT NOT NULL CHECK (
    movement_type IN (
      'initial_opname',
      'restock',
      'adjustment_in',
      'adjustment_out',
      'damage',
      'loss',
      'reserve',
      'release',
      'sale',
      'refund_restock'
    )
  ),
  quantity_delta INTEGER NOT NULL,
  stock_before INTEGER NOT NULL CHECK (stock_before >= 0),
  stock_after INTEGER NOT NULL CHECK (stock_after >= 0),
  reserved_before INTEGER NOT NULL DEFAULT 0 CHECK (reserved_before >= 0),
  reserved_after INTEGER NOT NULL DEFAULT 0 CHECK (reserved_after >= 0),
  reference_type TEXT NOT NULL CHECK (char_length(reference_type) <= 50),
  reference_id TEXT NOT NULL CHECK (char_length(reference_id) <= 120),
  reason TEXT NOT NULL CHECK (char_length(trim(reason)) >= 3 AND char_length(reason) <= 500),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_inventory_movement_idempotency
    UNIQUE (reference_type, reference_id, product_id, movement_type)
);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_product_created
  ON public.inventory_movements (product_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.low_stock_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id TEXT NOT NULL REFERENCES public.cafe_menus(id) ON DELETE CASCADE,
  reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_available_stock INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL CHECK (char_length(trim(note)) >= 3 AND char_length(note) <= 500),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved')),
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_low_stock_reports_status_created
  ON public.low_stock_reports (status, created_at DESC);

-- =============================================================================
-- 5. UPGRADE cafe_orders, cafe_order_items, payments, payment_events, refunds
-- =============================================================================
ALTER TABLE public.cafe_orders
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS cashier_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS order_source TEXT NOT NULL DEFAULT 'customer_app' CHECK (
    order_source IN ('customer_app', 'cashier_pos')
  ),
  ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (
    payment_status IN ('unpaid', 'pending', 'paid', 'failed', 'expired', 'refunded', 'partially_refunded')
  ),
  ADD COLUMN IF NOT EXISTS is_simulation BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_cafe_orders_customer_created
  ON public.cafe_orders (customer_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_cafe_orders_payment_status_paid_at
  ON public.cafe_orders (payment_status, paid_at DESC);

CREATE TABLE IF NOT EXISTS public.cafe_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT NOT NULL REFERENCES public.cafe_orders(order_id) ON DELETE RESTRICT,
  product_id TEXT NOT NULL REFERENCES public.cafe_menus(id) ON DELETE RESTRICT,
  product_name_snapshot TEXT NOT NULL,
  sku_snapshot TEXT,
  unit_price_snapshot INTEGER NOT NULL CHECK (unit_price_snapshot >= 0),
  cost_price_snapshot INTEGER CHECK (cost_price_snapshot IS NULL OR cost_price_snapshot >= 0),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  modifiers_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  line_subtotal INTEGER NOT NULL CHECK (line_subtotal >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cafe_order_items_order_id
  ON public.cafe_order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_cafe_order_items_product_id
  ON public.cafe_order_items (product_id);

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT NOT NULL REFERENCES public.cafe_orders(order_id) ON DELETE RESTRICT,
  provider TEXT NOT NULL CHECK (provider IN ('midtrans', 'cash', 'sandbox_simulator')),
  is_simulation BOOLEAN NOT NULL DEFAULT false,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('qris', 'cash')),
  midtrans_order_id TEXT UNIQUE,
  midtrans_transaction_id TEXT UNIQUE,
  idempotency_key TEXT NOT NULL UNIQUE,
  gross_amount INTEGER NOT NULL CHECK (gross_amount >= 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'paid', 'failed', 'expired', 'cancelled', 'refunded')
  ),
  qr_string TEXT,
  qr_code_url TEXT,
  qris_actions JSONB NOT NULL DEFAULT '[]'::jsonb,
  acquirer TEXT,
  expires_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  verified_by_webhook BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_payments_simulation_consistency CHECK (
    (provider = 'sandbox_simulator' AND is_simulation = true) OR
    (provider <> 'sandbox_simulator' AND is_simulation = false)
  )
);

CREATE INDEX IF NOT EXISTS idx_payments_order_id
  ON public.payments (order_id, created_at DESC);

DROP TRIGGER IF EXISTS trg_payments_updated_at ON public.payments;
CREATE TRIGGER trg_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TABLE IF NOT EXISTS public.payment_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE RESTRICT,
  dedup_key TEXT NOT NULL UNIQUE,
  payload_sha256 TEXT NOT NULL,
  midtrans_transaction_id TEXT,
  midtrans_order_id TEXT,
  transaction_status TEXT NOT NULL,
  fraud_status TEXT,
  status_code TEXT,
  signature_verified BOOLEAN NOT NULL DEFAULT false,
  is_simulation BOOLEAN NOT NULL DEFAULT false,
  payload_sanitized JSONB NOT NULL DEFAULT '{}'::jsonb,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_events_payment_id
  ON public.payment_events (payment_id, received_at DESC);

CREATE TABLE IF NOT EXISTS public.refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT NOT NULL REFERENCES public.cafe_orders(order_id) ON DELETE RESTRICT,
  payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE RESTRICT,
  amount INTEGER NOT NULL CHECK (amount > 0),
  reason TEXT NOT NULL CHECK (char_length(trim(reason)) >= 3 AND char_length(reason) <= 500),
  restock_items BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_refunds_order_status
  ON public.refunds (order_id, status, completed_at DESC);

-- =============================================================================
-- 6. TABEL SIGN LANGUAGE VIDEOS (METADATA & PUBLISHING WORKFLOW)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.sign_language_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL CHECK (char_length(trim(title)) >= 1 AND char_length(title) <= 120),
  slug TEXT NOT NULL CHECK (char_length(trim(slug)) >= 1 AND char_length(slug) <= 120),
  gloss TEXT NOT NULL CHECK (char_length(trim(gloss)) >= 1 AND char_length(gloss) <= 120),
  aliases TEXT[] NOT NULL DEFAULT '{}',
  language_type TEXT NOT NULL DEFAULT 'BISINDO' CHECK (language_type IN ('BISINDO', 'SIBI')),
  category TEXT NOT NULL DEFAULT 'umum' CHECK (char_length(category) <= 60),
  description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 600),
  storage_bucket TEXT NOT NULL DEFAULT 'sign-language-videos',
  storage_path TEXT NOT NULL CHECK (char_length(storage_path) <= 300),
  thumbnail_path TEXT CHECK (thumbnail_path IS NULL OR char_length(thumbnail_path) <= 300),
  duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  mime_type TEXT NOT NULL DEFAULT 'video/mp4' CHECK (mime_type IN ('video/mp4', 'video/webm')),
  file_size_bytes BIGINT CHECK (file_size_bytes IS NULL OR (file_size_bytes > 0 AND file_size_bytes <= 52428800)),
  publication_status TEXT NOT NULL DEFAULT 'draft' CHECK (
    publication_status IN ('draft', 'published', 'archived')
  ),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  published_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_sign_language_video_lang_slug UNIQUE (language_type, slug)
);

CREATE INDEX IF NOT EXISTS idx_sign_videos_status_lang
  ON public.sign_language_videos (publication_status, language_type, category);

DROP TRIGGER IF EXISTS trg_sign_language_videos_updated_at ON public.sign_language_videos;
CREATE TRIGGER trg_sign_language_videos_updated_at
  BEFORE UPDATE ON public.sign_language_videos
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Add ownership columns to legacy accessibility tables without losing existing rows
ALTER TABLE public.translations_history
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.user_settings
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.sign_transcripts
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.user_loyalty
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- =============================================================================
-- 7. ATOMIC DATABASE FUNCTIONS (INVENTORY, ORDER RESERVATION, QRIS, REPORTS)
-- =============================================================================

-- 7.1 Expire stale QRIS reservations so expired orders never hold stock forever
CREATE OR REPLACE FUNCTION public.rpc_expire_stale_qris_reservations()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order RECORD;
  v_item RECORD;
  v_menu RECORD;
  v_expired_count INTEGER := 0;
BEGIN
  FOR v_order IN
    SELECT o.order_id
      FROM public.cafe_orders o
     WHERE o.payment_status = 'pending'
       AND o.expires_at IS NOT NULL
       AND o.expires_at < now()
       AND o.status NOT IN ('completed', 'cancelled')
     FOR UPDATE SKIP LOCKED
  LOOP
    FOR v_item IN
      SELECT oi.product_id, oi.quantity
        FROM public.cafe_order_items oi
       WHERE oi.order_id = v_order.order_id
       ORDER BY oi.product_id
    LOOP
      SELECT m.id, m.stock_on_hand, m.stock_reserved
        INTO v_menu
        FROM public.cafe_menus m
       WHERE m.id = v_item.product_id
       FOR UPDATE;

      IF FOUND AND v_menu.stock_reserved >= v_item.quantity THEN
        INSERT INTO public.inventory_movements (
          product_id, movement_type, quantity_delta,
          stock_before, stock_after, reserved_before, reserved_after,
          reference_type, reference_id, reason
        )
        VALUES (
          v_menu.id, 'release', 0,
          v_menu.stock_on_hand, v_menu.stock_on_hand,
          v_menu.stock_reserved, v_menu.stock_reserved - v_item.quantity,
          'order_expired', v_order.order_id, 'Reservasi QRIS dilepas otomatis karena pembayaran kedaluwarsa'
        )
        ON CONFLICT (reference_type, reference_id, product_id, movement_type) DO NOTHING;

        IF FOUND THEN
          UPDATE public.cafe_menus
             SET stock_reserved = stock_reserved - v_item.quantity,
                 updated_at = now()
           WHERE id = v_menu.id;
        END IF;
      END IF;
    END LOOP;

    UPDATE public.cafe_orders
       SET payment_status = 'expired',
           status = 'cancelled',
           cancelled_at = now(),
           updated_at = now()
     WHERE order_id = v_order.order_id;

    UPDATE public.payments
       SET status = 'expired',
           updated_at = now()
     WHERE order_id = v_order.order_id
       AND status = 'pending';

    v_expired_count := v_expired_count + 1;
  END LOOP;

  RETURN v_expired_count;
END;
$$;

-- 7.2 Create Order with Atomic Stock Reservation & Server-Side Price Snapshot
CREATE OR REPLACE FUNCTION public.rpc_create_order_with_reservation(
  p_order_id TEXT,
  p_queue_number TEXT,
  p_customer_name TEXT,
  p_customer_notes TEXT,
  p_payment_method TEXT,
  p_order_source TEXT,
  p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_role TEXT := public.current_active_role();
  v_item JSONB;
  v_product_id TEXT;
  v_qty INTEGER;
  v_modifiers JSONB;
  v_modifier_extra INTEGER;
  v_menu RECORD;
  v_available INTEGER;
  v_unit_price INTEGER;
  v_line_subtotal INTEGER;
  v_subtotal INTEGER := 0;
  v_tax INTEGER := 0;
  v_grand_total INTEGER := 0;
  v_expires_at TIMESTAMPTZ := now() + interval '15 minutes';
BEGIN
  IF v_uid IS NULL OR v_role IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: active authenticated account required to create order.';
  END IF;

  IF p_payment_method NOT IN ('qris', 'cash') THEN
    RAISE EXCEPTION 'Invalid payment method: %', p_payment_method;
  END IF;

  -- CUSTOMER can only create QRIS orders via customer_app
  IF v_role = 'customer' AND (p_payment_method <> 'qris' OR p_order_source <> 'customer_app') THEN
    RAISE EXCEPTION 'Forbidden: customers can only checkout via QRIS on customer_app.';
  END IF;

  IF jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Validation error: order must contain at least 1 item.';
  END IF;

  -- Release any stale reservations before checking stock
  PERFORM public.rpc_expire_stale_qris_reservations();

  -- Create shell order row first so cafe_order_items FK is satisfied
  INSERT INTO public.cafe_orders (
    order_id, queue_number, customer_name, customer_notes,
    items, status, payment_method, payment_status,
    customer_id, cashier_id, order_source,
    amount_paid, subtotal, tax_amount, grand_total, change_amount, expires_at
  )
  VALUES (
    p_order_id,
    p_queue_number,
    COALESCE(trim(p_customer_name), 'Pelanggan'),
    COALESCE(trim(p_customer_notes), ''),
    p_items,
    'confirmed',
    p_payment_method,
    'pending',
    CASE WHEN v_role = 'customer' THEN v_uid ELSE NULL END,
    CASE WHEN v_role IN ('cashier', 'admin') THEN v_uid ELSE NULL END,
    p_order_source,
    0, 0, 0, 0, 0,
    v_expires_at
  );

  -- Lock products in deterministic order by product_id to prevent deadlocks
  FOR v_item IN
    SELECT value
      FROM jsonb_array_elements(p_items) AS t(value)
     ORDER BY (value->>'product_id') ASC
  LOOP
    v_product_id := trim(COALESCE(v_item->>'product_id', ''));
    v_qty := COALESCE((v_item->>'quantity')::integer, 0);
    v_modifiers := COALESCE(v_item->'modifiers', '{}'::jsonb);
    v_modifier_extra := GREATEST(COALESCE((v_item->>'modifier_extra_price')::integer, 0), 0);

    IF v_product_id = '' OR v_qty <= 0 THEN
      RAISE EXCEPTION 'Invalid item payload for product_id=%', v_product_id;
    END IF;

    SELECT m.*
      INTO v_menu
      FROM public.cafe_menus m
     WHERE m.id = v_product_id
     FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Product not found: %', v_product_id;
    END IF;

    IF v_menu.is_archived OR NOT v_menu.is_available THEN
      RAISE EXCEPTION 'Produk "%" sedang tidak aktif atau tidak tersedia.', v_menu.name;
    END IF;

    IF NOT v_menu.is_stock_initialized THEN
      RAISE EXCEPTION 'Stok produk "%" belum diinisialisasi (Stock Opname belum dilakukan oleh Admin).', v_menu.name;
    END IF;

    v_available := v_menu.stock_on_hand - v_menu.stock_reserved;
    IF v_available < v_qty THEN
      RAISE EXCEPTION 'Stok produk "%" tidak mencukupi (tersedia: %, diminta: %).',
        v_menu.name, v_available, v_qty;
    END IF;

    v_unit_price := v_menu.price + v_modifier_extra;
    v_line_subtotal := v_unit_price * v_qty;
    v_subtotal := v_subtotal + v_line_subtotal;

    -- Reserve stock atomically
    INSERT INTO public.inventory_movements (
      product_id, movement_type, quantity_delta,
      stock_before, stock_after, reserved_before, reserved_after,
      reference_type, reference_id, reason, created_by
    )
    VALUES (
      v_menu.id, 'reserve', 0,
      v_menu.stock_on_hand, v_menu.stock_on_hand,
      v_menu.stock_reserved, v_menu.stock_reserved + v_qty,
      'order_reserve', p_order_id,
      'Reservasi stok otomatis untuk pesanan ' || p_order_id,
      v_uid
    );

    UPDATE public.cafe_menus
       SET stock_reserved = stock_reserved + v_qty,
           updated_at = now()
     WHERE id = v_menu.id;

    INSERT INTO public.cafe_order_items (
      order_id, product_id, product_name_snapshot, sku_snapshot,
      unit_price_snapshot, cost_price_snapshot, quantity,
      modifiers_json, line_subtotal
    )
    VALUES (
      p_order_id, v_menu.id, v_menu.name, v_menu.sku,
      v_unit_price, v_menu.cost_price, v_qty,
      v_modifiers, v_line_subtotal
    );
  END LOOP;

  -- PB1 10% tax consistent with CafeOrderTicket domain logic
  v_tax := round(v_subtotal * 0.10)::integer;
  v_grand_total := v_subtotal + v_tax;

  UPDATE public.cafe_orders
     SET subtotal = v_subtotal,
         tax_amount = v_tax,
         grand_total = v_grand_total,
         updated_at = now()
   WHERE order_id = p_order_id;

  RETURN jsonb_build_object(
    'order_id', p_order_id,
    'queue_number', p_queue_number,
    'subtotal', v_subtotal,
    'tax_amount', v_tax,
    'grand_total', v_grand_total,
    'payment_status', 'pending',
    'expires_at', v_expires_at
  );
END;
$$;

-- 7.3 Finalize Payment & Convert Stock Reservation into Sale (Idempotent + Row Locked)
CREATE OR REPLACE FUNCTION public.rpc_finalize_payment_stock(
  p_payment_id UUID,
  p_dedup_key TEXT,
  p_payload_sha256 TEXT,
  p_midtrans_transaction_id TEXT,
  p_midtrans_order_id TEXT,
  p_transaction_status TEXT,
  p_fraud_status TEXT,
  p_status_code TEXT,
  p_signature_verified BOOLEAN,
  p_is_simulation BOOLEAN,
  p_payload_sanitized JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payment RECORD;
  v_order RECORD;
  v_item RECORD;
  v_menu RECORD;
BEGIN
  -- Lock the payment row first to serialize concurrent webhooks
  SELECT p.*
    INTO v_payment
    FROM public.payments p
   WHERE p.id = p_payment_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found: %', p_payment_id;
  END IF;

  -- Strict simulator isolation: simulator can NEVER finalize a non-simulation payment
  IF p_is_simulation AND (NOT v_payment.is_simulation OR v_payment.provider <> 'sandbox_simulator') THEN
    RAISE EXCEPTION 'Security violation: simulator event cannot modify real payment %', p_payment_id;
  END IF;

  -- Record webhook event idempotently via uq_payment_events (dedup_key)
  INSERT INTO public.payment_events (
    payment_id, dedup_key, payload_sha256,
    midtrans_transaction_id, midtrans_order_id,
    transaction_status, fraud_status, status_code,
    signature_verified, is_simulation, payload_sanitized
  )
  VALUES (
    p_payment_id, p_dedup_key, p_payload_sha256,
    p_midtrans_transaction_id, p_midtrans_order_id,
    p_transaction_status, p_fraud_status, p_status_code,
    p_signature_verified, p_is_simulation, COALESCE(p_payload_sanitized, '{}'::jsonb)
  )
  ON CONFLICT (dedup_key) DO NOTHING;

  -- If already paid, return idempotent success without deducting stock twice
  IF v_payment.status = 'paid' THEN
    RETURN jsonb_build_object(
      'status', 'already_paid',
      'order_id', v_payment.order_id,
      'payment_id', v_payment.id
    );
  END IF;

  -- Validate allowed state transition (only pending -> paid)
  IF v_payment.status <> 'pending' THEN
    RAISE EXCEPTION 'Invalid payment state transition from % to paid', v_payment.status;
  END IF;

  SELECT o.*
    INTO v_order
    FROM public.cafe_orders o
   WHERE o.order_id = v_payment.order_id
   FOR UPDATE;

  -- Convert reserved stock into final sale deduction once per item
  FOR v_item IN
    SELECT oi.product_id, oi.quantity
      FROM public.cafe_order_items oi
     WHERE oi.order_id = v_payment.order_id
     ORDER BY oi.product_id ASC
  LOOP
    SELECT m.*
      INTO v_menu
      FROM public.cafe_menus m
     WHERE m.id = v_item.product_id
     FOR UPDATE;

    IF v_menu.stock_on_hand < v_item.quantity OR v_menu.stock_reserved < v_item.quantity THEN
      RAISE EXCEPTION 'Stock reconciliation conflict on product % (on_hand=%, reserved=%, qty=%)',
        v_menu.id, v_menu.stock_on_hand, v_menu.stock_reserved, v_item.quantity;
    END IF;

    INSERT INTO public.inventory_movements (
      product_id, movement_type, quantity_delta,
      stock_before, stock_after, reserved_before, reserved_after,
      reference_type, reference_id, reason
    )
    VALUES (
      v_menu.id, 'sale', -v_item.quantity,
      v_menu.stock_on_hand, v_menu.stock_on_hand - v_item.quantity,
      v_menu.stock_reserved, v_menu.stock_reserved - v_item.quantity,
      'payment_settled', v_payment.order_id,
      'Penjualan selesai untuk pesanan ' || v_payment.order_id
    );

    UPDATE public.cafe_menus
       SET stock_on_hand = stock_on_hand - v_item.quantity,
           stock_reserved = stock_reserved - v_item.quantity,
           updated_at = now()
     WHERE id = v_menu.id;
  END LOOP;

  UPDATE public.payments
     SET status = 'paid',
         midtrans_transaction_id = COALESCE(p_midtrans_transaction_id, midtrans_transaction_id),
         verified_by_webhook = p_signature_verified,
         paid_at = now(),
         updated_at = now()
   WHERE id = v_payment.id;

  UPDATE public.cafe_orders
     SET payment_status = 'paid',
         amount_paid = grand_total,
         status = CASE WHEN status IN ('draft', 'confirmed') THEN 'preparing' ELSE status END,
         is_simulation = v_payment.is_simulation,
         paid_at = now(),
         updated_at = now()
   WHERE order_id = v_payment.order_id;

  PERFORM public.write_audit_log(
    'payment_settled',
    'cafe_orders',
    v_payment.order_id,
    jsonb_build_object('payment_status', v_order.payment_status),
    jsonb_build_object('payment_status', 'paid', 'amount', v_payment.gross_amount, 'is_simulation', v_payment.is_simulation),
    jsonb_build_object('payment_id', v_payment.id, 'provider', v_payment.provider)
  );

  RETURN jsonb_build_object(
    'status', 'paid',
    'order_id', v_payment.order_id,
    'payment_id', v_payment.id
  );
END;
$$;

-- 7.4 Release Stock Reservation on Failed / Expired / Cancelled Payment
CREATE OR REPLACE FUNCTION public.rpc_release_stock_reservation(
  p_order_id TEXT,
  p_target_status TEXT,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order RECORD;
  v_item RECORD;
  v_menu RECORD;
BEGIN
  IF p_target_status NOT IN ('failed', 'expired', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid release target status: %', p_target_status;
  END IF;

  SELECT o.*
    INTO v_order
    FROM public.cafe_orders o
   WHERE o.order_id = p_order_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  IF v_order.payment_status = 'paid' THEN
    RAISE EXCEPTION 'Cannot release reservation of an already paid order %', p_order_id;
  END IF;

  IF v_order.payment_status IN ('failed', 'expired', 'cancelled') THEN
    RETURN jsonb_build_object('status', v_order.payment_status, 'order_id', p_order_id);
  END IF;

  FOR v_item IN
    SELECT oi.product_id, oi.quantity
      FROM public.cafe_order_items oi
     WHERE oi.order_id = p_order_id
     ORDER BY oi.product_id ASC
  LOOP
    SELECT m.*
      INTO v_menu
      FROM public.cafe_menus m
     WHERE m.id = v_item.product_id
     FOR UPDATE;

    IF FOUND AND v_menu.stock_reserved >= v_item.quantity THEN
      INSERT INTO public.inventory_movements (
        product_id, movement_type, quantity_delta,
        stock_before, stock_after, reserved_before, reserved_after,
        reference_type, reference_id, reason, created_by
      )
      VALUES (
        v_menu.id, 'release', 0,
        v_menu.stock_on_hand, v_menu.stock_on_hand,
        v_menu.stock_reserved, v_menu.stock_reserved - v_item.quantity,
        'order_' || p_target_status, p_order_id,
        COALESCE(p_reason, 'Pelepasan reservasi stok pesanan ' || p_order_id),
        auth.uid()
      )
      ON CONFLICT (reference_type, reference_id, product_id, movement_type) DO NOTHING;

      IF FOUND THEN
        UPDATE public.cafe_menus
           SET stock_reserved = stock_reserved - v_item.quantity,
               updated_at = now()
         WHERE id = v_menu.id;
      END IF;
    END IF;
  END LOOP;

  UPDATE public.cafe_orders
     SET payment_status = p_target_status,
         status = 'cancelled',
         cancelled_at = now(),
         updated_at = now()
   WHERE order_id = p_order_id;

  UPDATE public.payments
     SET status = p_target_status,
         updated_at = now()
   WHERE order_id = p_order_id
     AND status = 'pending';

  RETURN jsonb_build_object('status', p_target_status, 'order_id', p_order_id);
END;
$$;

-- 7.5 Admin Stock Opname & Inventory Adjustment RPC (Strict ADMIN Only)
CREATE OR REPLACE FUNCTION public.rpc_admin_adjust_stock(
  p_product_id TEXT,
  p_movement_type TEXT,
  p_quantity_delta INTEGER,
  p_reason TEXT,
  p_reference_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_menu RECORD;
  v_new_stock INTEGER;
  v_ref_id TEXT := COALESCE(p_reference_id, gen_random_uuid()::text);
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden: only ADMIN can adjust inventory or perform stock opname.';
  END IF;

  IF p_movement_type NOT IN ('initial_opname', 'restock', 'adjustment_in', 'adjustment_out', 'damage', 'loss') THEN
    RAISE EXCEPTION 'Invalid admin movement_type: %', p_movement_type;
  END IF;

  IF char_length(trim(COALESCE(p_reason, ''))) < 3 THEN
    RAISE EXCEPTION 'Validation error: reason is mandatory (min 3 characters).';
  END IF;

  SELECT m.*
    INTO v_menu
    FROM public.cafe_menus m
   WHERE m.id = p_product_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found: %', p_product_id;
  END IF;

  IF p_movement_type = 'initial_opname' THEN
    IF p_quantity_delta < 0 THEN
      RAISE EXCEPTION 'Initial stock opname quantity cannot be negative.';
    END IF;
    v_new_stock := p_quantity_delta;
  ELSE
    IF NOT v_menu.is_stock_initialized THEN
      RAISE EXCEPTION 'Produk "%" wajib menjalani Stock Opname Awal terlebih dahulu.', v_menu.name;
    END IF;
    IF p_movement_type IN ('adjustment_out', 'damage', 'loss') AND p_quantity_delta > 0 THEN
      v_new_stock := v_menu.stock_on_hand - p_quantity_delta;
    ELSE
      v_new_stock := v_menu.stock_on_hand + p_quantity_delta;
    END IF;
  END IF;

  IF v_new_stock < 0 THEN
    RAISE EXCEPTION 'Stok setelah penyesuaian tidak boleh negatif (hasil: %).', v_new_stock;
  END IF;

  IF v_new_stock < v_menu.stock_reserved THEN
    RAISE EXCEPTION 'Stok fisik (%) tidak boleh lebih kecil dari stok yang sedang direservasi (%).',
      v_new_stock, v_menu.stock_reserved;
  END IF;

  INSERT INTO public.inventory_movements (
    product_id, movement_type, quantity_delta,
    stock_before, stock_after, reserved_before, reserved_after,
    reference_type, reference_id, reason, created_by
  )
  VALUES (
    v_menu.id,
    p_movement_type,
    v_new_stock - v_menu.stock_on_hand,
    v_menu.stock_on_hand,
    v_new_stock,
    v_menu.stock_reserved,
    v_menu.stock_reserved,
    'admin_' || p_movement_type,
    v_ref_id,
    trim(p_reason),
    v_uid
  );

  UPDATE public.cafe_menus
     SET stock_on_hand = v_new_stock,
         is_stock_initialized = true,
         updated_by = v_uid,
         updated_at = now()
   WHERE id = v_menu.id;

  PERFORM public.write_audit_log(
    'inventory_' || p_movement_type,
    'cafe_menus',
    v_menu.id,
    jsonb_build_object(
      'product_name', v_menu.name,
      'stock_on_hand', v_menu.stock_on_hand,
      'is_stock_initialized', v_menu.is_stock_initialized
    ),
    jsonb_build_object(
      'product_name', v_menu.name,
      'stock_on_hand', v_new_stock,
      'is_stock_initialized', true,
      'reason', trim(p_reason)
    ),
    jsonb_build_object('movement_type', p_movement_type, 'reference_id', v_ref_id)
  );

  RETURN jsonb_build_object(
    'product_id', v_menu.id,
    'product_name', v_menu.name,
    'stock_before', v_menu.stock_on_hand,
    'stock_after', v_new_stock,
    'stock_reserved', v_menu.stock_reserved,
    'available_stock', v_new_stock - v_menu.stock_reserved,
    'is_stock_initialized', true
  );
END;
$$;

-- 7.6 Cashier Complete Cash Payment RPC (Strictly for 'cash' payment method)
CREATE OR REPLACE FUNCTION public.rpc_cashier_complete_cash_order(
  p_order_id TEXT,
  p_amount_received INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
  v_payment_id UUID;
  v_change INTEGER;
BEGIN
  IF NOT public.is_cashier_or_admin() THEN
    RAISE EXCEPTION 'Forbidden: only CASHIER or ADMIN can process cash payments.';
  END IF;

  SELECT o.*
    INTO v_order
    FROM public.cafe_orders o
   WHERE o.order_id = p_order_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  IF v_order.payment_method <> 'cash' THEN
    RAISE EXCEPTION 'Forbidden: QRIS order % cannot be settled as cash by cashier.', p_order_id;
  END IF;

  IF v_order.payment_status = 'paid' THEN
    RETURN jsonb_build_object('status', 'already_paid', 'order_id', p_order_id);
  END IF;

  IF p_amount_received < v_order.grand_total THEN
    RAISE EXCEPTION 'Nominal uang tunai (%) kurang dari total tagihan (%).',
      p_amount_received, v_order.grand_total;
  END IF;

  v_change := p_amount_received - v_order.grand_total;

  INSERT INTO public.payments (
    order_id, provider, is_simulation, payment_method,
    idempotency_key, gross_amount, status, created_by
  )
  VALUES (
    p_order_id, 'cash', false, 'cash',
    'cash:' || p_order_id, v_order.grand_total, 'pending', v_uid
  )
  ON CONFLICT (idempotency_key) DO UPDATE SET
    updated_at = now()
  RETURNING id INTO v_payment_id;

  PERFORM public.rpc_finalize_payment_stock(
    v_payment_id,
    'cash_settle:' || p_order_id,
    encode(extensions.digest(p_order_id || ':' || p_amount_received::text, 'sha256'), 'hex'),
    'CASH-' || p_order_id,
    p_order_id,
    'settlement',
    'accept',
    '200',
    true,
    false,
    jsonb_build_object('amount_received', p_amount_received, 'change_amount', v_change, 'cashier_id', v_uid)
  );

  UPDATE public.cafe_orders
     SET amount_paid = p_amount_received,
         change_amount = v_change,
         cashier_id = COALESCE(cashier_id, v_uid),
         updated_at = now()
   WHERE order_id = p_order_id;

  RETURN jsonb_build_object(
    'status', 'paid',
    'order_id', p_order_id,
    'amount_paid', p_amount_received,
    'change_amount', v_change
  );
END;
$$;

-- 7.7 Cashier Advance Order Workflow Status RPC
CREATE OR REPLACE FUNCTION public.rpc_cashier_advance_order_status(
  p_order_id TEXT,
  p_new_status TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
BEGIN
  IF NOT public.is_cashier_or_admin() THEN
    RAISE EXCEPTION 'Forbidden: only CASHIER or ADMIN can update order workflow status.';
  END IF;

  IF p_new_status NOT IN ('preparing', 'readyForPickup', 'completed', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid target order status: %', p_new_status;
  END IF;

  SELECT o.*
    INTO v_order
    FROM public.cafe_orders o
   WHERE o.order_id = p_order_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  IF p_new_status IN ('preparing', 'readyForPickup', 'completed') AND v_order.payment_status <> 'paid' THEN
    RAISE EXCEPTION 'Pesanan % belum lunas (status pembayaran: %). Tidak dapat diproses ke tahap %.',
      p_order_id, v_order.payment_status, p_new_status;
  END IF;

  IF p_new_status = 'cancelled' AND v_order.payment_status = 'pending' THEN
    RETURN public.rpc_release_stock_reservation(p_order_id, 'cancelled', 'Dibatalkan oleh kasir/admin');
  END IF;

  UPDATE public.cafe_orders
     SET status = p_new_status,
         cashier_id = COALESCE(cashier_id, v_uid),
         completed_by = CASE WHEN p_new_status = 'completed' THEN v_uid ELSE completed_by END,
         updated_at = now()
   WHERE order_id = p_order_id;

  PERFORM public.write_audit_log(
    'order_status_' || p_new_status,
    'cafe_orders',
    p_order_id,
    jsonb_build_object('status', v_order.status),
    jsonb_build_object('status', p_new_status),
    jsonb_build_object('queue_number', v_order.queue_number)
  );

  RETURN jsonb_build_object(
    'order_id', p_order_id,
    'previous_status', v_order.status,
    'new_status', p_new_status
  );
END;
$$;

-- 7.8 Admin Financial & Operational Dashboard Metrics (Timezone: Asia/Jakarta)
CREATE OR REPLACE FUNCTION public.rpc_admin_dashboard_metrics(
  p_start_date DATE,
  p_end_date DATE,
  p_tz TEXT DEFAULT 'Asia/Jakarta',
  p_include_simulations BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_gross_sales BIGINT := 0;
  v_refunded_amount BIGINT := 0;
  v_net_sales BIGINT := 0;
  v_success_count INTEGER := 0;
  v_pending_count INTEGER := 0;
  v_failed_count INTEGER := 0;
  v_aov BIGINT := 0;
  v_units_sold INTEGER := 0;
  v_qris_count INTEGER := 0;
  v_qris_sales BIGINT := 0;
  v_cash_count INTEGER := 0;
  v_cash_sales BIGINT := 0;
  v_missing_cost_count INTEGER := 0;
  v_total_cogs BIGINT := 0;
  v_has_complete_cost BOOLEAN := false;
  v_net_profit BIGINT := NULL;
  v_daily_series JSONB := '[]'::jsonb;
  v_top_products JSONB := '[]'::jsonb;
  v_stock_summary JSONB := '{}'::jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden: only ADMIN can access revenue and analytics metrics.';
  END IF;

  -- 1. Order & Payment Summary within Asia/Jakarta date range
  SELECT
    COALESCE(SUM(o.grand_total) FILTER (WHERE o.payment_status IN ('paid', 'refunded', 'partially_refunded')), 0),
    COUNT(*) FILTER (WHERE o.payment_status IN ('paid', 'refunded', 'partially_refunded')),
    COUNT(*) FILTER (WHERE o.payment_status = 'pending'),
    COUNT(*) FILTER (WHERE o.payment_status IN ('failed', 'expired', 'cancelled')),
    COUNT(*) FILTER (WHERE o.payment_status IN ('paid', 'refunded', 'partially_refunded') AND o.payment_method = 'qris'),
    COALESCE(SUM(o.grand_total) FILTER (WHERE o.payment_status IN ('paid', 'refunded', 'partially_refunded') AND o.payment_method = 'qris'), 0),
    COUNT(*) FILTER (WHERE o.payment_status IN ('paid', 'refunded', 'partially_refunded') AND o.payment_method = 'cash'),
    COALESCE(SUM(o.grand_total) FILTER (WHERE o.payment_status IN ('paid', 'refunded', 'partially_refunded') AND o.payment_method = 'cash'), 0)
  INTO
    v_gross_sales, v_success_count, v_pending_count, v_failed_count,
    v_qris_count, v_qris_sales, v_cash_count, v_cash_sales
  FROM public.cafe_orders o
  WHERE (p_include_simulations OR NOT o.is_simulation)
    AND ((COALESCE(o.paid_at, o.created_at) AT TIME ZONE p_tz)::date BETWEEN p_start_date AND p_end_date);

  -- 2. Completed Refunds in period
  SELECT COALESCE(SUM(r.amount), 0)
    INTO v_refunded_amount
    FROM public.refunds r
    JOIN public.cafe_orders o ON o.order_id = r.order_id
   WHERE r.status = 'completed'
     AND (p_include_simulations OR NOT o.is_simulation)
     AND ((COALESCE(r.completed_at, r.created_at) AT TIME ZONE p_tz)::date BETWEEN p_start_date AND p_end_date);

  v_net_sales := GREATEST(v_gross_sales - v_refunded_amount, 0);
  IF v_success_count > 0 THEN
    v_aov := v_net_sales / v_success_count;
  END IF;

  -- 3. Units sold & COGS check from immutable snapshot items of paid orders (excluding fully refunded)
  SELECT
    COALESCE(SUM(oi.quantity), 0),
    COUNT(*) FILTER (WHERE oi.cost_price_snapshot IS NULL),
    COALESCE(SUM(oi.cost_price_snapshot * oi.quantity), 0)
  INTO
    v_units_sold, v_missing_cost_count, v_total_cogs
  FROM public.cafe_order_items oi
  JOIN public.cafe_orders o ON o.order_id = oi.order_id
  WHERE o.payment_status = 'paid'
    AND (p_include_simulations OR NOT o.is_simulation)
    AND ((o.paid_at AT TIME ZONE p_tz)::date BETWEEN p_start_date AND p_end_date);

  IF v_units_sold > 0 AND v_missing_cost_count = 0 THEN
    v_has_complete_cost := true;
    v_net_profit := v_net_sales - v_total_cogs;
  END IF;

  -- 4. Daily series (Asia/Jakarta)
  SELECT COALESCE(jsonb_agg(row_to_json(d) ORDER BY d.report_date ASC), '[]'::jsonb)
    INTO v_daily_series
    FROM (
      SELECT
        gs.day::date AS report_date,
        COALESCE(SUM(o.grand_total) FILTER (WHERE o.payment_status = 'paid'), 0) AS gross_sales,
        COUNT(o.order_id) FILTER (WHERE o.payment_status = 'paid') AS transaction_count
      FROM generate_series(p_start_date::timestamp, p_end_date::timestamp, interval '1 day') AS gs(day)
      LEFT JOIN public.cafe_orders o
        ON (o.paid_at AT TIME ZONE p_tz)::date = gs.day::date
       AND o.payment_status = 'paid'
       AND (p_include_simulations OR NOT o.is_simulation)
      GROUP BY gs.day::date
    ) d;

  -- 5. Top selling products (only paid orders, using snapshot prices)
  SELECT COALESCE(jsonb_agg(row_to_json(tp)), '[]'::jsonb)
    INTO v_top_products
    FROM (
      SELECT
        oi.product_id,
        oi.product_name_snapshot AS product_name,
        SUM(oi.quantity)::integer AS units_sold,
        SUM(oi.line_subtotal)::bigint AS total_revenue,
        CASE WHEN v_gross_sales > 0
             THEN round((SUM(oi.line_subtotal)::numeric / v_gross_sales::numeric) * 100, 1)
             ELSE 0
        END AS revenue_share_percent
      FROM public.cafe_order_items oi
      JOIN public.cafe_orders o ON o.order_id = oi.order_id
      WHERE o.payment_status = 'paid'
        AND (p_include_simulations OR NOT o.is_simulation)
        AND ((o.paid_at AT TIME ZONE p_tz)::date BETWEEN p_start_date AND p_end_date)
      GROUP BY oi.product_id, oi.product_name_snapshot
      ORDER BY units_sold DESC, total_revenue DESC
      LIMIT 10
    ) tp;

  -- 6. Stock health summary
  SELECT jsonb_build_object(
    'active_products', COUNT(*) FILTER (WHERE NOT m.is_archived AND m.is_available),
    'uninitialized_count', COUNT(*) FILTER (WHERE NOT m.is_archived AND NOT m.is_stock_initialized),
    'total_available_stock', COALESCE(SUM(m.stock_on_hand - m.stock_reserved) FILTER (WHERE NOT m.is_archived AND m.is_stock_initialized), 0),
    'out_of_stock_count', COUNT(*) FILTER (WHERE NOT m.is_archived AND m.is_stock_initialized AND (m.stock_on_hand - m.stock_reserved) <= 0),
    'low_stock_count', COUNT(*) FILTER (WHERE NOT m.is_archived AND m.is_stock_initialized AND (m.stock_on_hand - m.stock_reserved) > 0 AND (m.stock_on_hand - m.stock_reserved) <= m.low_stock_threshold)
  )
  INTO v_stock_summary
  FROM public.cafe_menus m;

  RETURN jsonb_build_object(
    'timezone', p_tz,
    'start_date', p_start_date,
    'end_date', p_end_date,
    'gross_sales', v_gross_sales,
    'refunded_amount', v_refunded_amount,
    'net_sales', v_net_sales,
    'success_count', v_success_count,
    'pending_count', v_pending_count,
    'failed_count', v_failed_count,
    'average_order_value', v_aov,
    'units_sold', v_units_sold,
    'qris_count', v_qris_count,
    'qris_sales', v_qris_sales,
    'cash_count', v_cash_count,
    'cash_sales', v_cash_sales,
    'has_complete_cost_data', v_has_complete_cost,
    'net_profit', v_net_profit,
    'daily_series', v_daily_series,
    'top_products', v_top_products,
    'stock_summary', v_stock_summary
  );
END;
$$;

-- =============================================================================
-- 8. ROW LEVEL SECURITY (RLS) HARDENING ACROSS ALL TABLES
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.low_stock_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sign_language_videos ENABLE ROW LEVEL SECURITY;

-- 8.1 profiles policies
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "profiles_update_own_safe" ON public.profiles;
CREATE POLICY "profiles_update_own_safe" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid() AND status = 'active')
  WITH CHECK (id = auth.uid() AND status = 'active');

-- 8.2 audit_logs policies (Strictly ADMIN read; no client insert/update/delete)
DROP POLICY IF EXISTS "audit_logs_admin_select" ON public.audit_logs;
CREATE POLICY "audit_logs_admin_select" ON public.audit_logs
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- 8.3 product_categories policies
DROP POLICY IF EXISTS "product_categories_select_all" ON public.product_categories;
CREATE POLICY "product_categories_select_all" ON public.product_categories
  FOR SELECT TO anon, authenticated
  USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "product_categories_admin_insert" ON public.product_categories;
CREATE POLICY "product_categories_admin_insert" ON public.product_categories
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "product_categories_admin_update" ON public.product_categories;
CREATE POLICY "product_categories_admin_update" ON public.product_categories
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "product_categories_admin_delete" ON public.product_categories;
CREATE POLICY "product_categories_admin_delete" ON public.product_categories
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- 8.4 cafe_menus policies (Replace insecure anon write policies!)
DROP POLICY IF EXISTS "cafe_menus_select_policy" ON public.cafe_menus;
DROP POLICY IF EXISTS "cafe_menus_insert_policy" ON public.cafe_menus;
DROP POLICY IF EXISTS "cafe_menus_update_policy" ON public.cafe_menus;
DROP POLICY IF EXISTS "cafe_menus_delete_policy" ON public.cafe_menus;

CREATE POLICY "cafe_menus_select_v3" ON public.cafe_menus
  FOR SELECT TO anon, authenticated
  USING ((NOT is_archived) OR public.is_admin());

CREATE POLICY "cafe_menus_admin_insert_v3" ON public.cafe_menus
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "cafe_menus_admin_update_v3" ON public.cafe_menus
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "cafe_menus_admin_delete_v3" ON public.cafe_menus
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- 8.5 inventory_movements & low_stock_reports policies
DROP POLICY IF EXISTS "inventory_movements_admin_select" ON public.inventory_movements;
CREATE POLICY "inventory_movements_admin_select" ON public.inventory_movements
  FOR SELECT TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "low_stock_reports_select" ON public.low_stock_reports;
CREATE POLICY "low_stock_reports_select" ON public.low_stock_reports
  FOR SELECT TO authenticated
  USING (public.is_cashier_or_admin());

DROP POLICY IF EXISTS "low_stock_reports_cashier_insert" ON public.low_stock_reports;
CREATE POLICY "low_stock_reports_cashier_insert" ON public.low_stock_reports
  FOR INSERT TO authenticated
  WITH CHECK (public.is_cashier_or_admin() AND reported_by = auth.uid());

DROP POLICY IF EXISTS "low_stock_reports_admin_update" ON public.low_stock_reports;
CREATE POLICY "low_stock_reports_admin_update" ON public.low_stock_reports
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 8.6 cafe_orders & cafe_order_items policies (Replace insecure anon policies!)
DROP POLICY IF EXISTS "cafe_orders_select_policy" ON public.cafe_orders;
DROP POLICY IF EXISTS "cafe_orders_insert_policy" ON public.cafe_orders;
DROP POLICY IF EXISTS "cafe_orders_update_policy" ON public.cafe_orders;
DROP POLICY IF EXISTS "cafe_orders_delete_policy" ON public.cafe_orders;

CREATE POLICY "cafe_orders_select_v3" ON public.cafe_orders
  FOR SELECT TO authenticated
  USING (
    customer_id = auth.uid() OR
    public.is_cashier_or_admin()
  );

CREATE POLICY "cafe_order_items_select_v3" ON public.cafe_order_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.cafe_orders o
      WHERE o.order_id = cafe_order_items.order_id
        AND (o.customer_id = auth.uid() OR public.is_cashier_or_admin())
    )
  );

-- 8.7 payments, payment_events, refunds policies
CREATE POLICY "payments_select_v3" ON public.payments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.cafe_orders o
      WHERE o.order_id = payments.order_id
        AND (o.customer_id = auth.uid() OR public.is_cashier_or_admin())
    )
  );

CREATE POLICY "payment_events_admin_select" ON public.payment_events
  FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY "refunds_select_v3" ON public.refunds
  FOR SELECT TO authenticated
  USING (
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM public.cafe_orders o
      WHERE o.order_id = refunds.order_id
        AND (o.customer_id = auth.uid() OR public.is_cashier())
    )
  );

-- 8.8 sign_language_videos policies (CUSTOMER sees only published; ADMIN sees all & mutates)
CREATE POLICY "sign_videos_select_published_or_admin" ON public.sign_language_videos
  FOR SELECT TO anon, authenticated
  USING (
    publication_status = 'published' OR
    public.is_admin()
  );

CREATE POLICY "sign_videos_admin_insert" ON public.sign_language_videos
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "sign_videos_admin_update" ON public.sign_language_videos
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "sign_videos_admin_delete" ON public.sign_language_videos
  FOR DELETE TO authenticated
  USING (public.is_admin());

-- 8.9 counter_sessions policies (Restrict write to CASHIER/ADMIN)
DROP POLICY IF EXISTS "counter_sessions_select_policy" ON public.counter_sessions;
DROP POLICY IF EXISTS "counter_sessions_insert_policy" ON public.counter_sessions;
DROP POLICY IF EXISTS "counter_sessions_update_policy" ON public.counter_sessions;
DROP POLICY IF EXISTS "counter_sessions_delete_policy" ON public.counter_sessions;

CREATE POLICY "counter_sessions_select_v3" ON public.counter_sessions
  FOR SELECT TO authenticated
  USING (public.is_active_user());

CREATE POLICY "counter_sessions_staff_write_v3" ON public.counter_sessions
  FOR ALL TO authenticated
  USING (public.is_cashier_or_admin())
  WITH CHECK (public.is_cashier_or_admin());

-- =============================================================================
-- 9. SUPABASE STORAGE BUCKETS & RLS POLICIES
-- =============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'sign-language-videos',
  'sign-language-videos',
  false, -- Private bucket: draft videos cannot be accessed by customers; published served via signed URLs
  52428800, -- 50 MB max
  ARRAY['video/mp4', 'video/webm', 'image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Lock down menu-photos mutations to ADMIN only (keep public read)
DROP POLICY IF EXISTS "menu_photos_public_insert" ON storage.objects;
DROP POLICY IF EXISTS "menu_photos_public_update" ON storage.objects;
DROP POLICY IF EXISTS "menu_photos_public_delete" ON storage.objects;

CREATE POLICY "menu_photos_admin_insert_v3" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'menu-photos' AND public.is_admin());

CREATE POLICY "menu_photos_admin_update_v3" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'menu-photos' AND public.is_admin())
  WITH CHECK (bucket_id = 'menu-photos' AND public.is_admin());

CREATE POLICY "menu_photos_admin_delete_v3" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'menu-photos' AND public.is_admin());

-- Lock down legacy sign-videos bucket mutations to ADMIN only
DROP POLICY IF EXISTS "sign_videos_public_insert" ON storage.objects;
DROP POLICY IF EXISTS "sign_videos_public_update" ON storage.objects;

CREATE POLICY "sign_videos_admin_insert_v3" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'sign-videos' AND public.is_admin());

CREATE POLICY "sign_videos_admin_update_v3" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'sign-videos' AND public.is_admin())
  WITH CHECK (bucket_id = 'sign-videos' AND public.is_admin());

CREATE POLICY "sign_videos_admin_delete_v3" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'sign-videos' AND public.is_admin());

-- Policies for private bucket sign-language-videos:
-- ADMIN has full CRUD; authenticated users can SELECT only objects linked to a 'published' row.
DROP POLICY IF EXISTS "sign_lang_videos_select_published_or_admin" ON storage.objects;
CREATE POLICY "sign_lang_videos_select_published_or_admin" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'sign-language-videos' AND (
      public.is_admin() OR
      EXISTS (
        SELECT 1 FROM public.sign_language_videos v
        WHERE v.storage_bucket = 'sign-language-videos'
          AND (v.storage_path = storage.objects.name OR v.thumbnail_path = storage.objects.name)
          AND v.publication_status = 'published'
      )
    )
  );

DROP POLICY IF EXISTS "sign_lang_videos_admin_insert" ON storage.objects;
CREATE POLICY "sign_lang_videos_admin_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'sign-language-videos' AND public.is_admin());

DROP POLICY IF EXISTS "sign_lang_videos_admin_update" ON storage.objects;
CREATE POLICY "sign_lang_videos_admin_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'sign-language-videos' AND public.is_admin())
  WITH CHECK (bucket_id = 'sign-language-videos' AND public.is_admin());

DROP POLICY IF EXISTS "sign_lang_videos_admin_delete" ON storage.objects;
CREATE POLICY "sign_lang_videos_admin_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'sign-language-videos' AND public.is_admin());

-- =============================================================================
-- 10. REALTIME PUBLICATIONS FOR NEW OPERATIONAL TABLES
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'payments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'low_stock_reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.low_stock_reports;
  END IF;
END $$;

COMMIT;
