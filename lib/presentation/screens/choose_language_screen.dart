import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/controllers/sign_language_controller.dart';
import '../../features/sign_language/services/bisindo_classifier_service.dart';

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
    final settings = Get.find<SettingsController>();
    _selectedLang = settings.selectedSignLanguage.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pilih Bahasa Isyarat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sistem Isyarat Pilihan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda dapat mengganti pilihan ini kapan saja melalui menu Pengaturan.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: BISINDO
              _buildLanguageCard(
                title: 'BISINDO',
                fullName: 'Bahasa Isyarat Indonesia',
                description: 'Isyarat alami dua tangan yang lazim digunakan komunitas Tuli Indonesia sehari-hari.',
                badgeAsset: AppAssets.badgeBisindo,
                vocabCount: '47 Kosakata Inti',
                langKey: 'BISINDO',
              ),
              const SizedBox(height: 16),

              // Option 2: SIBI
              _buildLanguageCard(
                title: 'SIBI',
                fullName: 'Sistem Isyarat Bahasa Indonesia',
                description: 'Sistem isyarat formal berbasis tata bahasa baku Indonesia dan alfabet jari.',
                badgeAsset: AppAssets.badgeSibi,
                vocabCount: '72 Kosakata Formal',
                langKey: 'SIBI',
              ),
              const Spacer(),

              // Action CTA
              AppPrimaryButton(
                label: 'Mulai Menggunakan Aplikasi',
                icon: Icons.check,
                onPressed: () async {
                  final settings = Get.find<SettingsController>();
                  await settings.setSignLanguage(_selectedLang);
                  await settings.completeOnboarding();

                  final signCtrl = Get.find<SignLanguageController>();
                  signCtrl.setModel(
                    _selectedLang == 'BISINDO'
                        ? SignLanguageModelType.bisindo
                        : SignLanguageModelType.sibi,
                  );

                  Get.offAllNamed(AppRoutes.mainShell);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String title,
    required String fullName,
    required String description,
    required String badgeAsset,
    required String vocabCount,
    required String langKey,
  }) {
    final isSelected = _selectedLang == langKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLang = langKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : AppColors.primary.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(badgeAsset, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.primary : AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Text(
                          vocabCount,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
