import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

import '../providers/frame_provider.dart';

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.grey[300]!;
    final paint2 = Paint()..color = Colors.grey[100]!;
    const squareSize = 20.0;

    for (double i = 0; i < size.width; i += squareSize) {
      for (double j = 0; j < size.height; j += squareSize) {
        final paint = ((i / squareSize).floor() + (j / squareSize).floor()) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(Rect.fromLTWH(i, j, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum ExportQuality { low, medium, high }

class EditPage extends ConsumerWidget {
  final String frameId;
  final GlobalKey _globalKey = GlobalKey();

  EditPage({super.key, required this.frameId});

  Future<void> _importImage(BuildContext context) async {
    // Placeholder for import image functionality
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Image feature coming soon!')));
  }

  Future<void> _exportToPng(BuildContext context, frame) async {
    // Show dialog for export options
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExportOptionsDialog(defaultName: frame.name),
    );

    if (result == null) return; // User cancelled

    final fileName = result['name'] as String;
    final quality = result['quality'] as ExportQuality;

    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        double pixelRatio;
        switch (quality) {
          case ExportQuality.low:
            pixelRatio = 1.0;
            break;
          case ExportQuality.medium:
            pixelRatio = 2.0;
            break;
          case ExportQuality.high:
            pixelRatio = 3.0;
            break;
        }
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();
        final saveResult = await ImageGallerySaverPlus.saveImage(pngBytes, name: '$fileName.png');
        if (saveResult['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported to gallery successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to export')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final framesAsync = ref.watch(framesProvider);
    final editUseCase = ref.watch(editColorUseCaseProvider);

    return framesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (frames) {
        final frame = frames.firstWhere((f) => f.id == frameId);
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
            title: Text('Edit ${frame.name}'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'export') {
                    _exportToPng(context, frame);
                  } else if (value == 'fullscreen') {
                    context.go('/preview/$frameId');
                  } else if (value == 'import') {
                    _importImage(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'export', child: Text('Export')),
                  const PopupMenuItem(value: 'fullscreen', child: Text('Fullscreen Preview')),
                  const PopupMenuItem(value: 'import', child: Text('Import Image')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: RepaintBoundary(
                  key: _globalKey,
                  child: CustomPaint(
                    painter: CheckerboardPainter(),
                    child: SvgPicture.string(frame.svgString),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: frame.pathColors.entries.map((entry) {
                    final pathId = entry.key;
                    final currentColor = entry.value;
                    return GestureDetector(
                      onTap: () async {
                        Color pickedColor = Color(int.parse(currentColor.replaceFirst('#', ''), radix: 16) + 0xFF000000);
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: pickedColor,
                                onColorChanged: (color) => pickedColor = color,
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: const Text('Select'),
                                onPressed: () {
                                  final hexColor = '#${pickedColor.value.toRadixString(16).substring(2)}';
                                  editUseCase.call(frame, pathId, hexColor).then((updatedFrame) {
                                    ref.read(framesProvider.notifier).updateFrame(updatedFrame);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(currentColor.replaceFirst('#', ''), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                          //border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExportOptionsDialog extends StatefulWidget {
  final String defaultName;

  const ExportOptionsDialog({super.key, required this.defaultName});

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  late TextEditingController _nameController;
  ExportQuality _selectedQuality = ExportQuality.medium;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'File Name',
              hintText: 'Enter file name',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExportQuality>(
            value: _selectedQuality,
            decoration: const InputDecoration(
              labelText: 'Quality',
            ),
            items: ExportQuality.values.map((quality) {
              String label;
              switch (quality) {
                case ExportQuality.low:
                  label = 'Low';
                  break;
                case ExportQuality.medium:
                  label = 'Medium';
                  break;
                case ExportQuality.high:
                  label = 'High';
                  break;
              }
              return DropdownMenuItem(
                value: quality,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedQuality = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'name': _nameController.text.trim().isEmpty ? widget.defaultName : _nameController.text.trim(),
              'quality': _selectedQuality,
            });
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}