import 'frame_path_style.dart';

class Frame {
  final String id;
  final String name;
  final String svgString;
  final Map<String, FramePathStyle>
  pathStyles; // Map of path index or id to style

  Frame({
    required this.id,
    required this.name,
    required this.svgString,
    required this.pathStyles,
  });

  Frame copyWith({
    String? id,
    String? name,
    String? svgString,
    Map<String, FramePathStyle>? pathStyles,
  }) {
    return Frame(
      id: id ?? this.id,
      name: name ?? this.name,
      svgString: svgString ?? this.svgString,
      pathStyles: pathStyles ?? this.pathStyles,
    );
  }
}
