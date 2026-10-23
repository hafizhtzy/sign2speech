import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_layout.dart';

/// Data model representing a single selectable option in [SettingsOptionSheet].
class SettingsOptionItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailingBadge;
  final Widget? visualPreview;

  const SettingsOptionItem({
    required this.value,
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailingBadge,
    this.visualPreview,
  });
}

/// A modern, responsive bottom sheet modal for settings option selection.
class SettingsOptionSheet<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData titleIcon;
  final List<SettingsOptionItem<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const SettingsOptionSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.titleIcon,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  /// Static helper to display the responsive bottom sheet.
  static Future<void> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData titleIcon,
    required List<SettingsOptionItem<T>> options,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    HapticFeedback.selectionClick();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => SettingsOptionSheet<T>(
        title: title,
        subtitle: subtitle,
        titleIcon: titleIcon,
        options: options,
        selectedValue: selectedValue,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Center(
      child: ResponsiveContentWrapper(
        maxWidth: ResponsiveBreakpoints.maxFormWidth,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header Row: Icon, Title & Close Button
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Icon(
                            titleIcon,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.muted,
                            size: 22,
                          ),
                          splashRadius: 22,
                          tooltip: 'Tutup',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.borderSoft, height: 1),
                    const SizedBox(height: 14),

                    // Option Selection Cards
                    ...options.map((option) {
                      final isSelected = option.value == selectedValue;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOptionTile(context, option, isSelected),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    SettingsOptionItem<T> option,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(option.value);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondary.withValues(alpha: 0.08)
                : AppColors.bgSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      option.icon,
                      size: 20,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                option.title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (option.trailingBadge != null) ...[
                              const SizedBox(width: 8),
                              option.trailingBadge!,
                            ],
                          ],
                        ),
                        if (option.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            option.subtitle!,
                            style: AppTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? AppColors.ink.withValues(alpha: 0.8)
                                  : AppColors.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.secondary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.border,
                        width: isSelected ? 0 : 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              if (option.visualPreview != null) ...[
                const SizedBox(height: 12),
                option.visualPreview!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
