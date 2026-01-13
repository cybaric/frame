import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/frame.dart';
import '../../domain/repositories/svg_repository.dart';

class SvgRepositoryImpl implements SvgRepository {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<List<Frame>> getAllFrames() async {
    final frames = <Frame>[];

    // Load drawing.svg
    try {
      final svg1 = await rootBundle.loadString('assets/drawing.svg');
      final pathColors1 = _parsePathColors(svg1);
      frames.add(Frame(id: '1', name: 'Drawing Frame', svgString: svg1, pathColors: pathColors1));
    } catch (e) {
      // Handle error
    }

    // Load frame1.svg
    try {
      final svg2 = await rootBundle.loadString('assets/frame1.svg');
      final pathColors2 = _parsePathColors(svg2);
      frames.add(Frame(id: '2', name: 'Rectangle Frame', svgString: svg2, pathColors: pathColors2));
    } catch (e) {
      // Handle error
    }

    // Load frame2.svg
    try {
      final svg3 = await rootBundle.loadString('assets/frame2.svg');
      final pathColors3 = _parsePathColors(svg3);
      frames.add(Frame(id: '3', name: 'Diamond Frame', svgString: svg3, pathColors: pathColors3));
    } catch (e) {
      // Handle error
    }

    return frames;
  }

  Map<String, String> _parsePathColors(String svgString) {
    final document = XmlDocument.parse(svgString);
    final paths = document.findAllElements('path').toList();
    final pathColors = <String, String>{};
    for (int i = 0; i < paths.length; i++) {
      final fill = paths[i].getAttribute('fill') ?? '#000000';
      pathColors[i.toString()] = fill;
    }
    return pathColors;
  }

  @override
  Future<Frame> loadSvg(String id) async {
    // Load from assets or mock
    final frames = await getAllFrames();
    return frames.firstWhere((f) => f.id == id);
  }

  @override
  Future<Frame> editColor(Frame frame, String pathId, String color) async {
    // This is handled in use case, but can be here if needed
    return frame; // Placeholder
  }

  @override
  Future<Frame> importFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final svgString = String.fromCharCodes(bytes); // Assume it's SVG
      return Frame(
        id: DateTime.now().toString(),
        name: 'Imported Frame',
        svgString: svgString,
        pathColors: {}, // Parse later if needed
      );
    }
    throw Exception('No file selected');
  }

  @override
  Future<void> exportToPng(Frame frame, String path) async {
    // This requires rendering the SVG to image, which is complex
    // For now, placeholder
    // Use RepaintBoundary or something, but need widget context
    // Perhaps return the path or save
  }
}