import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          AppAssets.brandEmblem,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign2Speech',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Aksesibilitas Dua Arah',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Obx(
                    () => Row(
                      children: [
                        StatusBadge(
                          label: settings.selectedSignLanguage.value,
                          variant: BadgeVariant.active,
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(
                          label: settings.selectedRole.value,
                          variant: BadgeVariant.neutral,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Editorial Welcome Banner
              AppCard(
                backgroundColor: AppColors.paleMist,
                border: const BorderSide(color: AppColors.borderSoft),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Siap Berkomunikasi Hari Ini?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pilih mode terjemahan di bawah untuk memulai percakapan ramah dan inklusif.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        AppAssets.bannerWide,
                        height: 70,
                        width: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Mode Penerjemah Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Sign to Speech Card (Mineral Ocean #1B3B4B)
              _buildFeatureCard(
                title: 'Sign to Speech',
                subtitle: 'Arahkan kamera ke gerakan isyarat untuk diterjemahkan menjadi suara lisan Bahasa Indonesia secara langsung.',
                tag: 'Kamera AI + Suara',
                color: AppColors.primary,
                textColor: AppColors.surface,
                icon: Icons.camera_alt_rounded,
                onTap: () => Get.toNamed(AppRoutes.signToSpeechCamera),
              ),
              const SizedBox(height: 14),

              // 2. Speech to Sign Card (Fjord Blue #38687D)
              _buildFeatureCard(
                title: 'Speech to Sign',
                subtitle: 'Bicara lewat mikrofon untuk menampilkan rangkaian video peragaan isyarat kata-demi-kata secara berurutan.',
                tag: 'Mikrofon + Video',
                color: AppColors.secondary,
                textColor: AppColors.surface,
                icon: Icons.mic_rounded,
                onTap: () => Get.toNamed(AppRoutes.speechToSignMic),
              ),
              const SizedBox(height: 24),

              // Quick Categories Shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Katalog Isyarat Cepat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.signLibrary),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryPill(
                      'Salam & Sapaan',
                      Icons.waving_hand_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Layanan Publik',
                      Icons.account_balance_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Kesehatan',
                      Icons.local_hospital_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Belanja Harian',
                      Icons.shopping_bag_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Recent History Teaser
              Obx(() {
                final recent = history.items.take(2).toList();
                if (recent.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Percakapan Terakhir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.history),
                          child: const Text(
                            'Riwayat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recent.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onTap: () => Get.toNamed(AppRoutes.history),
                          child: Row(
                            children: [
                              Icon(
                                item.direction.index == 0
                                    ? Icons.sign_language_rounded
                                    : Icons.record_voice_over_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.translatedContent,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      item.signLanguageType,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String tag,
    required Color color,
    required Color textColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: textColor, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Mulai Sekarang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: textColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String title, IconData icon) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.signLibrary),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
