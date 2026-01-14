import 'package:flutter/widgets.dart';

sealed class FramePathStyle {
  const FramePathStyle();
}

class SolidColorStyle extends FramePathStyle {
  final Color color;

  const SolidColorStyle(this.color);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SolidColorStyle && other.color == color;
  }

  @override
  int get hashCode => color.hashCode;
}

class GradientStyle extends FramePathStyle {
  final String id;
  final List<Color> colors;
  final List<double> stops;
  final Alignment begin;
  final Alignment end;

  const GradientStyle({
    required this.id,
    required this.colors,
    required this.stops,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GradientStyle &&
        other.id == id &&
        other.colors == colors &&
        other.stops == stops &&
        other.begin == begin &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(colors),
    Object.hashAll(stops),
    begin,
    end,
  );
}
