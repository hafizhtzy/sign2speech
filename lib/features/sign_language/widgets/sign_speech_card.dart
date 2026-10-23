import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SignSpeechCard extends StatefulWidget {
  final bool isListening;
  final String recognizedText;
  final VoidCallback onToggleListen;
  final String statusText;

  const SignSpeechCard({
    super.key,
    required this.isListening,
    required this.recognizedText,
    required this.onToggleListen,
    this.statusText = 'Mendengarkan...',
  });

  @override
  State<SignSpeechCard> createState() => _SignSpeechCardState();
}

class _SignSpeechCardState extends State<SignSpeechCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isShortLandscape = size.height < 520;

    final micSize = isShortLandscape ? 60.0 : 80.0;
    final micIconSize = isShortLandscape ? 28.0 : 38.0;
    final cardPadding = isShortLandscape
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
        : const EdgeInsets.all(24);
    final waveHeight = isShortLandscape ? 32.0 : 48.0;
    final verticalSpacing = isShortLandscape ? 10.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform bars (5 responsive bars)
          if (widget.isListening)
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final val = _animController.value;
                return SizedBox(
                  height: waveHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaveBar(12 + (val * (waveHeight - 12))),
                      const SizedBox(width: 6),
                      _buildWaveBar(18 + ((1 - val) * (waveHeight - 18))),
                      const SizedBox(width: 6),
                      _buildWaveBar(24 + (val * (waveHeight - 24))),
                      const SizedBox(width: 6),
                      _buildWaveBar(16 + ((1 - val) * (waveHeight - 16))),
                      const SizedBox(width: 6),
                      _buildWaveBar(10 + (val * (waveHeight - 10))),
                    ],
                  ),
                );
              },
            )
          else
            SizedBox(
              height: waveHeight,
              child: Center(
                child: Text(
                  'Tekan mikrofon untuk bicara',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          SizedBox(height: verticalSpacing),

          // Central Microphone Button
          GestureDetector(
            onTap: widget.onToggleListen,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: micSize,
              height: micSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening
                    ? AppColors.secondary
                    : AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.isListening
                                ? AppColors.secondary
                                : AppColors.primary)
                            .withValues(alpha: 0.3),
                    blurRadius: widget.isListening ? 20 : 8,
                    spreadRadius: widget.isListening ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                color: AppColors.surface,
                size: micIconSize,
              ),
            ),
          ),
          SizedBox(height: verticalSpacing),

          // Status & Live Transcript
          Text(
            widget.isListening ? widget.statusText : 'Siap merekam suara',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.isListening ? AppColors.secondary : AppColors.muted,
            ),
          ),
          if (widget.recognizedText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                widget.recognizedText,
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 5,
      height: height.clamp(6.0, 48.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
