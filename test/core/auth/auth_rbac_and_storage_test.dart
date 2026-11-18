import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/auth/controllers/auth_controller.dart';
import 'package:speech2sign/core/auth/middlewares/role_guard_middleware.dart';
import 'package:speech2sign/core/auth/models/app_user_role.dart';
import 'package:speech2sign/core/auth/models/user_profile.dart';
import 'package:speech2sign/core/auth/services/secure_supabase_storage.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/auth/screens/login_screen.dart';
import 'package:speech2sign/features/auth/screens/register_customer_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    AppTranslations.ensureLoaded();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('AppUserRole & Least Privilege Permissions', () {
    test('parses only customer, cashier, admin and defaults unknown to customer', () {
      expect(AppUserRole.fromString('customer'), AppUserRole.customer);
      expect(AppUserRole.fromString('CASHIER'), AppUserRole.cashier);
      expect(AppUserRole.fromString('admin'), AppUserRole.admin);
      expect(AppUserRole.fromString('superadmin'), AppUserRole.customer);
      expect(AppUserRole.fromString(null), AppUserRole.customer);
    });

    test('enforces least privilege capability flags per role', () {
      expect(AppUserRole.customer.canAccessCustomerFlow, isTrue);
      expect(AppUserRole.customer.canAccessCashierDashboard, isFalse);
      expect(AppUserRole.customer.canAccessAdminDashboard, isFalse);
      expect(AppUserRole.customer.canMutateMasterCatalog, isFalse);
      expect(AppUserRole.customer.canAdjustStock, isFalse);
      expect(AppUserRole.customer.canManageSignVideos, isFalse);
      expect(AppUserRole.customer.canManageStaff, isFalse);
      expect(AppUserRole.customer.canViewBusinessFinancials, isFalse);
      expect(AppUserRole.customer.canViewAuditLogs, isFalse);

      expect(AppUserRole.cashier.canAccessCashierDashboard, isTrue);
      expect(AppUserRole.cashier.canReportLowStock, isTrue);
      expect(AppUserRole.cashier.canAccessAdminDashboard, isFalse);
      expect(AppUserRole.cashier.canMutateMasterCatalog, isFalse);
      expect(AppUserRole.cashier.canAdjustStock, isFalse);
      expect(AppUserRole.cashier.canManageSignVideos, isFalse);
      expect(AppUserRole.cashier.canManageStaff, isFalse);
      expect(AppUserRole.cashier.canViewBusinessFinancials, isFalse);
      expect(AppUserRole.cashier.canViewAuditLogs, isFalse);

      expect(AppUserRole.admin.canAccessAdminDashboard, isTrue);
      expect(AppUserRole.admin.canMutateMasterCatalog, isTrue);
      expect(AppUserRole.admin.canAdjustStock, isTrue);
      expect(AppUserRole.admin.canManageSignVideos, isTrue);
      expect(AppUserRole.admin.canManageStaff, isTrue);
      expect(AppUserRole.admin.canViewBusinessFinancials, isTrue);
      expect(AppUserRole.admin.canViewAuditLogs, isTrue);
    });
  });

  group('UserProfile Role Escalation Prevention', () {
    test('toSelfEditableMap strips role and status fields to prevent escalation', () {
      final profile = UserProfile(
        id: 'user-123',
        email: 'customer@example.com',
        fullName: 'Budi Santoso',
        phone: '08123456789',
        role: AppUserRole.customer,
        status: AccountStatus.active,
        communicationMode: 'deaf',
        preferredSignSystem: 'BISINDO',
        createdAt: DateTime.utc(2026, 11, 18),
        updatedAt: DateTime.utc(2026, 11, 18),
      );

      final editable = profile.toSelfEditableMap();
      expect(editable.containsKey('role'), isFalse);
      expect(editable.containsKey('status'), isFalse);
      expect(editable.containsKey('id'), isFalse);
      expect(editable['full_name'], 'Budi Santoso');
      expect(editable['communication_mode'], 'deaf');
    });

    test('fromPostgresMap ignores client user_metadata role escalation attempts', () {
      final row = <String, dynamic>{
        'id': 'user-123',
        'email': 'attacker@example.com',
        'full_name': 'Attacker',
        'role': 'customer',
        'status': 'active',
        'user_metadata': {'role': 'admin'},
      };
      final profile = UserProfile.fromPostgresMap(row);
      expect(profile.role, AppUserRole.customer);
      expect(profile.isActive, isTrue);
    });
  });

  group('SecureSupabaseLocalStorage & SecureGotrueAsyncStorage', () {
    test('persists, reads, and removes session and PKCE verifier in secure store', () async {
      final store = InMemorySecureKeyValueStore();
      final localStorage = SecureSupabaseLocalStorage(store: store);
      final pkceStorage = SecureGotrueAsyncStorage(store: store);

      await localStorage.initialize();
      expect(await localStorage.hasAccessToken(), isFalse);
      expect(await localStorage.accessToken(), isNull);

      await localStorage.persistSession('{"access_token":"jwt-xyz"}');
      expect(await localStorage.hasAccessToken(), isTrue);
      expect(await localStorage.accessToken(), '{"access_token":"jwt-xyz"}');

      await pkceStorage.setItem(
        key: 'supabase.auth.token-code-verifier',
        value: 'pkce-secret-verifier-123',
      );
      expect(
        await pkceStorage.getItem(key: 'supabase.auth.token-code-verifier'),
        'pkce-secret-verifier-123',
      );

      await pkceStorage.removeItem(key: 'supabase.auth.token-code-verifier');
      expect(
        await pkceStorage.getItem(key: 'supabase.auth.token-code-verifier'),
        isNull,
      );

      await localStorage.removePersistedSession();
      expect(await localStorage.hasAccessToken(), isFalse);
    });
  });

  group('RoleGuardMiddleware & Instant Disabled Revocation', () {
    test('redirects unauthenticated user to login route', () {
      final authCtrl = Get.put(AuthController());
      expect(authCtrl.isAuthenticated, isFalse);

      final guard = RoleGuardMiddleware(allowedRoles: const [AppUserRole.admin]);
      final redirect = guard.redirect(AppRoutes.adminDashboard);
      expect(redirect?.name, AppRoutes.login);
    });

    test('blocks CUSTOMER from accessing CASHIER and ADMIN routes', () {
      final customerProfile = UserProfile(
        id: 'cust-1',
        email: 'cust@example.com',
        fullName: 'Pelanggan Satu',
        role: AppUserRole.customer,
        status: AccountStatus.active,
        communicationMode: 'deaf',
        preferredSignSystem: 'BISINDO',
        createdAt: DateTime.utc(2026, 11, 18),
        updatedAt: DateTime.utc(2026, 11, 18),
      );
      Get.put(AuthController(initialProfileForTest: customerProfile));

      final adminGuard = RoleGuardMiddleware(allowedRoles: const [AppUserRole.admin]);
      final cashierGuard = RoleGuardMiddleware(allowedRoles: const [AppUserRole.cashier]);
      final customerGuard = RoleGuardMiddleware(allowedRoles: const [AppUserRole.customer]);

      expect(adminGuard.redirect(AppRoutes.adminDashboard)?.name, AppRoutes.mainShell);
      expect(cashierGuard.redirect(AppRoutes.cafeCashierCounter)?.name, AppRoutes.mainShell);
      expect(customerGuard.redirect(AppRoutes.mainShell), isNull);
    });

    test('blocks CASHIER from accessing ADMIN route and redirects disabled cashier to login', () {
      final cashierProfile = UserProfile(
        id: 'cash-1',
        email: 'cashier@example.com',
        fullName: 'Kasir Satu',
        role: AppUserRole.cashier,
        status: AccountStatus.active,
        communicationMode: 'hearing',
        preferredSignSystem: 'BISINDO',
        createdAt: DateTime.utc(2026, 11, 18),
        updatedAt: DateTime.utc(2026, 11, 18),
      );
      final authCtrl = Get.put(AuthController(initialProfileForTest: cashierProfile));

      final adminGuard = RoleGuardMiddleware(allowedRoles: const [AppUserRole.admin]);
      final cashierGuard = RoleGuardMiddleware(allowedRoles: const [AppUserRole.cashier]);

      expect(adminGuard.redirect(AppRoutes.adminDashboard)?.name, AppRoutes.cafeCashierCounter);
      expect(cashierGuard.redirect(AppRoutes.cafeCashierCounter), isNull);

      // Simulate Admin disabling the cashier account in real time
      authCtrl.applyProfileUpdate(
        cashierProfile.copyWith(status: AccountStatus.disabled),
      );
      expect(authCtrl.isAuthenticated, isFalse);
      expect(cashierGuard.redirect(AppRoutes.cafeCashierCounter)?.name, AppRoutes.login);
    });
  });

  group('LoginScreen & RegisterCustomerScreen UI', () {
    testWidgets('LoginScreen validates empty fields and navigates to RegisterCustomerScreen', (tester) async {
      Get.put(AuthController());
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          initialRoute: AppRoutes.login,
          getPages: [
            GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
            GetPage(
              name: AppRoutes.registerCustomer,
              page: () => const RegisterCustomerScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.authLoginTitle.tr), findsOneWidget);
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.authValidationRequired.tr), findsWidgets);

      final regBtn = find.byKey(const Key('go_to_register_button'));
      await tester.ensureVisible(regBtn);
      await tester.tap(regBtn);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.authRegisterCustomerTitle.tr), findsOneWidget);
      // Verify no admin/cashier role radio or option is exposed on public customer registration
      expect(find.text('ADMIN'), findsNothing);
      expect(find.text('CASHIER'), findsNothing);
    });
  });
}
