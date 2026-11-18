import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Addendum V3 Edge Functions & Provisioning Security Contract', () {
    test('auth_guard verifies active profile role directly from public.profiles', () {
      final guard = File('supabase/functions/_shared/auth_guard.ts')
          .readAsStringSync();
      expect(guard.contains("from('profiles')"), isTrue);
      expect(guard.contains("profile.status !== 'active'"), isTrue);
      expect(guard.contains('allowedRoles.includes(role)'), isTrue);
    });

    test('admin-manage-cashier forbids admin creation, bans disabled accounts, and writes audit_logs', () {
      final fn = File('supabase/functions/admin-manage-cashier/index.ts')
          .readAsStringSync();
      expect(fn.contains("requireActiveRole(req, ['admin'])"), isTrue);
      expect(
        fn.contains("String(body.role).toLowerCase() !== 'cashier'"),
        isTrue,
      );
      expect(fn.contains('inviteUserByEmail'), isTrue);
      expect(fn.contains("ban_duration: isDisabling ? '876000h' : 'none'"), isTrue);
      expect(fn.contains("from('audit_logs').insert"), isTrue);
    });

    test('payment-create-qris parses Midtrans Core API actions and isolates simulator from production', () {
      final fn = File('supabase/functions/payment-create-qris/index.ts')
          .readAsStringSync();
      expect(fn.contains("a.name === 'generate-qr-code-v2'"), isTrue);
      expect(fn.contains("a.name === 'generate-qr-code'"), isTrue);
      expect(fn.contains("provider: 'midtrans'"), isTrue);
      expect(fn.contains("provider: 'sandbox_simulator'"), isTrue);
      expect(fn.contains('!isProduction &&'), isTrue);
    });

    test('payment-webhook verifies SHA-512, builds composite dedupKey + sha256, and blocks simulator on real payments', () {
      final fn = File('supabase/functions/payment-webhook/index.ts')
          .readAsStringSync();
      expect(fn.contains('sha512Hex'), isTrue);
      expect(fn.contains('payloadSha256 = await sha256Hex(rawBody)'), isTrue);
      expect(
        fn.contains(
          "if (!payment.is_simulation || payment.provider !== 'sandbox_simulator')",
        ),
        isTrue,
      );
      expect(fn.contains('rpc_finalize_payment_stock'), isTrue);
      expect(fn.contains('rpc_release_stock_reservation'), isTrue);
    });
  });
}
