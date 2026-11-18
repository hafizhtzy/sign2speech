import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';
import 'package:speech2sign/features/sign_language/controllers/sign_language_controller.dart';
import 'package:speech2sign/features/sign_language/widgets/gesture_candidate_loader.dart';

import '../controllers/cafe_cashier_controller.dart';
import 'cafe_mini_camera_viewport.dart';
import 'cashier_quick_deck.dart';

/// Active tab on Cashier Order & Communication Deck.
/// Order requested: Tab 1: Bahasa Isyarat (Default/Left), Tab 2: 1-Tap (Middle), Tab 3: Mic (Right).
enum CashierDeckTab { signLanguage, quickDeck, mic }

/// Unified 3-Tab Interaction Deck for Cashier Counter ("Stage 1: Pesan & AI").
///
/// Combines:
/// 1. Tab 1 (Default / Left): Sign Language Camera Detection (Live CameraX, AI HUD, gesture simulator chips).
/// 2. Tab 2 (Middle): 1-Tap Cashier Quick Deck (6 instant barista macros with speech & sign video sync).
/// 3. Tab 3 (Right): Voice Mic STT (Pulsing mic hero for vocal input & translation).
///
/// Below the tabs:
/// - Unified editable order transcript field.
/// - Quick preferences chips (+ Pisang Goreng, + Kopi Susu, + Oat Milk, etc.).
/// - 1-Tap "Proses Pesanan ke Nota" action button.
class CashierOrderDeckCard extends StatefulWidget {
  final CafeCashierController controller;
  final VoidCallback? onOpenMenuCatalog;

  const CashierOrderDeckCard({
    super.key,
    required this.controller,
    this.onOpenMenuCatalog,
  });

  @override
  State<CashierOrderDeckCard> createState() => _CashierOrderDeckCardState();
}

class _CashierOrderDeckCardState extends State<CashierOrderDeckCard>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Worker? _transcriptWorker;
  Worker? _listeningWorker;
  bool _isUserEditing = false;

  // Default is Tab 1: Bahasa Isyarat (Camera detection as primary choice on cashier side)
  CashierDeckTab _activeTab = CashierDeckTab.signLanguage;

  static const List<String> _quickPreferences = [
    'Pisang Goreng',
    'Kopi Susu',
    'Oat Milk',
    'Es Sedikit',
    'Gula Aren',
    'Tanpa Gula',
    'Dingin',
    'Panas',
    'Americano',
  ];

  static const List<String> _quickSignWords = [
    'SAYA',
    'PESAN',
    'KOPI SUSU',
    'PISANG GORENG',
    'DINGIN',
    'PANAS',
    'OAT MILK',
    'TERIMA KASIH',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.liveTranscript.value,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.controller.isListening.value) {
      _pulseController.repeat(reverse: true);
    }

    _listeningWorker = ever<bool>(widget.controller.isListening, (listening) {
      if (!mounted) return;
      if (listening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    // Synchronize live transcript with cashier text field when not manually typing
    _transcriptWorker = ever<String>(widget.controller.liveTranscript, (text) {
      if (!_isUserEditing && mounted) {
        if (_textController.text != text) {
          _textController.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller.activeCameraFeature.value ==
        CafeCameraActiveFeature.liveOrder) {
      widget.controller.closeCamera();
    }
    _transcriptWorker?.dispose();
    _listeningWorker?.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _switchTab(CashierDeckTab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
    });

    if (tab == CashierDeckTab.signLanguage) {
      if (widget.controller.isListening.value) {
        widget.controller.toggleListening();
      }
      // Kamera default tetap tertutup / sesuai preferensi kasir
    } else if (tab == CashierDeckTab.mic) {
      widget.controller.closeCamera();
    } else {
      // 1-Tap Quick Deck tab
      if (widget.controller.isListening.value) {
        widget.controller.toggleListening();
      }
      widget.controller.closeCamera();
    }
  }

  void _appendPreference(String pref) {
    final current = _textController.text.trim();
    final updated = current.isEmpty ? pref : '$current $pref';
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    widget.controller.onTranscriptReceived(updated, triggerSign: true);
  }

  void _submitOrder() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(
        title: AppStrings.cafeCashierDeckTitle.tr,
        message: AppStrings.cafeCashierSubmitEmptyWarning.tr,
        variant: SnackbarVariant.warning,
      );
      return;
    }

    widget.controller.submitCustomerVoiceOrder(text);

    AppSnackbar.show(
      title: AppStrings.cafeCashierDeckTitle.tr,
      message: AppStrings.cafeCashierSubmitSuccess.tr,
      variant: SnackbarVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Clean Editorial Header (Zero Active-Mode Pills / Icon Boxes) ─
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeCashierDeckTitle.tr,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.cafeCashierDeckSubtitle.tr,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onOpenMenuCatalog != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: widget.onOpenMenuCatalog,
                  icon: Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    AppStrings.cafeModeMenuCatalog.tr,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(48, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),

          // ── 3-Tab Segmented Switcher (Bahasa Isyarat | 1-Tap | Mic) ──────
          _build3TabSwitcher(),

          // ── Active Tab Body ──────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildActiveTabContent(),
          ),

          const SizedBox(height: 22),

          // ── Clean Editable Transcript Input (Speech-to-Sign Style) ───────
          Container(
            decoration: BoxDecoration(
              color: AppColors.paleMist,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft, width: 1.0),
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isUserEditing = hasFocus;
                });
              },
              child: TextField(
                controller: _textController,
                maxLines: 2,
                minLines: 1,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.cafeCustomerVoiceEditHint.tr,
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, val, _) {
                      if (val.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        tooltip: AppStrings.cafeClearInputTooltip.tr,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        onPressed: () {
                          _textController.clear();
                          widget.controller.liveTranscript.value = '';
                          widget.controller.activeParsedSlot.value = null;
                          widget.controller.clearLiveOrderSentence();
                        },
                      );
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) {
                  widget.controller.onTranscriptReceived(
                    val,
                    triggerSign: true,
                  );
                },
                onSubmitted: (val) {
                  _submitOrder();
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Quick Preference Chips (Clean Speech-to-Sign Pill Style) ─────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.cafeCustomerQuickTagsTitle.tr,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _quickPreferences.map((pref) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          '+ $pref',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.border, width: 1.0),
                        ),
                        onPressed: () => _appendPreference(pref),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Primary Stadium CTA (Speech-to-Sign Reference Style) ─────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submitOrder,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                AppStrings.cafeCashierSubmitOrder.tr,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3-Tab Segmented Switcher: [Bahasa Isyarat | 1-Tap | Mic]
  Widget _build3TabSwitcher() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paleMist,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              tab: CashierDeckTab.signLanguage,
              label: AppStrings.cafeCashierTabSign.tr,
              icon: Icons.camera_alt_rounded,
              isSelected: _activeTab == CashierDeckTab.signLanguage,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabItem(
              tab: CashierDeckTab.quickDeck,
              label: AppStrings.cafeCashierTabQuick.tr,
              icon: Icons.touch_app_rounded,
              isSelected: _activeTab == CashierDeckTab.quickDeck,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabItem(
              tab: CashierDeckTab.mic,
              label: AppStrings.cafeCashierTabMic.tr,
              icon: Icons.mic_rounded,
              isSelected: _activeTab == CashierDeckTab.mic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required CashierDeckTab tab,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _switchTab(tab),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.onPrimary : AppColors.muted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? AppColors.onPrimary : AppColors.ink,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 12,
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

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case CashierDeckTab.signLanguage:
        return _buildCameraSignDetectionSection();
      case CashierDeckTab.quickDeck:
        return _buildQuickDeckSection();
      case CashierDeckTab.mic:
        return _buildVoiceMicrophoneHero();
    }
  }

  /// Tab 1 (Default): Bahasa Isyarat - Camera Detection Viewport & Gesture HUD
  Widget _buildCameraSignDetectionSection() {
    return Obx(() {
      final isCameraOpen =
          widget.controller.activeCameraFeature.value ==
          CafeCameraActiveFeature.liveOrder;

      return Column(
        key: const ValueKey('cashier_camera_sign_section'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Live Camera Viewport OR Closed Camera Standby Placeholder
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isCameraOpen
                ? _buildActiveCameraViewport()
                : _buildClosedCameraPlaceholder(),
          ),

          const SizedBox(height: 14),

          // 2. Clean Action Buttons (Avoid duplicating "Buka Kamera" when closed)
          if (isCameraOpen) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                key: const ValueKey('btn_toggle_camera'),
                onPressed: widget.controller.closeCamera,
                icon: const Icon(Icons.videocam_off_rounded, size: 17),
                label: Text(
                  AppStrings.cafeCloseLiveCamera.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(color: AppColors.secondary, width: 1.2),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              // Tombol Hapus Kata
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: widget.controller.deleteLastSignWord,
                    icon: const Icon(Icons.backspace_outlined, size: 15),
                    label: Text(
                      AppStrings.cafeCustomerDeleteLastWord.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: BorderSide(color: AppColors.border, width: 1.0),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Reset Isyarat
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: widget.controller.clearLiveOrderSentence,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: Text(
                      AppStrings.cafeCustomerClearSentence.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      side: BorderSide(color: AppColors.border, width: 1.0),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Quick Sign Simulator Chips (Clean Speech-to-Sign Pill Style)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.cafeCustomerQuickSignChips.tr,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _quickSignWords.map((sign) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          sign,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.border, width: 1.0),
                        ),
                        onPressed: () =>
                            widget.controller.addSignWordToLiveOrder(sign),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Tampilan Kamera Standby / Tertutup (Default — Serene Speech-to-Sign Style)
  Widget _buildClosedCameraPlaceholder() {
    return Container(
      key: const ValueKey('closed_camera_placeholder'),
      constraints: const BoxConstraints(minHeight: 224),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Icon(
              Icons.videocam_rounded,
              size: 28,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.cafeCashierCameraClosedTitle.tr,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.cafeCashierCameraClosedDesc.tr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              key: const ValueKey('btn_toggle_camera'),
              onPressed: () {
                widget.controller.openCameraFor(
                  CafeCameraActiveFeature.liveOrder,
                );
              },
              icon: const Icon(Icons.videocam_rounded, size: 18),
              label: Text(
                AppStrings.cafeOpenLiveCamera.tr,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Live Kamera Saat Dibuka
  Widget _buildActiveCameraViewport() {
    final signCtrl = widget.controller.signLanguageController;

    return CafeMiniCameraViewport(
      key: const ValueKey('active_camera_viewport'),
      height: 250,
      title: AppStrings.cafeCashierCameraActiveTitle.tr,
      subtitle: AppStrings.cafeCashierCameraSubtitle.tr,
      modelBadge: widget.controller.activeSignModel.displayName,
      onClose: widget
          .controller
          .closeCamera, // Tombol tutup kamera (X) di pojok kanan atas
      onSwitchCamera: widget.controller.switchCameraLens,
      cameraService: widget.controller.cameraFeedService,
      centerOverlay: signCtrl != null
          ? Obx(() {
              final candidate = signCtrl.streamingCandidate.value;
              final progress = signCtrl.suggestionProgress.value;
              final isConfirmed = signCtrl.isCandidateConfirmed.value;

              if (candidate.isNotEmpty) {
                return GestureCandidateLoader(
                  label: candidate,
                  progress: progress,
                  isConfirmed: isConfirmed,
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pan_tool_outlined,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Arahkan tangan ke kamera',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              );
            })
          : null,
      bottomBanner: signCtrl != null
          ? Obx(() {
              final state = signCtrl.state.value;
              final isSigning = state == BisindoLiveState.signing;
              final isClassifying = state == BisindoLiveState.classifying;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSigning
                        ? AppColors.amber
                        : isClassifying
                        ? AppColors.secondary
                        : AppColors.matcha,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSigning
                            ? AppColors.amber
                            : isClassifying
                            ? AppColors.secondary
                            : AppColors.matcha,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isSigning
                            ? 'Membaca gerakan tangan...'
                            : isClassifying
                            ? 'Memproses klasifikasi isyarat...'
                            : AppStrings.cafeCustomerCameraReady.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          : null,
    );
  }

  /// Tab 2: 1-Tap Cashier Quick Deck (Embedded)
  Widget _buildQuickDeckSection() {
    return Container(
      key: const ValueKey('cashier_quick_deck_section'),
      child: Obx(
        () => CashierQuickDeck(
          activeIndex: widget.controller.activeQuickDeckIndex.value,
          onExecute: widget.controller.executeQuickDeck,
          isEmbedded: true,
        ),
      ),
    );
  }

  /// Tab 3: Suara / Microphone Action Hero (Clean Speech-to-Sign Reference Style)
  Widget _buildVoiceMicrophoneHero() {
    return Obx(() {
      final isListening = widget.controller.isListening.value;
      return Padding(
        key: const ValueKey('cashier_voice_mode_hero'),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Column(
          children: [
            Text(
              AppStrings.cafeCashierMicHint.tr,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.muted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: widget.controller.toggleListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening
                            ? AppColors.secondary
                            : AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening
                                    ? AppColors.secondary
                                    : Colors.black)
                                .withValues(alpha: isListening ? 0.30 : 0.14),
                            blurRadius: isListening ? 20 : 12,
                            spreadRadius: isListening ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        size: 36,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isListening
                  ? AppStrings.cafeCashierMicListening.tr
                  : AppStrings.cafeCashierMicTap.tr,
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: isListening ? AppColors.secondary : AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }
}
