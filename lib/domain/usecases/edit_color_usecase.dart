import 'package:xml/xml.dart';

import '../entities/frame.dart';
import '../entities/frame_path_style.dart';
import '../repositories/svg_repository.dart';

class EditColorUseCase {
  final SvgRepository repository;

  EditColorUseCase(this.repository);

  Future<Frame> call(Frame frame, String pathId, FramePathStyle style) async {
    final document = XmlDocument.parse(frame.svgString);
    final paths = document.findAllElements('path');

    if (int.tryParse(pathId) != null) {
      final index = int.parse(pathId);
      if (index < paths.length) {
        final path = paths.elementAt(index);

        switch (style) {
          case SolidColorStyle(color: final color):
            // Convert Color to hex string #RRGGBB or #AARRGGBB
            // Svg usually wants #RRGGBB.
            final hex =
                '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
            path.setAttribute('fill', hex);
            break;
          case GradientStyle(
            id: final id,
            colors: final colors,
            stops: final stops,
          ):
            // 1. Ensure <defs> exists
            var defs = document.findAllElements('defs').firstOrNull;
            if (defs == null) {
              defs = XmlElement(XmlName('defs'));
              document.rootElement.children.insert(0, defs);
            }

            // 2. Check if linearGradient with id exists, update or create
            var lg = defs
                .findAllElements('linearGradient')
                .where((node) => node.getAttribute('id') == id)
                .firstOrNull;

            if (lg != null) {
              // Remove existing stops
              lg.children.clear();
            } else {
              lg = XmlElement(XmlName('linearGradient'));
              lg.setAttribute('id', id);
              lg.setAttribute('gradientUnits', 'objectBoundingBox');

              // Map Alignment (-1..1) to (0%..100%)
              // Alignment.centerLeft (-1, 0) -> x=0%, y=50%
              // But standard linear gradient usually implies start to end.
              // Let's assume standard Flutter LinearGradient behavior mapping.
              // x = (alignment.x + 1) / 2 * 100
              // y = (alignment.y + 1) / 2 * 100

              final x1 = (style.begin.x + 1) / 2 * 100;
              final y1 = (style.begin.y + 1) / 2 * 100;
              final x2 = (style.end.x + 1) / 2 * 100;
              final y2 = (style.end.y + 1) / 2 * 100;

              lg.setAttribute('x1', '${x1.toStringAsFixed(1)}%');
              lg.setAttribute('y1', '${y1.toStringAsFixed(1)}%');
              lg.setAttribute('x2', '${x2.toStringAsFixed(1)}%');
              lg.setAttribute('y2', '${y2.toStringAsFixed(1)}%');
              defs.children.add(lg);
            }

            // 3. Add stops
            for (int i = 0; i < colors.length; i++) {
              final color = colors[i];
              final stop = stops[i];
              final stopEl = XmlElement(XmlName('stop'));
              stopEl.setAttribute(
                'offset',
                '${(stop * 100).toStringAsFixed(1)}%',
              );
              final hex =
                  '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
              stopEl.setAttribute('stop-color', hex);
              lg.children.add(stopEl);
            }

            path.setAttribute('fill', 'url(#$id)');
            break;
        }
      }
    }
    final modifiedSvg = document.toXmlString();
    final updatedFrame = frame.copyWith(svgString: modifiedSvg);
    // Update pathStyles map
    final updatedStyles = Map<String, FramePathStyle>.from(frame.pathStyles);
    updatedStyles[pathId] = style;
    return updatedFrame.copyWith(pathStyles: updatedStyles);
  }
}
