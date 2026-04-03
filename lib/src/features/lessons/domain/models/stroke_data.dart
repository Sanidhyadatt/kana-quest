import 'package:flutter/foundation.dart';

@immutable
class StrokeData {
  const StrokeData({
    required this.character,
    required this.paths,
  });

  final String character;
  final List<String> paths; // SVG path data Strings (M..., L..., C...)

  int get strokeCount => paths.length;
}
