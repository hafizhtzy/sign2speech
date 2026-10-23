import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaveBar(16 + (val * 24)),
                      const SizedBox(width: 6),
                      _buildWaveBar(24 + ((1 - val) * 20)),
                      const SizedBox(width: 6),
                      _buildWaveBar(32 + (val * 16)),
                      const SizedBox(width: 6),
                      _buildWaveBar(20 + ((1 - val) * 22)),
                      const SizedBox(width: 6),
                      _buildWaveBar(14 + (val * 20)),
                    ],
                  ),
                );
              },
            )
          else
            SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  'Tekan mikrofon untuk bicara',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Central Microphone Button
          GestureDetector(
            onTap: widget.onToggleListen,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 80,
              height: 80,
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
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status & Live Transcript
          Text(
            widget.isListening ? widget.statusText : 'Siap merekam suara',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isListening ? AppColors.secondary : AppColors.muted,
            ),
          ),
          if (widget.recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paleMist,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                widget.recognizedText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
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
      height: height.clamp(8.0, 48.0),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
