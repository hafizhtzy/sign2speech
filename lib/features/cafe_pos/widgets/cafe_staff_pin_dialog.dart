import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_typography.dart';

/// Dialog keypad PIN 4 digit untuk Quick Staff Authentication.
/// Offline-first: PIN default '0000'. Tidak perlu internet.
///
/// Penggunaan:
/// ```dart
/// final ok = await CafeStaffPinDialog.show(
///   context,
///   onVerify: (pin) => controller.verifyStaffPin(pin),
/// );
/// ```
class CafeStaffPinDialog extends StatefulWidget {
  final bool Function(String pin) onVerify;
  final String? title;
  final String? subtitle;

  const CafeStaffPinDialog({
    super.key,
    required this.onVerify,
    this.title,
    this.subtitle,
  });

  static Future<bool> show(
    BuildContext context, {
    required bool Function(String pin) onVerify,
    String? title,
    String? subtitle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CafeStaffPinDialog(
        onVerify: onVerify,
        title: title,
        subtitle: subtitle,
      ),
    );
    return result ?? false;
  }

  @override
  State<CafeStaffPinDialog> createState() => _CafeStaffPinDialogState();
}

class _CafeStaffPinDialogState extends State<CafeStaffPinDialog> {
  String _pin = '';
  bool _hasError = false;

  void _onKey(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _hasError = false;
      });
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _onConfirm() {
    if (_pin.length < 4) return;
    final verified = widget.onVerify(_pin);
    if (verified) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title ?? 'PIN Staf',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle ?? 'Masukkan PIN 4 digit untuk membuka akses',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            ),

            const SizedBox(height: 20),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? AppColors.amber.withValues(alpha: 0.8)
                        : (filled
                            ? AppColors.secondary
                            : AppColors.bgSurface),
                    border: Border.all(
                      color: _hasError
                          ? AppColors.amber
                          : (filled
                              ? AppColors.secondary
                              : AppColors.border),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_hasError) ...[
              const SizedBox(height: 8),
              Text(
                'PIN salah, coba lagi',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Keypad (3x4 grid)
            _buildKeypad(),

            const SizedBox(height: 16),

            // Cancel
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 72, height: 56);
            }
            return _buildKey(key);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isDelete = key == '⌫';
    return SizedBox(
      width: 72,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isDelete) {
              _onDelete();
            } else if (key == '0' && _pin.length < 4) {
              _onKey('0');
              if (_pin.length == 4) _onConfirm();
            } else {
              _onKey(key);
              if (_pin.length == 4) {
                Future.delayed(
                  const Duration(milliseconds: 80),
                  _onConfirm,
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined,
                    size: 22, color: AppColors.muted)
                : Text(
                    key,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
