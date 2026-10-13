import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/models/sign_video_entry.dart';
import '../../features/sign_language/services/sign_language_repository.dart';

class SignLibraryScreen extends StatefulWidget {
  const SignLibraryScreen({super.key});

  @override
  State<SignLibraryScreen> createState() => _SignLibraryScreenState();
}

class _SignLibraryScreenState extends State<SignLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SignLanguageRepository repository = Get.find<SignLanguageRepository>();

  String _selectedCategory = 'Semua';
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  final List<String> _categories = [
    'Semua',
    'Salam',
    'Keluarga',
    'Kesehatan',
    'Belanja',
    'Darurat',
    'Layanan Publik',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SignVideoEntry> get _filteredEntries {
    final query = _searchController.text.toLowerCase().trim();
    return repository.allCatalogEntries.where((entry) {
      final matchesCat =
          _selectedCategory == 'Semua' ||
          entry.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          entry.label.toLowerCase().contains(query) ||
          entry.aliases.any((a) => a.toLowerCase().contains(query));
      return matchesCat && matchesQuery;
    }).toList();
  }

  Future<void> _downloadCategoryPack(String category) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.1;
    });

    final success = await repository.downloadCategory(
      category.toLowerCase(),
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _downloadProgress = p;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      Get.snackbar(
        success ? 'Unduhan Selesai' : 'Unduhan Gagal',
        success
            ? 'Paket kosakata $category berhasil tersimpan offline'
            : 'Periksa koneksi internet Anda dan coba lagi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.ink,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Perpustakaan Isyarat')),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari kosakata atau frasa isyarat...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.muted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            // Horizontal Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      selectedColor: AppColors.secondary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.surface : AppColors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.border,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Offline Download Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(
                backgroundColor: AppColors.paleMist,
                border: const BorderSide(color: AppColors.borderSoft),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.download_for_offline_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paket Offline Siap Unduh',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            _isDownloading
                                ? 'Mengunduh... (${(_downloadProgress * 100).toInt()}%)'
                                : 'Simpan paket kosakata untuk penggunaan tanpa kuota internet',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _isDownloading
                          ? null
                          : () => _downloadCategoryPack(_selectedCategory),
                      child: Text(
                        _isDownloading ? 'Proses' : 'Unduh',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Vocabulary List
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada kosakata yang cocok dengan pencarian.',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () {
                            final ttsCtrl = Get.find<TextToSignController>();
                            ttsCtrl.recognizedWords.value = entry.label;
                            ttsCtrl.processVoiceInput(entry.label);
                            Get.toNamed(AppRoutes.speechToSignResult);
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.paleMist,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AppColors.secondary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (entry.aliases.isNotEmpty)
                                      Text(
                                        'Alias: ${entry.aliases.join(', ')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
