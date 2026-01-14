import 'package:xml/xml.dart';
import '../domain/models/export_models.dart';

ExportSpec? tryParseExportSpec(String svgString) {
  try {
    final doc = XmlDocument.parse(svgString);
    final svg = doc.findAllElements('svg').first;
    final viewBox = svg.getAttribute('viewBox');
    if (viewBox == null) return null;

    final parts = viewBox
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.length != 4) return null;

    final minX = double.tryParse(parts[0]) ?? 0.0;
    final minY = double.tryParse(parts[1]) ?? 0.0;
    final w = double.tryParse(parts[2]) ?? 0.0;
    final h = double.tryParse(parts[3]) ?? 0.0;

    final ds = doc
        .findAllElements('path')
        .map((p) => p.getAttribute('d'))
        .whereType<String>()
        .where((d) => d.trim().isNotEmpty)
        .toList();

    return ExportSpec(minX: minX, minY: minY, width: w, height: h, pathDs: ds);
  } catch (_) {
    return null;
  }
}
