import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// Paints strokes incrementally in the Duolingo style:
/// - Strokes before [showUpTo-1] are drawn solid in a "completed" tint.
/// - The stroke at [showUpTo-1] is drawn fully in [brushColor] with a direction dot + arrow.
/// - Strokes after [showUpTo-1] are drawn as a faint ghost guide.
///
/// Set [showUpTo] == [paths.length] to show all strokes as fully completed.
class StrokeOrderPainter extends CustomPainter {
  const StrokeOrderPainter({
    required this.paths,
    required this.showUpTo,
    required this.brushColor,
    this.strokeWidth = 4.0,
    this.hintColor,
    this.showArrow = true,
  });

  final List<String> paths;

  /// How many strokes to show (1-indexed).
  /// - Strokes 0 .. showUpTo-2 draw as "done" (muted brushColor).
  /// - Stroke showUpTo-1 draws as "active" (full brushColor + arrow).
  /// - Strokes showUpTo .. end draw as ghost.
  final int showUpTo;

  final Color brushColor;
  final double strokeWidth;

  /// Override color for "already completed" strokes. Defaults to brushColor at 45% opacity.
  final Color? hintColor;

  /// Whether to draw the direction arrow on the active stroke.
  final bool showArrow;

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty) return;

    // KanjiVG uses a 109×109 viewbox
    final double scale = size.width / 109.0;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale;

    for (int i = 0; i < paths.length; i++) {
      if (paths[i].isEmpty) continue;
      final path = parseSvgPathData(paths[i]);

      if (showUpTo == 0) {
        // Ghost mode: all strokes faint
        paint.color = brushColor.withValues(alpha: 0.10);
        canvas.drawPath(path, paint);
      } else if (i < showUpTo - 1) {
        // Previously completed strokes — solid but slightly muted
        paint.color = hintColor ?? brushColor.withValues(alpha: 0.55);
        canvas.drawPath(path, paint);
      } else if (i == showUpTo - 1) {
        // Active (newest) stroke — full color + direction cue
        paint.color = brushColor;
        canvas.drawPath(path, paint);
        if (showArrow) _drawStartMarker(canvas, path, brushColor, scale);
      } else {
        // Upcoming strokes — ghost
        paint.color = brushColor.withValues(alpha: 0.10);
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  /// Draws a filled circle at the stroke's start point and a small arrow
  /// indicating the direction of travel — like Duolingo's stroke guide.
  void _drawStartMarker(Canvas canvas, Path path, Color color, double scale) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    if (metric.length < 4) return;

    final t0 = metric.getTangentForOffset(0);
    // Sample slightly ahead to get travel direction
    final sampleDist = math.min(8.0, metric.length * 0.25);
    final t1 = metric.getTangentForOffset(sampleDist);
    if (t0 == null || t1 == null) return;

    final start = t0.position;
    final ahead = t1.position;
    final dir = ahead - start;
    final len = dir.distance;
    if (len == 0) return;
    final norm = dir / len;

    // ── Start dot ──────────────────────────────────────────────
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(start, 4.0 / scale, dotPaint);

    // ── Arrow head pointing in travel direction ─────────────────
    final arrowLen = 5.5 / scale;
    final perpendicular = Offset(-norm.dy, norm.dx);
    final tip = start + norm * arrowLen * 1.8;
    final base = start + norm * arrowLen * 0.6;
    final left = base + perpendicular * (arrowLen * 0.65);
    final right = base - perpendicular * (arrowLen * 0.65);

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(arrowPath, dotPaint);
  }

  @override
  bool shouldRepaint(covariant StrokeOrderPainter oldDelegate) {
    return oldDelegate.showUpTo != showUpTo ||
        oldDelegate.brushColor != brushColor ||
        oldDelegate.paths != paths;
  }
}
