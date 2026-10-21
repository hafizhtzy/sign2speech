import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';
import '../../features/sign_language/services/sign_language_cache_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final tts = Get.find<BisindoTtsService>();
    final cacheService = Get.find<SignLanguageCacheService>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group 1: Bahasa Isyarat & Peran
              _buildSectionHeader('Preferensi Bahasa & Peran'),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Obx(
                      () => _buildDropdownRow(
                        title: 'Bahasa Isyarat Aktif',
                        subtitle: 'Pilih sistem pengenalan & peragaan',
                        value: settings.selectedSignLanguage.value,
                        items: ['BISINDO', 'SIBI'],
                        onChanged: (val) {
                          if (val != null) settings.setSignLanguage(val);
                        },
                      ),
                    ),
                    const Divider(color: AppColors.borderSoft, height: 24),
                    Obx(
                      () => _buildDropdownRow(
                        title: 'Peran Komunikasi',
                        subtitle: 'Sesuaikan pengalaman interaksi',
                        value: settings.selectedRole.value,
                        items: ['Teman Tuli', 'Teman Dengar'],
                        onChanged: (val) {
                          if (val != null) settings.setRole(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group 2: Suara & Audio TTS
              _buildSectionHeader('Suara & Audio TTS (id-ID)'),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kecepatan Ucapan Suara',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mengatur kelancaran tempo suara Text-to-Speech',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    Obx(
                      () => Slider(
                        value: settings.ttsSpeed.value,
                        min: 0.5,
                        max: 1.5,
                        divisions: 4,
                        label: '${settings.ttsSpeed.value}x',
                        activeColor: AppColors.secondary,
                        inactiveColor: AppColors.border,
                        thumbColor: AppColors.secondary,
                        onChanged: (val) => settings.setTtsSpeed(val),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        tts.speak(
                          'Halo! Ini adalah contoh suara Bahasa Indonesia Sign2Speech.',
                        );
                      },
                      icon: const Icon(Icons.volume_up, size: 18),
                      label: const Text('Uji Coba Suara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.textOnDark,
                        minimumSize: const Size(double.infinity, 42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group 3: Video Peragaan Isyarat
              _buildSectionHeader('Video Peragaan Isyarat'),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => _buildDropdownRow(
                    title: 'Kecepatan Default Video',
                    subtitle: 'Kelajuan pemutaran animasi isyarat',
                    value: '${settings.videoSpeed.value}x',
                    items: ['0.75x', '1.0x', '1.25x'],
                    onChanged: (val) {
                      if (val != null) {
                        final speed =
                            double.tryParse(val.replaceAll('x', '')) ?? 1.0;
                        settings.setVideoSpeed(speed);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Group 4: Penyimpanan Offline
              _buildSectionHeader('Penyimpanan & Cache'),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Penyimpanan Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Tier 1 + Tier 2 Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.matcha,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Video kosakata inti tersedia langsung di dalam aplikasi tanpa kuota internet.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await cacheService.clearCache();
                        Get.snackbar(
                          'Cache Dibersihkan',
                          'Seluruh berkas cache sementara berhasil dihapus.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.surface,
                          colorText: AppColors.ink,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Bersihkan Cache Video Lokal'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(double.infinity, 42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group 5: Tentang Aplikasi & Bantuan
              _buildSectionHeader('Tentang Sign2Speech'),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Versi Aplikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'v2.2.0 (Inclusive Cafe Edition)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Privasi & Keamanan: Pemrosesan kamera dan koordinat MediaPipe berjalan 100% lokal di perangkat tanpa pengunggahan frame ke internet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.onboarding1);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(double.infinity, 42),
                      ),
                      child: const Text('Buka Ulang Panduan Onboarding'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            fontSize: 14,
          ),
          items: items.map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
