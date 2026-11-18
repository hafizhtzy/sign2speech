import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Addendum V3 SQL Migration Security & ERP Contract', () {
    late String sql;

    setUpAll(() {
      final file = File(
        'supabase/migrations/20261118000000_three_role_rbac_and_erp_schema.sql',
      );
      expect(file.existsSync(), isTrue);
      sql = file.readAsStringSync();
    });

    test('does not invent default stock_on_hand = 25 and enforces stock opname initialization', () {
      expect(sql.contains('DEFAULT 25'), isFalse);
      expect(
        sql.contains('is_stock_initialized BOOLEAN NOT NULL DEFAULT false'),
        isTrue,
      );
      expect(
        sql.contains('stock_on_hand INTEGER NOT NULL DEFAULT 0'),
        isTrue,
      );
      expect(
        sql.contains('cost_price INTEGER CHECK (cost_price IS NULL OR cost_price >= 0)'),
        isTrue,
      );
      expect(sql.contains("'initial_opname'"), isTrue);
    });

    test('enforces SECURITY DEFINER SET search_path = empty string across all RPCs', () {
      final secDefCount = 'SECURITY DEFINER'.allMatches(sql).length;
      final searchPathCount = "SET search_path = ''".allMatches(sql).length;
      expect(secDefCount, greaterThanOrEqualTo(10));
      expect(searchPathCount, equals(secDefCount));
    });

    test('enforces Midtrans composite dedup_key, payload_sha256, and simulator isolation', () {
      expect(sql.contains('dedup_key TEXT NOT NULL UNIQUE'), isTrue);
      expect(sql.contains('payload_sha256 TEXT NOT NULL'), isTrue);
      expect(sql.contains('chk_payments_simulation_consistency'), isTrue);
      expect(sql.contains('qr_code_url TEXT'), isTrue);
      expect(sql.contains('qris_actions JSONB'), isTrue);
      expect(
        sql.contains(
          'Security violation: simulator event cannot modify real payment',
        ),
        isTrue,
      );
    });

    test('enables RLS on all ERP tables and locks down audit_logs from UPDATE/DELETE', () {
      for (final table in [
        'profiles',
        'audit_logs',
        'product_categories',
        'inventory_movements',
        'low_stock_reports',
        'cafe_order_items',
        'payments',
        'payment_events',
        'refunds',
        'sign_language_videos',
      ]) {
        expect(
          sql.contains('ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY;'),
          isTrue,
          reason: 'Table $table must enable RLS',
        );
      }
      expect(
        sql.contains(
          'REVOKE UPDATE, DELETE, TRUNCATE ON public.audit_logs FROM anon, authenticated;',
        ),
        isTrue,
      );
    });
  });
}
