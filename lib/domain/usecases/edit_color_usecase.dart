import 'package:xml/xml.dart';

import '../entities/frame.dart';
import '../repositories/svg_repository.dart';

class EditColorUseCase {
  final SvgRepository repository;

  EditColorUseCase(this.repository);

  Future<Frame> call(Frame frame, String pathId, String color) async {
    // For now, implement simple XML parsing here, but ideally in repository
    // But since use case can have logic, let's do it here
    final document = XmlDocument.parse(frame.svgString);
    final paths = document.findAllElements('path');
    if (int.tryParse(pathId) != null) {
      final index = int.parse(pathId);
      if (index < paths.length) {
        paths.elementAt(index).setAttribute('fill', color);
      }
    }
    final modifiedSvg = document.toXmlString();
    final updatedFrame = frame.copyWith(svgString: modifiedSvg);
    // Update pathColors map
    final updatedColors = Map<String, String>.from(frame.pathColors);
    updatedColors[pathId] = color;
    return updatedFrame.copyWith(pathColors: updatedColors);
  }
}