import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_model.dart';

import '../controllers/cafe_cashier_controller.dart';
import '../domain/models/coffee_menu_item.dart';
import '../domain/models/order_enums.dart';
import '../screens/cafe_order_queue_screen.dart';
import 'cafe_menu_catalog_sheet.dart';
import 'cafe_staff_pin_dialog.dart';

/// Modal Bottom Sheet for Cafe Cashier Controls & Settings.
/// Centralizes sign language model toggles, queue management, staff PIN authentication,
/// and transaction reset in a responsive, accessible bottom sheet.
class CafeCashierControlSheet extends StatefulWidget {
  final CafeCashierController controller;

  const CafeCashierControlSheet({
    super.key,
    required this.controller,
  });

  /// Displays the control bottom sheet with responsive width constraints.
  static Future<void> show({
    required BuildContext context,
    required CafeCashierController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CafeCashierControlSheet(controller: controller),
    );
  }

  @override
  State<CafeCashierControlSheet> createState() => _CafeCashierControlSheetState();
}

class _CafeCashierControlSheetState extends State<CafeCashierControlSheet> {
  late final TextEditingController _roomCodeCtrl;

  CafeCashierController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _roomCodeCtrl = TextEditingController(text: controller.counterId.value);
  }

  @override
  void dispose() {
    _roomCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.90;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: maxSheetHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.cafeControlSheetTitle.tr,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              AppStrings.cafeControlSheetSubtitle.tr,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.muted,
                        tooltip: 'Tutup',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(height: 1, thickness: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  // ── SECTION 1: Model Bahasa Isyarat ────────────────────────
                  _buildSignModelSection(context),

                  const SizedBox(height: 14),

                  // ── SECTION 1B: Mode Perangkat (1 Tablet vs 2 Tablet) ──────
                  _buildDeviceModeSection(context),

                  const SizedBox(height: 14),

                  // ── SECTION 2: Antrean Pesanan Kafe ────────────────────────
                  _buildQueueSection(context),

                  const SizedBox(height: 10),

                  // ── SECTION 2B: Akses Katalog Menu Kafe ────────────────────
                  _buildMenuCatalogTile(context),

                  const SizedBox(height: 14),

                  // ── SECTION 3: Keamanan & PIN Staf ─────────────────────────
                  _buildStaffSecuritySection(context),

                  const SizedBox(height: 14),

                  // ── SECTION 4: Reset Sesi Transaksi ────────────────────────
                  _buildResetSessionSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignModelSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sign_language_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.cafeControlSignModelTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.cafeControlSignModelDesc.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final active = controller.activeSignModel;
            return Row(
              children: [
                Expanded(
                  child: _buildModelChoiceCard(
                    model: SignLanguageModel.bisindo,
                    label: 'BISINDO',
                    description: AppStrings.cafeControlBisindoDesc.tr,
                    isSelected: active == SignLanguageModel.bisindo,
                    onTap: () {
                      controller.switchSignLanguageModel(SignLanguageModel.bisindo);
                      AppSnackbar.show(
                        title: 'Model Bahasa Isyarat',
                        message: AppStrings.cafeSignModelChanged.trParams({'model': 'BISINDO'}),
                        variant: SnackbarVariant.info,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModelChoiceCard(
                    model: SignLanguageModel.sibi,
                    label: 'SIBI',
                    description: AppStrings.cafeControlSibiDesc.tr,
                    isSelected: active == SignLanguageModel.sibi,
                    onTap: () {
                      controller.switchSignLanguageModel(SignLanguageModel.sibi);
                      AppSnackbar.show(
                        title: 'Model Bahasa Isyarat',
                        message: AppStrings.cafeSignModelChanged.trParams({'model': 'SIBI'}),
                        variant: SnackbarVariant.info,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModelChoiceCard({
    required SignLanguageModel model,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? AppColors.matcha : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.muted,
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceModeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.devices_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.cafeDeviceModeTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.cafeDeviceModeDesc.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final isDual = controller.deviceMode.value == CounterDeviceMode.dualTabletLocked;
            final isFlipped = controller.isFlipped.value;
            final currentRoom = controller.counterId.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Opsi 1: 1 Tablet
                    Expanded(
                      child: _buildDeviceChoiceCard(
                        icon: Icons.screen_rotation_rounded,
                        label: AppStrings.cafeMode1Tablet.tr,
                        description: AppStrings.cafeMode1TabletDesc.tr,
                        isSelected: !isDual,
                        onTap: () {
                          controller.setDeviceMode(CounterDeviceMode.singleTabletSwitch);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Opsi 2: 2 Tablet
                    Expanded(
                      child: _buildDeviceChoiceCard(
                        icon: Icons.sync_alt_rounded,
                        label: AppStrings.cafeMode2Tablet.tr,
                        description: AppStrings.cafeMode2TabletDesc.tr,
                        isSelected: isDual,
                        onTap: () {
                          controller.setDeviceMode(CounterDeviceMode.dualTabletLocked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sub-panel untuk 1 Tablet (Fitur Flip 180°)
                if (!isDual) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.screen_rotation_alt_rounded,
                          size: 20,
                          color: isFlipped ? AppColors.secondary : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.cafeFlipScreen.tr,
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                isFlipped
                                    ? AppStrings.cafeFlipActive.tr
                                    : AppStrings.cafeFlipInactive.tr,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            controller.toggleFlip();
                          },
                          icon: Icon(
                            Icons.flip_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            isFlipped ? 'Normal' : 'Putar 180°',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Sub-panel untuk 2 Tablet (Sinkronisasi Ruang via Supabase Realtime)
                // Dipisahkan secara cerdas berdasarkan autentikasi PIN Staf:
                // - Tablet Kasir (PIN valid): bertindak sebagai Host, generate & bagikan kode ruangan.
                // - Tablet Pembeli (Tanpa PIN): bertindak sebagai Client, memasukkan kode untuk menghubungkan.
                if (isDual) ...[
                  Builder(
                    builder: (context) {
                      final isStaff = controller.staffPinAuthenticated.value;

                      if (isStaff) {
                        // SISI TABLET KASIR (HOST)
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.matcha, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.matcha.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.point_of_sale_rounded,
                                          size: 14,
                                          color: AppColors.matcha,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppStrings.cafeDualHostBadge.tr,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.matcha,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => controller.logoutStaff(),
                                    icon: const Icon(Icons.lock_rounded, size: 14),
                                    label: Text(
                                      'Kunci Kasir',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.cafeDualStaffHostTitle.tr,
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.cafeDualStaffHostDesc.tr,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.cafeRoomCodeLabel.tr,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currentRoom,
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 18),
                                      color: AppColors.secondary,
                                      tooltip: 'Salin Kode',
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: currentRoom));
                                        AppSnackbar.show(
                                          title: AppStrings.cafeDeviceModeTitle.tr,
                                          message: AppStrings.cafeRoomCodeCopied.tr,
                                          variant: SnackbarVariant.info,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    FilledButton.icon(
                                      onPressed: () async {
                                        final newRoom = await controller.createRoomSession();
                                        _roomCodeCtrl.text = newRoom;
                                        AppSnackbar.show(
                                          title: AppStrings.cafeDeviceModeTitle.tr,
                                          message: AppStrings.cafeRoomCreated.tr,
                                          variant: SnackbarVariant.success,
                                        );
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 15),
                                      label: Text(
                                        AppStrings.cafeCreateRoom.tr,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // SISI TABLET PEMBELI (CLIENT LAYAR HADAP)
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.secondary, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_pin_rounded,
                                        size: 14,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppStrings.cafeDualCustomerBadge.tr,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await CafeStaffPinDialog.show(
                                      context,
                                      onVerify: controller.verifyStaffPin,
                                      title: 'PIN Staf Kasir',
                                      subtitle: 'Masukkan PIN untuk beralih ke sisi kasir',
                                    );
                                  },
                                  icon: const Icon(Icons.pin_rounded, size: 14),
                                  label: Text(
                                    'Masuk Kasir',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.cafeDualCustomerTitle.tr,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.cafeDualCustomerDesc.tr,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 42,
                                    child: TextField(
                                      controller: _roomCodeCtrl,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: AppStrings.cafeRoomCodeHint.tr,
                                        hintStyle: AppTypography.bodySmall.copyWith(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.bgSurface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: AppColors.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: AppColors.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: AppColors.secondary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final text = _roomCodeCtrl.text.trim();
                                    if (text.isNotEmpty) {
                                      await controller.joinRoomSession(text);
                                      AppSnackbar.show(
                                        title: AppStrings.cafeDeviceModeTitle.tr,
                                        message: AppStrings.cafeRoomJoined.tr,
                                        variant: SnackbarVariant.success,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.link_rounded, size: 16),
                                  label: Text(
                                    AppStrings.cafeJoinRoom.tr,
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeviceChoiceCard({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.secondary,
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? AppColors.matcha : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.muted,
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSection(BuildContext context) {
    return Obx(() {
      final queueCount = controller.activeOrdersQueue.length;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: queueCount > 0
                    ? AppColors.matcha.withValues(alpha: 0.15)
                    : AppColors.paleMist,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: queueCount > 0 ? AppColors.matcha : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: queueCount > 0 ? AppColors.matcha : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cafeControlQueueTitle.tr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    AppStrings.cafeControlQueueDesc.trParams({'count': '$queueCount'}),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                CafeOrderQueueScreen.showAsDialog(
                  context,
                  controller: controller,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.cafeControlQueueOpen.tr,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuCatalogTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cafeModeMenuCatalog.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Lihat menu kopi, teh, & camilan kafe',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              CafeMenuCatalogSheet.show(
                context: context,
                catalog: controller.menuCatalog,
                onSelectItem: (CoffeeMenuItem item) {
                  controller.addRecommendedItemToTicket(item);
                  controller.onTranscriptReceived(
                    'pesan ${item.nameId}',
                    triggerSign: true,
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buka',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSecuritySection(BuildContext context) {
    return Obx(() {
      final isAuthenticated = controller.staffPinAuthenticated.value;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? AppColors.matcha.withValues(alpha: 0.15)
                    : AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isAuthenticated ? AppColors.matcha : AppColors.amber,
                ),
              ),
              child: Icon(
                isAuthenticated ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 20,
                color: isAuthenticated ? AppColors.matcha : AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.cafeControlStaffTitle.tr,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    isAuthenticated
                        ? AppStrings.cafeControlStaffLoggedIn.tr
                        : AppStrings.cafeControlStaffLocked.tr,
                    style: AppTypography.bodySmall.copyWith(
                      color: isAuthenticated ? AppColors.matcha : AppColors.muted,
                      fontWeight: isAuthenticated ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                if (isAuthenticated) {
                  controller.logoutStaff();
                } else {
                  Navigator.of(context).pop();
                  await CafeStaffPinDialog.show(
                    context,
                    onVerify: controller.verifyStaffPin,
                    title: 'PIN Staf Kasir',
                    subtitle: 'Masukkan PIN untuk melanjutkan',
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAuthenticated ? AppColors.paleMist : AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAuthenticated
                      ? AppStrings.cafeControlStaffLogout.tr
                      : AppStrings.cafeControlStaffLogin.tr,
                  style: AppTypography.labelSmall.copyWith(
                    color: isAuthenticated ? AppColors.ink : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResetSessionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cafeControlResetTitle.tr,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  AppStrings.cafeControlResetDesc.tr,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              _showConfirmResetDialog(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Reset Meja',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmResetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          AppStrings.cafeControlResetTitle.tr,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppStrings.cafeControlResetConfirm.tr,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.cafeControlResetCancel.tr,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              controller.resetToIdle();
              AppSnackbar.show(
                title: 'Meja Direset',
                message: 'Meja kasir telah dikosongkan dan siap untuk pelanggan berikutnya.',
                variant: SnackbarVariant.success,
              );
            },
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );
  }
}
