import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../features/cafe_pos/controllers/cafe_cashier_controller.dart';
import '../../constants/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../models/app_user_role.dart';

/// GetX Route Middleware enforcing Three-Role Authorization (`CUSTOMER`, `CASHIER`, `ADMIN`).
///
/// 1. Unauthenticated or disabled users are redirected to [AppRoutes.login].
/// 2. Authenticated users whose role is not in [allowedRoles] are redirected
///    to their own authorized home dashboard — except when
///    [allowPairedCustomerCounterTablet] is true and a `CUSTOMER` tablet has
///    completed pairing with a Cashier counter room code (`isPairedCustomerSession`).
class RoleGuardMiddleware extends GetMiddleware {
  final List<AppUserRole> allowedRoles;
  final bool? allowUnauthenticatedInWidgetTestOnly;
  final bool? allowPairedCustomerCounterTablet;

  RoleGuardMiddleware({
    required this.allowedRoles,
    this.allowUnauthenticatedInWidgetTestOnly = false,
    this.allowPairedCustomerCounterTablet = false,
    super.priority = 1,
  });

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) {
      if ((allowUnauthenticatedInWidgetTestOnly == true) && Get.testMode) {
        return null;
      }
      return const RouteSettings(name: AppRoutes.login);
    }

    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      if ((allowUnauthenticatedInWidgetTestOnly == true) &&
          Get.testMode &&
          auth.sessionState.value is AuthUnauthenticated) {
        return null;
      }
      return const RouteSettings(name: AppRoutes.login);
    }

    final role = auth.currentRole;
    final canUseCounterPairing =
        (allowPairedCustomerCounterTablet == true) ||
        route == AppRoutes.cafeCashierCounter;
    if (role == AppUserRole.customer && canUseCounterPairing) {
      final isPaired = Get.isRegistered<CafeCashierController>() &&
          Get.find<CafeCashierController>().isPairedCustomerSession.value;
      if (isPaired) {
        return null;
      }
      return const RouteSettings(name: AppRoutes.customerCheckout);
    }

    if (role == null || !allowedRoles.contains(role)) {
      return RouteSettings(name: auth.homeRouteForCurrentRole);
    }

    return null;
  }
}
