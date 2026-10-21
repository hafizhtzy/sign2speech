import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../features/settings/controllers/settings_controller.dart';

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
    final settings = Get.find<SettingsController>();
    _selected = settings.selectedRole.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pilih Peran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bagaimana Anda Berkomunikasi?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih peran agar kami dapat menyesuaikan alur kenyamanan layar untuk Anda.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Role 1: Teman Tuli
              _buildRoleCard(
                title: 'Teman Tuli',
                cafeBadge: 'Barista / Pelanggan Tuli',
                cafeBadgeTextColor: AppColors.secondary,
                subtitle: 'Menggunakan Bahasa Isyarat (BISINDO / SIBI) untuk berbicara, mendengar via teks dan visual.',
                imagePath: AppAssets.roleTemanTuli,
                roleKey: 'Teman Tuli',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'atau',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),

              // Role 2: Teman Dengar
              _buildRoleCard(
                title: 'Teman Dengar',
                cafeBadge: 'Pelanggan / Teman Dengar',
                cafeBadgeTextColor: AppColors.muted,
                subtitle: 'Berbicara menggunakan suara lisan, mendengarkan respon suara dari bahasa isyarat lawan bicara.',
                imagePath: AppAssets.roleTemanDengar,
                roleKey: 'Teman Dengar',
              ),
              const SizedBox(height: 32),

              // Action CTA
              AppPrimaryButton(
                label: 'Lanjut',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  final settings = Get.find<SettingsController>();
                  settings.setRole(_selected);
                  Get.toNamed(AppRoutes.chooseLanguage);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String cafeBadge,
    required Color cafeBadgeTextColor,
    required String subtitle,
    required String imagePath,
    required String roleKey,
  }) {
    final isSelected = _selected == roleKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selected = roleKey;
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
              blurRadius: isSelected ? 14 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Text(
                      cafeBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cafeBadgeTextColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 90,
                width: 75,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
