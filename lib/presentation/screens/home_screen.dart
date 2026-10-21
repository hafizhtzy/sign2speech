import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _activeQuickPhrase;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final history = Get.find<HistoryController>();
    final tts = Get.find<BisindoTtsService>();

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
                          color: AppColors.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          AppAssets.brandEmblem,
                          fit: BoxFit.contain,
                          cacheWidth: 100,
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
                            'Aksesibilitas Kasir & Kafe',
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

              // Greeting Banner with Left Accent Line
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: AppColors.secondary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Mau Pesan Apa Hari Ini?',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Obx(
                                          () => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              settings
                                                  .selectedSignLanguage
                                                  .value,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textOnDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Pilih mode terjemahan atau pintasan kasir di bawah untuk mulai komunikasi ramah dan inklusif di kafe.',
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
                                  width: 85,
                                  fit: BoxFit.contain,
                                  cacheWidth: 200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── New Section: Pintasan Kalimat Kasir (Quick Chips) ────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pintasan Kalimat Kasir',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Sentuh untuk bersuara',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickOrderChip(
                      tts: tts,
                      chipLabel: '☕ Pesan Kopi',
                      spokenPhrase: 'Saya mau pesan kopi',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickOrderChip(
                      tts: tts,
                      chipLabel: '🧊 Less Ice',
                      spokenPhrase: 'Tolong esnya sedikit saja ya',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickOrderChip(
                      tts: tts,
                      chipLabel: '🍯 Kurang Gula',
                      spokenPhrase: 'Tolong kurangi gulanya ya',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickOrderChip(
                      tts: tts,
                      chipLabel: '💳 Bayar QRIS',
                      spokenPhrase: 'Saya ingin bayar menggunakan QRIS',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickOrderChip(
                      tts: tts,
                      chipLabel: '🛍️ Bawa Pulang',
                      spokenPhrase: 'Tolong dibungkus untuk dibawa pulang',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Mode Penerjemah Utama ────────────────────────────────────
              const Text(
                'Mode Penerjemah Utama',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Sign to Speech Card (Rich Espresso #2C1E18)
              _buildFeatureCard(
                title: 'Sign to Speech',
                subtitle:
                    'Arahkan kamera ke gerakan isyarat untuk diterjemahkan menjadi suara lisan Bahasa Indonesia secara langsung.',
                tag: 'Kamera AI + Suara',
                color: AppColors.primary,
                textColor: AppColors.textOnDark,
                tagBgColor: AppColors.textOnDark.withValues(alpha: 0.14),
                dividerColor: AppColors.textOnDark.withValues(alpha: 0.20),
                icon: Icons.camera_alt_rounded,
                onTap: () => Get.toNamed(AppRoutes.signToSpeechCamera),
              ),
              const SizedBox(height: 14),

              // 2. Speech to Sign Card (Warm Caramel #8C5A3C)
              _buildFeatureCard(
                title: 'Speech to Sign',
                subtitle:
                    'Bicara lewat mikrofon untuk menampilkan rangkaian video peragaan isyarat kata-demi-kata secara berurutan.',
                tag: 'Mikrofon + Video',
                color: AppColors.secondary,
                textColor: AppColors.textOnDark,
                tagBgColor: AppColors.textOnDark.withValues(alpha: 0.16),
                dividerColor: AppColors.textOnDark.withValues(alpha: 0.25),
                icon: Icons.mic_rounded,
                onTap: () => Get.toNamed(AppRoutes.speechToSignMic),
              ),
              const SizedBox(height: 24),

              // Quick Categories Shortcut (Katalog Isyarat Kafe)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Katalog Isyarat Kafe',
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
                        fontWeight: FontWeight.w700,
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
                      'Minuman & Menu',
                      Icons.coffee_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Takaran (Es/Gula)',
                      Icons.tune_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Kasir & Bayar',
                      Icons.point_of_sale_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Sapaan Kafe',
                      Icons.waving_hand_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      'Bawa Pulang',
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
                              fontWeight: FontWeight.w700,
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.direction.index == 0
                                      ? Icons.sign_language_rounded
                                      : Icons.record_voice_over_rounded,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.translatedContent,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
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
                                color: AppColors.textMuted,
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

  Widget _buildQuickOrderChip({
    required BisindoTtsService tts,
    required String chipLabel,
    required String spokenPhrase,
  }) {
    final isActive = _activeQuickPhrase == chipLabel;

    return GestureDetector(
      onTap: () async {
        setState(() {
          _activeQuickPhrase = chipLabel;
        });
        await tts.speak(spokenPhrase);
        Get.snackbar(
          'Suara Diucapkan',
          spokenPhrase,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: AppColors.textOnDark,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _activeQuickPhrase = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.secondary : AppColors.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          chipLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.textOnDark : AppColors.ink,
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
    required Color tagBgColor,
    required Color dividerColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
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
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tagBgColor,
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
              // Cafe Ticket Dashed Divider Detail
              LayoutBuilder(
                builder: (context, constraints) {
                  final boxWidth = constraints.maxWidth;
                  const dashWidth = 5.0;
                  const dashSpace = 4.0;
                  final dashCount =
                      (boxWidth / (dashWidth + dashSpace)).floor();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(dashCount, (_) {
                        return SizedBox(
                          width: dashWidth,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: dividerColor),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
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
