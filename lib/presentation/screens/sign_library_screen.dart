import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/responsive_layout.dart';
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

  /// Filter bahasa isyarat: 'Semua', 'BISINDO', atau 'SIBI'
  String _selectedLanguage = 'Semua';

  /// Filter kategori kosakata
  String _selectedCategory = 'Semua';

  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  final List<String> _languages = const ['Semua', 'BISINDO', 'SIBI'];

  final List<String> _categories = const [
    'Semua',
    'Harian',
    'Minuman & Menu',
    'Takaran (Es/Gula)',
    'Kasir & Bayar',
    'Sapaan',
    'Kesehatan',
    'Alfabet',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(SignVideoEntry entry, String selectedCategory) {
    if (selectedCategory == 'Semua') return true;
    final cat = entry.category.toLowerCase().trim();
    final label = entry.label.toLowerCase().trim();
    switch (selectedCategory) {
      case 'Minuman & Menu':
        return cat == 'drink' ||
            cat == 'food' ||
            cat == 'menu' ||
            label.contains('kopi') ||
            label.contains('air') ||
            label.contains('minum') ||
            label.contains('teh') ||
            label.contains('makan');
      case 'Takaran (Es/Gula)':
        return cat == 'measurement' ||
            label.contains('es') ||
            label.contains('gula') ||
            label.contains('sedikit') ||
            label.contains('banyak') ||
            label.contains('kurang');
      case 'Kasir & Bayar':
        return cat == 'finance' ||
            cat == 'payment' ||
            label.contains('bayar') ||
            label.contains('uang') ||
            label.contains('qris') ||
            label.contains('harga') ||
            label.contains('kasir') ||
            label.contains('beli');
      case 'Sapaan':
        return cat == 'salam' ||
            label.contains('halo') ||
            label.contains('terima kasih') ||
            label.contains('selamat') ||
            label.contains('permisi') ||
            label.contains('tolong');
      case 'Alfabet':
        return cat == 'alphabet' || cat == 'alfabet';
      case 'Harian':
        return cat == 'general' ||
            cat == 'harian' ||
            cat == 'pronoun' ||
            cat == 'question';
      case 'Kesehatan':
        return cat == 'health' || cat == 'kesehatan';
      default:
        return cat == selectedCategory.toLowerCase();
    }
  }

  bool _matchesLanguage(SignVideoEntry entry, String selectedLanguage) {
    if (selectedLanguage == 'Semua') return true;
    final sys = entry.signSystem.toLowerCase().trim();
    return sys == selectedLanguage.toLowerCase().trim();
  }

  bool _matchesQuery(SignVideoEntry entry, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (entry.label.toLowerCase().contains(q)) return true;
    return entry.aliases.any((a) => a.toLowerCase().contains(q));
  }

  String _formatCategoryDisplay(String category) {
    switch (category.toLowerCase().trim()) {
      case 'general':
      case 'harian':
        return 'Harian';
      case 'health':
      case 'kesehatan':
        return 'Kesehatan';
      case 'question':
        return 'Pertanyaan';
      case 'pronoun':
        return 'Kata Ganti';
      case 'movement':
        return 'Gerakan';
      case 'activity':
        return 'Aktivitas';
      case 'salam':
        return 'Sapaan';
      case 'alphabet':
      case 'alfabet':
        return 'Alfabet';
      default:
        return category.capitalizeFirst ?? category;
    }
  }

  List<SignVideoEntry> get _filteredEntries {
    final query = _searchController.text;
    return repository.allCatalogEntries.where((entry) {
      final matchesLang = _matchesLanguage(entry, _selectedLanguage);
      final matchesCat = _matchesCategory(entry, _selectedCategory);
      final matchesQ = _matchesQuery(entry, query);
      return matchesLang && matchesCat && matchesQ;
    }).toList();
  }

  int _countByLanguage(String lang) {
    if (lang == 'Semua') return repository.allCatalogEntries.length;
    return repository.allCatalogEntries
        .where((e) => e.signSystem.toLowerCase() == lang.toLowerCase())
        .length;
  }

  Future<void> _downloadFilteredPack() async {
    final targetEntries = _filteredEntries;
    if (targetEntries.isEmpty) {
      AppSnackbar.warning(
        title: AppStrings.libraryNoVideosToDownload.tr,
        message: AppStrings.libraryNoVideosToDownloadDesc.tr,
        icon: Icons.filter_none_rounded,
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
    });

    int downloadedCount = 0;
    int successCount = 0;

    for (int i = 0; i < targetEntries.length; i++) {
      final entry = targetEntries[i];
      if (entry.assetPath.isEmpty) {
        try {
          await repository.downloadVideo(
            entry,
            onProgress: (p) {
              if (mounted) {
                final base = i / targetEntries.length;
                final portion = (1.0 / targetEntries.length) * p;
                setState(() {
                  _downloadProgress = (base + portion).clamp(0.0, 1.0);
                });
              }
            },
          );
          successCount++;
        } catch (_) {}
      } else {
        successCount++;
      }
      downloadedCount++;
      if (mounted) {
        setState(() {
          _downloadProgress = (downloadedCount / targetEntries.length).clamp(
            0.0,
            1.0,
          );
        });
      }
    }

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      AppSnackbar.success(
        title: AppStrings.libraryDownloadComplete.tr,
        message: AppStrings.libraryDownloadCompleteDesc.trParams({
          'count': successCount.toString(),
        }),
        icon: Icons.cloud_done_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          AppStrings.libraryTitle.tr,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. HEADER CONTROLS (SEARCH, FILTERS, DOWNLOAD BANNER) ────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1.1 Search Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: AppStrings.librarySearchPlaceholder.tr,
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.textMuted),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: AppColors.textMuted,
                                  ),
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
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 1.2 Filter Sistem Isyarat (BISINDO / SIBI / SEMUA)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: _languages.map((lang) {
                            final isSelected = _selectedLanguage == lang;
                            final count = _countByLanguage(lang);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedLanguage = lang;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(
                                                alpha: 0.18,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$lang ($count)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.onPrimary
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 1.3 Filter Pill Kategori (Horizontal Scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
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
                                color: isSelected
                                    ? AppColors.textOnDark
                                    : AppColors.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 12.5,
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
                    const SizedBox(height: 10),

                    // 1.4 Offline Download Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AppCard(
                        backgroundColor: AppColors.bgSurface,
                        border: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.download_for_offline_rounded,
                                color: AppColors.textOnDark,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isDownloading
                                        ? 'Mengunduh... (${(_downloadProgress * 100).toInt()}%)'
                                        : 'Unduh Filter Ini (${entries.length} video)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    _isDownloading
                                        ? 'Sedang menyimpan video ke memori lokal'
                                        : 'Kategori $_selectedCategory • $_selectedLanguage',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _isDownloading ? null : _downloadFilteredPack,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _isDownloading ? 'Memproses' : 'Unduh',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── 2. VOCABULARY LIST OR EMPTY STATE ───────────────────────
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 52,
                            color: AppColors.muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada kosakata yang cocok',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba ubah kata kunci atau pilih kategori lain',
                            style: TextStyle(
                              color: AppColors.muted.withValues(alpha: 0.8),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (context.isLargeScreen)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 460,
                      mainAxisExtent: 84,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildVocabularyCard(context, entries[index]),
                      childCount: entries.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final itemIndex = index ~/ 2;
                        if (index.isOdd) {
                          return const SizedBox(height: 8);
                        }
                        return _buildVocabularyCard(
                          context,
                          entries[itemIndex],
                        );
                      },
                      childCount: entries.isEmpty ? 0 : entries.length * 2 - 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyCard(BuildContext context, SignVideoEntry entry) {
    final isSibi = entry.signSystem.toLowerCase().trim() == 'sibi';
    final isBundled = entry.assetPath.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () async {
        final ttsCtrl = Get.find<TextToSignController>();
        ttsCtrl.recognizedWords.value = entry.label;
        ttsCtrl.selectedLanguage.value = entry.signSystem.toLowerCase();
        ttsCtrl.currentEntry.value = entry;
        ttsCtrl.playlist.assignAll([entry]);
        ttsCtrl.activeWordIndex.value = 0;
        ttsCtrl.currentVideoSource.value = entry.path;
        await ttsCtrl.playEntry(
          entry,
          force: true,
          autoDownload: false,
        );
        Get.toNamed(AppRoutes.speechToSignResult);
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isSibi ? 'SIBI' : 'BISINDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.aliases.isNotEmpty
                      ? 'Sinonim: ${entry.aliases.join(', ')}'
                      : _formatCategoryDisplay(entry.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatCategoryDisplay(entry.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBundled
                        ? Icons.check_circle_outline_rounded
                        : Icons.cloud_outlined,
                    size: 13,
                    color: isBundled ? AppColors.matcha : AppColors.secondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isBundled ? 'Offline' : 'Cloud',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isBundled ? AppColors.matcha : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}


