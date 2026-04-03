import 'package:flutter/material.dart';

/// The wise "Sensei" fox mascot that guides the user.
/// Uses the high-quality generated asset and supports speech bubbles.
class SenseiFox extends StatelessWidget {
  const SenseiFox({
    super.key,
    this.size = 80,
    this.showSpeechBubble = false,
    this.speechText,
  });

  final double size;
  final bool showSpeechBubble;
  final String? speechText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showSpeechBubble && speechText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: scheme.secondary.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              speechText!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ),
          // Speech bubble tail
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: CustomPaint(
              size: const Size(14, 10),
              painter: _SpeechBubbleTailPainter(
                color: scheme.primaryContainer.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
        Image.asset(
          'assets/sensei_fox.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a simple icon if the asset is missing
            return Icon(
              Icons.pets_rounded,
              size: size,
              color: scheme.primary,
            );
          },
        ),
      ],
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  const _SpeechBubbleTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}