import 'dart:math' as math;
import 'dart:ui';

class StrokeValidationResult {
  const StrokeValidationResult({
    required this.isValid,
    required this.progress, // 0.0 to 1.0
    this.reason = '',
  });

  final bool isValid;
  final double progress;
  final String reason;
}

class PathValidator {
  /// Samples a list of points along a given Path at a regular interval.
  static List<Offset> samplePath(Path path, {double interval = 3.0}) {
    final List<Offset> points = [];
    for (final metric in path.computeMetrics()) {
      final int count = (metric.length / interval).ceil();
      for (int i = 0; i <= count; i++) {
        final distance = (i / count) * metric.length;
        final tangent = metric.getTangentForOffset(distance.clamp(0, metric.length));
        if (tangent != null) {
          points.add(tangent.position);
        }
      }
    }
    return points;
  }

  /// Validates a complete stroke (list of user points) against a target path.
  ///
  /// Strategy:
  /// 1. User must START near the beginning of the target path.
  /// 2. User must END near the end of the target path.
  /// 3. The user's path must generally stay within tolerance of the target.
  ///
  /// All point coordinates are in the canonical 109x109 KanjiVG space.
  static StrokeValidationResult validateCompletedStroke({
    required List<Offset> userPoints,
    required List<Offset> targetPoints,
    double tolerance = 13.0, // in canonical 109x109 units (~12% of canvas)
  }) {

    if (userPoints.isEmpty) {
      return const StrokeValidationResult(isValid: false, progress: 0, reason: 'No input');
    }
    if (targetPoints.isEmpty) {
      // No reference data, allow any stroke
      return const StrokeValidationResult(isValid: true, progress: 1.0);
    }

    final userStart = userPoints.first;
    final userEnd = userPoints.last;
    final targetStart = targetPoints.first;
    final targetEnd = targetPoints.last;

    // 1. Check start proximity
    final startDist = (userStart - targetStart).distance;
    if (startDist > tolerance * 1.5) {
      return StrokeValidationResult(
        isValid: false,
        progress: 0,
        reason: 'Wrong start position (${startDist.toStringAsFixed(1)} units away)',
      );
    }

    // 2. Check end proximity
    final endDist = (userEnd - targetEnd).distance;
    if (endDist > tolerance * 1.8) {
      return StrokeValidationResult(
        isValid: false,
        progress: 0.5,
        reason: 'Wrong end position (${endDist.toStringAsFixed(1)} units away)',
      );
    }

    // 3. Check that user points are generally close to the target path
    // Sample a subset of user points for perf
    final step = math.max(1, userPoints.length ~/ 10);
    int outOfBounds = 0;
    for (int i = 0; i < userPoints.length; i += step) {
      final userPt = userPoints[i];
      final minD = _minDistanceTo(userPt, targetPoints);
      if (minD > tolerance) outOfBounds++;
    }
    final sampledCount = (userPoints.length / step).ceil();
    if (outOfBounds > sampledCount * 0.35) {
      return StrokeValidationResult(
        isValid: false,
        progress: 0.3,
        reason: 'Stroke deviated too far from the path',
      );
    }

    return const StrokeValidationResult(isValid: true, progress: 1.0);
  }

  static double _minDistanceTo(Offset point, List<Offset> points) {
    double minD = double.infinity;
    for (final p in points) {
      final d = (point - p).distance;
      if (d < minD) minD = d;
    }
    return minD;
  }
}
