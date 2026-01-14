import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/export_models.dart';
import '../providers/image_edit_provider.dart';
import 'svg_window_clipper.dart';

class ExportCanvas extends StatelessWidget {
  final String svgString;
  final List<ImageLayer> layers;
  final ExportSpec? exportSpec;

  const ExportCanvas({
    super.key,
    required this.svgString,
    required this.layers,
    required this.exportSpec,
  });

  @override
  Widget build(BuildContext context) {
    final spec = exportSpec;
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (layers.isNotEmpty)
            ClipPath(
              clipper: SvgWindowClipper(spec),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final layer in layers)
                    Center(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(
                            layer.offset.dx,
                            layer.offset.dy,
                            0.0,
                            1.0,
                          )
                          ..rotateZ(layer.rotation)
                          ..scaleByDouble(layer.scale, layer.scale, 1.0, 1.0),
                        child: Image.memory(layer.bytes, fit: BoxFit.contain),
                      ),
                    ),
                ],
              ),
            ),
          SvgPicture.string(svgString, fit: BoxFit.contain),
        ],
      ),
    );
  }
}
