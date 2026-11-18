import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../features/sign_language/controllers/text_to_sign_controller.dart';
import '../../features/sign_language/models/sign_video_entry.dart';
import '../../features/sign_language/services/sign_language_repository.dart';
import '../widgets/pagination_control_bar.dart';

class SignLibraryScreen extends StatefulWidget {
  const SignLibraryScreen({super.key});

  @override
  State<SignLibraryScreen> createState() => _SignLibraryScreenState();
}

class _SignLibraryScreenState extends State<SignLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SignLanguageRepository repository = Get.find<SignLanguageRepository>();

  /// Filter bahasa isyarat: 'Semua', 'BISINDO', atau 'SIBI'
  String _selectedLanguage = 'Semua';

  /// Filter kategori kosakata
  String _selectedCategory = 'Semua';

  /// Pagination halaman aktif (1-indexed) dan ukuran halaman
  int _currentPage = 1;
  static const int _pageSize = 12;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _goToPage(int page, int totalPages) {
    if (page < 1 || page > totalPages) return;
    setState(() {
      _currentPage = page;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
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
    final allFiltered = _filteredEntries;
    final totalItems = allFiltered.length;
    final totalPages = (totalItems / _pageSize).ceil();
    final safeCurrentPage = totalPages == 0
        ? 1
        : _currentPage.clamp(1, totalPages);
    final startIndex = (safeCurrentPage - 1) * _pageSize;
    final pagedEntries = allFiltered.skip(startIndex).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          AppStrings.libraryTitle.tr,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isDownloading
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: _downloadProgress > 0
                              ? _downloadProgress
                              : null,
                          strokeWidth: 2.2,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.download_for_offline_outlined,
                      color: AppColors.muted,
                      size: 22,
                    ),
                    tooltip: 'Unduh Filter Ini',
                    onPressed: _downloadFilteredPack,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveContentWrapper(
          maxWidth: ResponsiveBreakpoints.maxDashboardWidth,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. MINIMALIST HEADER CONTROLS (SEARCH, LANGUAGE, CATEGORY) ──
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    // 1.1 Airy Search Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {
                          _currentPage = 1;
                        }),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.librarySearchPlaceholder.tr,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _currentPage = 1;
                                    });
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
                              color: AppColors.secondary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 1.2 Clean Language Segmented Switcher (Semua / BISINDO / SIBI)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: _languages.map((lang) {
                            final isSelected = _selectedLanguage == lang;
                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedLanguage = lang;
                                    _currentPage = 1;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      lang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelMedium.copyWith(
                                        fontSize: 12.5,
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
                    const SizedBox(height: 18),

                    // 1.3 Editorial Category Tiles (Inspired by Apple/Spotify Reference)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCategory = cat;
                                  _currentPage = 1;
                                });
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              labelStyle: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1.4 Clean Editorial Section Header (No hardcoded/explicit vocab count)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                      child: Text(
                        _selectedCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. VOCABULARY TRACKLIST OR EMPTY STATE ────────────────────
              if (totalItems == 0)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Center(
                      child: Column(
                        mainAxisSize: .min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 52,
                            color: AppColors.muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada kosakata yang cocok',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba ubah kata kunci atau pilih kategori lain',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (context.isLargeScreen)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 460,
                          mainAxisExtent: 82,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 8,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildVocabularyRow(context, pagedEntries[index]),
                      childCount: pagedEntries.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 2, bottom: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final itemIndex = index ~/ 2;
                        if (index.isOdd) {
                          return Divider(
                            height: 1,
                            indent: 88,
                            endIndent: 20,
                            color: AppColors.border.withValues(alpha: 0.45),
                          );
                        }
                        return _buildVocabularyRow(
                          context,
                          pagedEntries[itemIndex],
                        );
                      },
                      childCount: pagedEntries.isEmpty
                          ? 0
                          : pagedEntries.length * 2 - 1,
                    ),
                  ),
                ),

              // ── 3. PAGINATION CONTROL BAR (FOOTER) ────────────────────────
              if (totalItems > 0 && totalPages > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
                    child: PaginationControlBar(
                      currentPage: safeCurrentPage,
                      totalPages: totalPages,
                      totalItems: totalItems,
                      itemsPerPage: _pageSize,
                      showItemCount: false,
                      onPageChanged: (page) => _goToPage(page, totalPages),
                    ),
                  ),
                )
              else if (totalItems > 0)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 128),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimalist borderless editorial vocabulary row inspired by clean tracklists.
  /// Zero pill clutter, generous touch padding, and subtle right-aligned metadata.
  Widget _buildVocabularyRow(BuildContext context, SignVideoEntry entry) {
    final isSibi = entry.signSystem.toLowerCase().trim() == 'sibi';
    final isBundled = entry.assetPath.isNotEmpty;
    final subtitleText = entry.aliases.isNotEmpty
        ? entry.aliases.join(', ')
        : _formatCategoryDisplay(entry.category);

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Left Square Rounded Play Tile (Tracklist Thumbnail Style)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.75),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isSibi ? AppColors.secondary : AppColors.ink,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Center: Bold Word + Clean Natural Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisAlignment: .center,
                children: [
                  Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Right: Clean Minimalist Metadata (Zero Pill Boxes!)
            Row(
              mainAxisSize: .min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isBundled ? AppColors.matcha : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isSibi ? 'SIBI' : 'BISINDO',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


