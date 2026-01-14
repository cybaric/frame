enum ExportQuality { low, medium, high }

class ExportSpec {
  final double minX;
  final double minY;
  final double width;
  final double height;
  final List<String> pathDs;

  const ExportSpec({
    required this.minX,
    required this.minY,
    required this.width,
    required this.height,
    required this.pathDs,
  });

  double get aspectRatio => width == 0 ? 1.0 : (width / height);
}
