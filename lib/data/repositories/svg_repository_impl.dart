import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:image_picker/image_picker.dart';
import 'package:xml/xml.dart';

import 'package:flutter/widgets.dart';
import '../../domain/entities/frame_path_style.dart';
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

    final svgAssets =
        allAssets
            .where(
              (k) =>
                  k.startsWith('assets/') && k.toLowerCase().endsWith('.svg'),
            )
            .toList()
          ..sort();

    for (final assetPath in svgAssets) {
      try {
        final svgString = await rootBundle.loadString(assetPath);
        final pathStyles = _parsePathStyles(svgString);
        frames.add(
          Frame(
            id: assetPath,
            name: _nameFromAssetPath(assetPath),
            svgString: svgString,
            pathStyles: pathStyles,
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
    final base = file.toLowerCase().endsWith('.svg')
        ? file.substring(0, file.length - 4)
        : file;
    // simple title-case-ish
    final withSpaces = base.replaceAll(RegExp(r'[_\-]+'), ' ');
    if (withSpaces.isEmpty) return 'Frame';
    return withSpaces
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  Map<String, FramePathStyle> _parsePathStyles(String svgString) {
    final document = XmlDocument.parse(svgString);
    final paths = document.findAllElements('path').toList();
    final pathStyles = <String, FramePathStyle>{};

    // Parse linearGradients
    final gradients = <String, GradientStyle>{};
    final defs = document.findAllElements('defs');
    if (defs.isNotEmpty) {
      final linearGradients = defs.first.findAllElements('linearGradient');
      for (final lg in linearGradients) {
        final id = lg.getAttribute('id');
        if (id == null) continue;

        final stops = <double>[];
        final colors = <Color>[];

        for (final stop in lg.findAllElements('stop')) {
          final offsetStr = stop.getAttribute('offset') ?? '0';
          // Handle % or 0..1
          double offset = 0;
          if (offsetStr.endsWith('%')) {
            offset =
                (double.tryParse(offsetStr.replaceAll('%', '')) ?? 0) / 100;
          } else {
            offset = double.tryParse(offsetStr) ?? 0;
          }
          stops.add(offset);

          final colorStr = stop.getAttribute('stop-color') ?? '#000000';
          colors.add(_parseColor(colorStr));
        }

        // Simple Alignment assumption based on coords if present, else defaults
        // For now, assuming standard TopLeft to BottomRight or Left to Right if not parsed
        // To be precise we should parse x1,y1,x2,y2
        // Let's parse them tentatively or use defaults
        gradients[id] = GradientStyle(
          id: id,
          colors: colors,
          stops: stops,
          // You might want to parse coordinates here for better accuracy
        );
      }
    }

    for (int i = 0; i < paths.length; i++) {
      final fill = paths[i].getAttribute('fill') ?? '#000000';
      if (fill.startsWith('url(#') && fill.endsWith(')')) {
        final id = fill.substring(5, fill.length - 1);
        if (gradients.containsKey(id)) {
          pathStyles[i.toString()] = gradients[id]!;
        } else {
          // Fallback or potentially error
          pathStyles[i.toString()] = const SolidColorStyle(Color(0xFF000000));
        }
      } else {
        pathStyles[i.toString()] = SolidColorStyle(_parseColor(fill));
      }
    }
    return pathStyles;
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.replaceAll('#', '');
        if (hex.length == 3) {
          final r = hex[0];
          final g = hex[1];
          final b = hex[2];
          return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
        } else if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
      return const Color(0xFF000000);
    } catch (_) {
      return const Color(0xFF000000);
    }
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
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final svgString = String.fromCharCodes(bytes); // Assume it's SVG
      return Frame(
        id: DateTime.now().toString(),
        name: 'Imported Frame',
        svgString: svgString,
        pathStyles: {}, // Parse later if needed
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
