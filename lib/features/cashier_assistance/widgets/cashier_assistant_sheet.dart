import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../sign_language/services/bisindo_tts_service.dart';

class CashierAssistantSheet extends StatefulWidget {
  const CashierAssistantSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CashierAssistantSheet(),
    );
  }

  @override
  State<CashierAssistantSheet> createState() => _CashierAssistantSheetState();
}

class _CashierAssistantSheetState extends State<CashierAssistantSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Price Pad State
  int _currentAmount = 0;

  // Customer-Facing Display State
  String _facingDisplayText = 'Halo! Mau pesan apa hari ini?';
  bool _isScreenFlipped = false;
  String _activeSpokenPhrase = '';

  // Preset categories filter
  String _selectedCategory = 'all';

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _speakText(String textId, String textEn) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeSpokenPhrase = textId;
      _facingDisplayText = textId;
    });

    if (Get.isRegistered<BisindoTtsService>()) {
      final tts = Get.find<BisindoTtsService>();
      final isEn = Get.isRegistered<SettingsController>() &&
          Get.find<SettingsController>().selectedAppLanguage.value == 'en';
      tts.speak(isEn ? textEn : textId);
    }
  }

  void _addAmount(int addition) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentAmount = (_currentAmount + addition).clamp(0, 99999999);
      _facingDisplayText = 'Total: ${_formatCurrency(_currentAmount)}';
    });
  }

  void _typeDigit(int digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentAmount == 0) {
        _currentAmount = digit;
      } else {
        final newStr = '$_currentAmount$digit';
        if (newStr.length <= 8) {
          _currentAmount = int.tryParse(newStr) ?? _currentAmount;
        }
      }
      _facingDisplayText = 'Total: ${_formatCurrency(_currentAmount)}';
    });
  }

  void _addThousands() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentAmount > 0) {
        final newStr = '${_currentAmount}000';
        if (newStr.length <= 8) {
          _currentAmount = int.tryParse(newStr) ?? _currentAmount;
        }
      }
      _facingDisplayText = 'Total: ${_formatCurrency(_currentAmount)}';
    });
  }

  void _backspaceAmount() {
    HapticFeedback.selectionClick();
    setState(() {
      final str = _currentAmount.toString();
      if (str.length <= 1) {
        _currentAmount = 0;
      } else {
        _currentAmount = int.tryParse(str.substring(0, str.length - 1)) ?? 0;
      }
      _facingDisplayText = _currentAmount > 0
          ? 'Total: ${_formatCurrency(_currentAmount)}'
          : 'Halo! Mau pesan apa hari ini?';
    });
  }

  void _clearAmount() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentAmount = 0;
      _facingDisplayText = 'Halo! Mau pesan apa hari ini?';
    });
  }

  void _speakTotalAmount() {
    if (_currentAmount <= 0) return;
    final formatted = _formatCurrency(_currentAmount);

    _speakText(
      'Total belanja Anda adalah $formatted',
      'Your order total is $formatted',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
          left: BorderSide(color: AppColors.border, width: 1),
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.point_of_sale_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.cashierAssistantTitle.tr,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          AppStrings.cashierAssistantSubtitle.tr,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: AppColors.muted),
                  ),
                ],
              ),
            ),

            // Tab Bar Navigation
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.muted,
                labelStyle: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.coffee_rounded, size: 18),
                    text: AppStrings.cashierTabPresets.tr,
                  ),
                  Tab(
                    icon: Icon(Icons.dialpad_rounded, size: 18),
                    text: AppStrings.cashierTabPricePad.tr,
                  ),
                  Tab(
                    icon: Icon(Icons.screen_rotation_rounded, size: 18),
                    text: AppStrings.cashierTabCustomerDisplay.tr,
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPresetsTab(),
                  _buildPricePadTab(),
                  _buildCustomerDisplayTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. PRESETS TAB ────────────────────────────────────────────────────────
  Widget _buildPresetsTab() {
    final presets = _getPresets();
    final filtered = _selectedCategory == 'all'
        ? presets
        : presets.where((p) => p['category'] == _selectedCategory).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryPill('all', 'Semua / All'),
                const SizedBox(width: 8),
                _buildCategoryPill('menu', '☕ Menu & Pesanan'),
                const SizedBox(width: 8),
                _buildCategoryPill('payment', '💳 Pembayaran'),
                const SizedBox(width: 8),
                _buildCategoryPill('friendly', '🤝 Sapaan & Ramah'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Active feedback badge
          if (_activeSpokenPhrase.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.matcha.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.matcha.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: AppColors.matcha, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suara Diucapkan: "$_activeSpokenPhrase"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.matcha,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Presets Grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return AppCard(
                padding: const EdgeInsets.all(12),
                onTap: () => _speakText(item['id']!, item['en']!),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          item['icon']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['id']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up_rounded,
                          color: AppColors.secondary, size: 20),
                      onPressed: () => _speakText(item['id']!, item['en']!),
                      tooltip: 'Ucapkan Suara',
                    ),
                    IconButton(
                      icon: Icon(Icons.screen_rotation_rounded,
                          color: AppColors.muted, size: 18),
                      onPressed: () {
                        setState(() {
                          _facingDisplayText = item['id']!;
                        });
                        _tabController.animateTo(2);
                      },
                      tooltip: 'Tampilkan ke Layar Balik',
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }

  // ── 2. PRICE PAD TAB ──────────────────────────────────────────────────────
  Widget _buildPricePadTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large Price Display Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.cashierAmountPrompt.tr,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatCurrency(_currentAmount),
                    style: AppTypography.displayLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Thousands Addition Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickAmountChip(1000, '+1.000'),
                const SizedBox(width: 6),
                _buildQuickAmountChip(5000, '+5.000'),
                const SizedBox(width: 6),
                _buildQuickAmountChip(10000, '+10.000'),
                const SizedBox(width: 6),
                _buildQuickAmountChip(20000, '+20.000'),
                const SizedBox(width: 6),
                _buildQuickAmountChip(50000, '+50.000'),
                const SizedBox(width: 6),
                _buildQuickAmountChip(100000, '+100.000'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Numpad Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: [
              _buildNumpadButton('1', () => _typeDigit(1)),
              _buildNumpadButton('2', () => _typeDigit(2)),
              _buildNumpadButton('3', () => _typeDigit(3)),
              _buildNumpadButton('4', () => _typeDigit(4)),
              _buildNumpadButton('5', () => _typeDigit(5)),
              _buildNumpadButton('6', () => _typeDigit(6)),
              _buildNumpadButton('7', () => _typeDigit(7)),
              _buildNumpadButton('8', () => _typeDigit(8)),
              _buildNumpadButton('9', () => _typeDigit(9)),
              _buildNumpadButton('000', _addThousands),
              _buildNumpadButton('0', () => _typeDigit(0)),
              _buildNumpadIconButton(
                Icons.backspace_outlined,
                _backspaceAmount,
                onLongPress: _clearAmount,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Vocalize and Display
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  label: AppStrings.cashierSpeakAmount.tr,
                  icon: Icons.record_voice_over_rounded,
                  onPressed: _currentAmount > 0 ? _speakTotalAmount : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: AppSecondaryButton(
                  label: 'Layar Balik',
                  icon: Icons.screen_rotation_rounded,
                  onPressed: _currentAmount > 0
                      ? () => _tabController.animateTo(2)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int value, String label) {
    return ActionChip(
      onPressed: () => _addAmount(value),
      backgroundColor: AppColors.bgSurface,
      label: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      side: BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildNumpadButton(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadIconButton(IconData icon, VoidCallback onTap,
      {VoidCallback? onLongPress}) {
    return Material(
      color: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(icon, color: AppColors.ink, size: 22),
        ),
      ),
    );
  }

  // ── 3. CUSTOMER-FACING FLIP DISPLAY TAB ──────────────────────────────────
  Widget _buildCustomerDisplayTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode switch header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isScreenFlipped
                      ? AppColors.amber.withValues(alpha: 0.15)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isScreenFlipped
                        ? AppColors.amber
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isScreenFlipped
                          ? Icons.screen_rotation_rounded
                          : Icons.phone_android_rounded,
                      size: 14,
                      color: _isScreenFlipped
                          ? AppColors.amber
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isScreenFlipped
                          ? 'Menghadap Pelanggan (180°)'
                          : 'Menghadap Kasir / Anda',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _isScreenFlipped
                            ? AppColors.amber
                            : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isScreenFlipped = !_isScreenFlipped;
                  });
                },
                icon: const Icon(Icons.flip_camera_android_rounded, size: 16),
                label: Text(
                  _isScreenFlipped ? 'Normal (0°)' : 'Balik 180°',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big Facing Card Container (Rotates 180 degrees)
          Expanded(
            child: AnimatedRotation(
              turns: _isScreenFlipped ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isScreenFlipped
                        ? AppColors.secondary
                        : AppColors.border,
                    width: _isScreenFlipped ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.cashierCustomerViewBadge.tr,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _facingDisplayText,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () =>
                              _speakText(_facingDisplayText, _facingDisplayText),
                          icon: const Icon(Icons.volume_up_rounded),
                          tooltip: 'Ucapkan Teks Ini',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.cashierFlipScreenDesc.tr,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getPresets() {
    return const [
      {
        'category': 'menu',
        'icon': '☕',
        'title': 'Pesan Kopi',
        'id': 'Saya ingin pesan kopi satu ya.',
        'en': 'I would like to order one coffee, please.',
      },
      {
        'category': 'menu',
        'icon': '🧊',
        'title': 'Sedikit Es (Less Ice)',
        'id': 'Tolong es batunya sedikit saja (less ice).',
        'en': 'Please put less ice in the drink.',
      },
      {
        'category': 'menu',
        'icon': '🍯',
        'title': 'Kurang Gula (Less Sugar)',
        'id': 'Tolong gulanya dikurangi ya (less sugar).',
        'en': 'Please make it with less sugar.',
      },
      {
        'category': 'menu',
        'icon': '🥡',
        'title': 'Bungkus / Takeaway',
        'id': 'Pesanan ini dibungkus untuk dibawa pulang.',
        'en': 'Please pack this order for takeaway.',
      },
      {
        'category': 'menu',
        'icon': '🍽️',
        'title': 'Makan di Tempat',
        'id': 'Pesanan ini untuk makan di tempat (dine-in).',
        'en': 'This order is for dine-in, please.',
      },
      {
        'category': 'payment',
        'icon': '💳',
        'title': 'Bayar Pakai QRIS',
        'id': 'Saya ingin membayar menggunakan QRIS.',
        'en': 'I would like to pay using QRIS code.',
      },
      {
        'category': 'payment',
        'icon': '💵',
        'title': 'Uang Pas',
        'id': 'Ini uang pas ya, terima kasih banyak.',
        'en': 'Here is the exact amount, thank you.',
      },
      {
        'category': 'payment',
        'icon': '🧾',
        'title': 'Minta Struk Pembayaran',
        'id': 'Bisa tolong berikan struk pembayarannya?',
        'en': 'Could I have the payment receipt, please?',
      },
      {
        'category': 'friendly',
        'icon': '⏱️',
        'title': 'Mohon Tunggu Sebentar',
        'id': 'Mohon tunggu sebentar ya, pesanan sedang disiapkan.',
        'en': 'Please wait a moment, your order is being prepared.',
      },
      {
        'category': 'friendly',
        'icon': '🙏',
        'title': 'Terima Kasih Banyak',
        'id': 'Terima kasih banyak, semoga harimu menyenangkan!',
        'en': 'Thank you very much, have a wonderful day!',
      },
    ];
  }
}
