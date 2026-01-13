import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:image_picker/image_picker.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/frame.dart';
import '../../domain/repositories/svg_repository.dart';

class SvgRepositoryImpl implements SvgRepository {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<List<Frame>> getAllFrames() async {
    final frames = <Frame>[];

    // Read assets from Flutter's AssetManifest (works across build modes and platforms)
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();

    final svgAssets = allAssets.where((k) => k.startsWith('assets/') && k.toLowerCase().endsWith('.svg')).toList()..sort();

    for (final assetPath in svgAssets) {
      try {
        final svgString = await rootBundle.loadString(assetPath);
        final pathColors = _parsePathColors(svgString);
        frames.add(
          Frame(
            id: assetPath,
            name: _nameFromAssetPath(assetPath),
            svgString: svgString,
            pathColors: pathColors,
          ),
        );
      } catch (e) {
        // Handle error
      }
    }

    return frames;
  }

  String _nameFromAssetPath(String assetPath) {
    final file = assetPath.split('/').last;
    final base = file.toLowerCase().endsWith('.svg') ? file.substring(0, file.length - 4) : file;
    // simple title-case-ish
    final withSpaces = base.replaceAll(RegExp(r'[_\-]+'), ' ');
    if (withSpaces.isEmpty) return 'Frame';
    return withSpaces
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
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