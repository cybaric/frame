class Frame {
  final String id;
  final String name;
  final String svgString;
  final Map<String, String> pathColors; // Map of path index or id to color

  Frame({
    required this.id,
    required this.name,
    required this.svgString,
    required this.pathColors,
  });

  Frame copyWith({
    String? id,
    String? name,
    String? svgString,
    Map<String, String>? pathColors,
  }) {
    return Frame(
      id: id ?? this.id,
      name: name ?? this.name,
      svgString: svgString ?? this.svgString,
      pathColors: pathColors ?? this.pathColors,
    );
  }
}