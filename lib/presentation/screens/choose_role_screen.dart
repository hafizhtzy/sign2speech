import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../widgets/onboarding_selection_cards.dart';

/// Standalone route for Choose Role using the unified Onboarding layout:
/// vertically centered 3D popout cards + sticky bottom Stadium Pill CTA.
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _selected = 'Teman Tuli';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SettingsController>()) {
      _selected = Get.find<SettingsController>().selectedRole.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark
        ? AppColors.darkCanvas
        : AppColors.textOnDark;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppStrings.chooseRoleTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            children: [
              // Vertically centered 3D Popout Role Cards
              Expanded(
                child: OnboardingRoleStepContent(
                  selectedRole: _selected,
                  onSelectRole: (role) {
                    setState(() => _selected = role);
                    if (Get.isRegistered<SettingsController>()) {
                      Get.find<SettingsController>().setRole(role);
                    }
                  },
                ),
              ),

              // Sticky Bottom Full-Width Stadium Pill CTA (Matches Onboarding)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (Get.isRegistered<SettingsController>()) {
                        Get.find<SettingsController>().setRole(_selected);
                      }
                      Get.toNamed(AppRoutes.chooseLanguage);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                      foregroundColor: foregroundColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: .center,
                      children: [
                        Text(
                          AppStrings.next.tr,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: foregroundColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: foregroundColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
