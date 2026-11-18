/// Authoritative three-role authorization model for Sign2Speech Addendum V3.
///
/// Important: This authorization role (`customer`, `cashier`, `admin`) is
/// strictly separated from the accessibility `CommunicationMode` (`Teman Tuli` / `Teman Dengar`).
enum AppUserRole {
  customer,
  cashier,
  admin;

  /// Parses database or claim role string safely.
  /// Defaults any unknown, null, or tampered string to [AppUserRole.customer]
  /// (least privilege).
  static AppUserRole fromString(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'admin' => .admin,
      'cashier' => .cashier,
      'customer' => .customer,
      _ => .customer,
    };
  }

  String get dbValue => switch (this) {
    .customer => 'customer',
    .cashier => 'cashier',
    .admin => 'admin',
  };

  bool get canAccessCustomerFlow => this == .customer || this == .admin;

  bool get canAccessCashierDashboard => this == .cashier;

  bool get canMonitorCashierTransactions => this == .cashier || this == .admin;

  bool get canReportLowStock => this == .cashier || this == .admin;

  bool get canAccessAdminDashboard => this == .admin;

  bool get canMutateMasterCatalog => this == .admin;

  bool get canAdjustStock => this == .admin;

  bool get canManageSignVideos => this == .admin;

  bool get canManageStaff => this == .admin;

  bool get canViewBusinessFinancials => this == .admin;

  bool get canViewAuditLogs => this == .admin;
}

/// Account operational status enforced server-side in `public.profiles`.
enum AccountStatus {
  active,
  disabled,
  invited;

  static AccountStatus fromString(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'disabled' => .disabled,
      'invited' => .invited,
      'active' => .active,
      _ => .active,
    };
  }

  String get dbValue => switch (this) {
    .active => 'active',
    .disabled => 'disabled',
    .invited => 'invited',
  };
}
