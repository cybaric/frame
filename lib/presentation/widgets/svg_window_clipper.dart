import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../../domain/models/export_models.dart';

class SvgWindowClipper extends CustomClipper<Path> {
  final ExportSpec? exportSpec;

  const SvgWindowClipper(this.exportSpec);

  @override
  Path getClip(Size size) {
    final spec = exportSpec;
    if (spec == null ||
        spec.width == 0 ||
        spec.height == 0 ||
        spec.pathDs.isEmpty) {
      return Path()..addRect(Offset.zero & size);
    }

    // Pick the smallest-area contour across all paths as the window/opening.
    // This matches typical frames where the outer frame is bigger and the inner opening is smaller.
    Path? best;
    double bestArea = double.infinity;

    for (final d in spec.pathDs) {
      Path parsed;
      try {
        parsed = parseSvgPathData(d);
      } catch (_) {
        continue;
      }

      // Split into contours if needed (single <path> can contain multiple subpaths).
      final metrics = parsed.computeMetrics(forceClosed: false).toList();
      if (metrics.isEmpty) continue;

      for (final metric in metrics) {
        final contour = metric.extractPath(0, metric.length);
        final b = contour.getBounds();
        final area = (b.width * b.height).abs();
        if (area > 0 && area < bestArea) {
          bestArea = area;
          best = contour;
        }
      }
    }

    if (best == null) {
      return Path()..addRect(Offset.zero & size);
    }

    final sx = size.width / spec.width;
    final sy = size.height / spec.height;

    final m = Matrix4.identity()
      ..translateByDouble(-spec.minX, -spec.minY, 0.0, 1.0)
      ..scaleByDouble(sx, sy, 1.0, 1.0);

    return best.transform(m.storage);
  }

  @override
  bool shouldReclip(covariant SvgWindowClipper oldClipper) {
    return oldClipper.exportSpec?.pathDs != exportSpec?.pathDs ||
        oldClipper.exportSpec?.minX != exportSpec?.minX ||
        oldClipper.exportSpec?.minY != exportSpec?.minY ||
        oldClipper.exportSpec?.width != exportSpec?.width ||
        oldClipper.exportSpec?.height != exportSpec?.height;
  }
}
