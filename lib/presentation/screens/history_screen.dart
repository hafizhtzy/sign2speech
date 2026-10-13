import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../features/history/controllers/history_controller.dart';
import '../../features/history/models/history_item.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/services/bisindo_tts_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Get.find<HistoryController>();
    final tts = Get.find<BisindoTtsService>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Riwayat Percakapan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Hapus Semua',
            onPressed: () {
              if (history.items.isEmpty) return;
              Get.defaultDialog(
                title: 'Hapus Riwayat',
                middleText: 'Apakah Anda yakin ingin menghapus seluruh riwayat percakapan?',
                textConfirm: 'Hapus',
                textCancel: 'Batal',
                confirmTextColor: AppColors.surface,
                buttonColor: AppColors.error,
                onConfirm: () {
                  history.clearAll();
                  Get.back();
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Obx(
                () => Row(
                  children: [
                    _buildFilterTab(history, 0, 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterTab(history, 1, 'Sign to Speech'),
                    const SizedBox(width: 8),
                    _buildFilterTab(history, 2, 'Speech to Sign'),
                  ],
                ),
              ),
            ),

            // Content List
            Expanded(
              child: Obx(() {
                final list = history.filteredItems;

                if (list.isEmpty) {
                  return EmptyStateView(
                    title: 'Belum Ada Riwayat',
                    subtitle: 'Mulai terjemahan lewat kamera atau mikrofon untuk menyimpan riwayat percakapan.',
                    actionLabel: 'Mulai Terjemahan',
                    onAction: () => Get.toNamed(AppRoutes.mainShell),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isS2S =
                        item.direction == TranslationDirection.signToSpeech;

                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isS2S
                                        ? Icons.sign_language_rounded
                                        : Icons.record_voice_over_rounded,
                                    size: 18,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isS2S ? 'Sign to Speech' : 'Speech to Sign',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.paleMist,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.signLanguageType,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.muted,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => history.deleteEntry(item.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.translatedContent,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                          if (item.originalContent.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Asal: ${item.originalContent}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(item.timestamp),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (isS2S)
                                TextButton.icon(
                                  onPressed: () =>
                                      tts.speak(item.translatedContent),
                                  icon: const Icon(
                                    Icons.volume_up_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Putar Suara',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () {
                                    final ttsCtrl =
                                        Get.find<TextToSignController>();
                                    ttsCtrl.recognizedWords.value =
                                        item.originalContent;
                                    ttsCtrl.processVoiceInput(
                                      item.originalContent,
                                    );
                                    Get.toNamed(AppRoutes.speechToSignResult);
                                  },
                                  icon: const Icon(
                                    Icons.play_circle_outline,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Putar Video',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(HistoryController history, int index, String title) {
    final isSelected = history.selectedFilterIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => history.setFilter(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.surface : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute';
  }
}
