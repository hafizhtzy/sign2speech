import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/services/bisindo_classifier_service.dart';
import '../widgets/onboarding_selection_cards.dart';

/// Standalone route for Choose Sign Language using the unified Onboarding layout:
/// vertically centered 3D popout cards + sticky bottom Stadium Pill CTA.
class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {
  String _selectedLang = 'BISINDO';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SettingsController>()) {
      _selectedLang = Get.find<SettingsController>().selectedSignLanguage.value;
    }
  }

  Future<void> _confirmSelection() async {
    HapticFeedback.lightImpact();
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      await settings.setSignLanguage(_selectedLang);
      await settings.completeOnboarding();
    }
    if (Get.isRegistered<SignLanguageController>()) {
      final signCtrl = Get.find<SignLanguageController>();
      signCtrl.setModel(
        _selectedLang == 'BISINDO'
            ? SignLanguageModelType.bisindo
            : SignLanguageModelType.sibi,
      );
    }
    Get.offAllNamed(AppRoutes.mainShell);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark ? AppColors.darkCanvas : AppColors.textOnDark;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppStrings.chooseLangTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxFormWidth,
          child: Column(
            children: [
              // Vertically centered 3D Popout Sign Language Cards
              Expanded(
                child: OnboardingSignLanguageStepContent(
                  selectedLanguage: _selectedLang,
                  onSelectLanguage: (lang) {
                    setState(() => _selectedLang = lang);
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
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkPrimary : AppColors.primary,
                      foregroundColor: foregroundColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: .center,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.startUsingApp.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: foregroundColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_rounded,
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
