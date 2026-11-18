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

/// Input mode selection for the customer order card.
enum CustomerOrderInputMode { voice, cameraSign }

/// Interactive Ordering Card for customers on Stage 1 ("Pesan & AI") page.
///
/// Features:
/// 1. Prominent segmented toggle between Voice (Mic STT) and Camera (Sign Language Recognition).
/// 2. In Voice Mode: Animated pulsing mic button with live speech-to-text.
/// 3. In Camera Mode: Live CameraX preview with HUD, streaming candidate loader,
///    lens switcher, and real-time gesture recognition into the order.
/// 4. Unified editable transcript field where customers can review and customize their order.
/// 5. Quick preference tags and quick sign simulator chips for rapid input.
/// 6. 1-Tap send button that dispatches order to cashier & triggers real-time sign video.
class CustomerVoiceOrderCard extends StatefulWidget {
  final CafeCashierController controller;
  final VoidCallback? onOpenMenuCatalog;

  const CustomerVoiceOrderCard({
    super.key,
    required this.controller,
    this.onOpenMenuCatalog,
  });

  @override
  State<CustomerVoiceOrderCard> createState() => _CustomerVoiceOrderCardState();
}

class _CustomerVoiceOrderCardState extends State<CustomerVoiceOrderCard>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Worker? _transcriptWorker;
  Worker? _listeningWorker;
  bool _isUserEditing = false;
  CustomerOrderInputMode _inputMode = CustomerOrderInputMode.voice;

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

    // Synchronize live transcript with customer text field when not manually typing
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
    if (_inputMode == CustomerOrderInputMode.cameraSign ||
        widget.controller.activeCameraFeature.value ==
            CafeCameraActiveFeature.liveOrder) {
      widget.controller.closeCamera();
    }
    _transcriptWorker?.dispose();
    _listeningWorker?.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _switchInputMode(CustomerOrderInputMode mode) {
    if (_inputMode == mode) return;
    setState(() {
      _inputMode = mode;
    });

    if (mode == CustomerOrderInputMode.cameraSign) {
      if (widget.controller.isListening.value) {
        widget.controller.toggleListening();
      }
      widget.controller.openCameraFor(CafeCameraActiveFeature.liveOrder);
    } else {
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
        title: AppStrings.cafeCustomerVoiceOrderTitle.tr,
        message: 'Silakan bicara atau gunakan isyarat untuk memesan kopi terlebih dahulu.',
        variant: SnackbarVariant.warning,
      );
      return;
    }

    widget.controller.submitCustomerVoiceOrder(text);

    AppSnackbar.show(
      title: AppStrings.cafeCustomerVoiceOrderTitle.tr,
      message: AppStrings.cafeCustomerVoiceSentSnackbar.tr,
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
          // ── Clean Editorial Header (Speech-to-Sign Reference Style) ──────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.cafeCustomerVoiceOrderTitle.tr,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.cafeCustomerVoiceOrderSubtitle.tr,
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

          // ── Segmented Mode Switcher (Mic <-> Kamera Isyarat) ─────────────
          _buildModeSwitcher(),

          // ── Active Mode Body (Voice Hero vs. Camera Viewport) ─────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _inputMode == CustomerOrderInputMode.voice
                ? _buildVoiceMicrophoneHero()
                : _buildCameraSignDetectionSection(),
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
                  widget.controller
                      .onTranscriptReceived(val, triggerSign: true);
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
                          side: BorderSide(
                            color: AppColors.border,
                            width: 1.0,
                          ),
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
                AppStrings.cafeCustomerVoiceSend.tr,
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

  /// Segmented pill switch between Suara (Mic) and Bahasa Isyarat (Kamera).
  Widget _buildModeSwitcher() {
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
            child: _buildModeTab(
              mode: CustomerOrderInputMode.voice,
              label: AppStrings.cafeCustomerModeMic.tr,
              icon: Icons.mic_rounded,
              isSelected: _inputMode == CustomerOrderInputMode.voice,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTab(
              mode: CustomerOrderInputMode.cameraSign,
              label: AppStrings.cafeCustomerModeCamera.tr,
              icon: Icons.camera_alt_rounded,
              isSelected: _inputMode == CustomerOrderInputMode.cameraSign,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required CustomerOrderInputMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _switchInputMode(mode),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.onPrimary : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.onPrimary : AppColors.ink,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mode 1: Suara / Microphone Action Hero (Clean Speech-to-Sign Reference Style)
  Widget _buildVoiceMicrophoneHero() {
    return Obx(() {
      final isListening = widget.controller.isListening.value;
      return Padding(
        key: const ValueKey('customer_voice_mode_hero'),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        child: Column(
          children: [
            Text(
              AppStrings.cafeCustomerVoiceHint.tr,
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
                  ? AppStrings.cafeCustomerVoiceListening.tr
                  : AppStrings.cafeCustomerVoiceMicTap.tr,
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

  /// Mode 2: Kamera / Sign Language Gesture Detection Viewport & Controls
  Widget _buildCameraSignDetectionSection() {
    final signCtrl = widget.controller.signLanguageController;

    return Column(
      key: const ValueKey('customer_camera_mode_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Live Camera Viewport
        CafeMiniCameraViewport(
          height: 250,
          title: AppStrings.cafeCustomerCameraActiveTitle.tr,
          subtitle: AppStrings.cafeCustomerCameraSubtitle.tr,
          modelBadge: widget.controller.activeSignModel.displayName,
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
                        horizontal: 12, vertical: 7),
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
                  final isClassifying =
                      state == BisindoLiveState.classifying;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
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
        ),

        const SizedBox(height: 14),

        // 2. Action Buttons (Hapus Kata Terakhir & Reset Isyarat)
        Row(
          children: [
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
  }
}
