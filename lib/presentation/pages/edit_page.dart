import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_drawing/path_drawing.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:xml/xml.dart';
import 'package:flutter/scheduler.dart';

import '../providers/frame_provider.dart';

final importedImageBytesProvider = StateProvider<Uint8List?>((ref) => null);

enum EditMode { frame, image }

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

class EditPage extends ConsumerStatefulWidget {
  final String frameId;
  final GlobalKey _globalKey = GlobalKey();

  EditPage({super.key, required this.frameId});

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  EditMode _editMode = EditMode.frame;

  bool _isImportingImage = false;

  bool _isExporting = false;

  RenderRepaintBoundary? _getMainBoundary() {
    final ctx = widget._globalKey.currentContext;
    if (ctx == null) return null;
    final ro = ctx.findRenderObject();
    if (ro is RenderRepaintBoundary) return ro;
    return null;
  }

  Offset _imageOffset = Offset.zero;
  double _imageScale = 1.0;
  double _imageRotation = 0.0;

  Offset _startFocalPoint = Offset.zero;
  Offset _baseOffset = Offset.zero;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  Future<void> _importImage(BuildContext context) async {
    if (_isImportingImage) return;
    try {
      setState(() {
        _isImportingImage = true;
      });
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        if (!mounted) return;
        setState(() {
          _isImportingImage = false;
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      ref.read(importedImageBytesProvider.notifier).state = bytes;
      if (!mounted) return;
      setState(() {
        _isImportingImage = false;
        _editMode = EditMode.image;
        _imageOffset = Offset.zero;
        _imageScale = 1.0;
        _imageRotation = 0.0;
      });
    } catch (e) {
      if (!context.mounted) return;
      if (mounted) {
        setState(() {
          _isImportingImage = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _resetImageTransform() {
    setState(() {
      _imageOffset = Offset.zero;
      _imageScale = 1.0;
      _imageRotation = 0.0;
    });
  }

  void _removeImportedImage() {
    ref.read(importedImageBytesProvider.notifier).state = null;
    setState(() {
      _editMode = EditMode.frame;
      _imageOffset = Offset.zero;
      _imageScale = 1.0;
      _imageRotation = 0.0;
    });
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
        if (mounted) {
          setState(() {
            _isExporting = true;
          });
        }

        // Let the UI rebuild and paint the export-only canvas.
        await WidgetsBinding.instance.endOfFrame;
        await SchedulerBinding.instance.endOfFrame;

        final initialBoundary = _getMainBoundary();
        if (initialBoundary == null) {
          if (mounted) {
            setState(() {
              _isExporting = false;
            });
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Export failed: export canvas not ready')));
          return;
        }
        RenderRepaintBoundary boundary = initialBoundary;

        // In debug/profile, boundary might still need paint. Give it a few frames.
        var retries = 5;
        while (boundary.debugNeedsPaint && retries > 0) {
          await SchedulerBinding.instance.endOfFrame;
          final againBoundary = _getMainBoundary();
          if (againBoundary != null) boundary = againBoundary;
          retries--;
        }

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

        if (mounted) {
          setState(() {
            _isExporting = false;
          });
        }

        if (!context.mounted) return;
        debugPrint('Export saveResult: $saveResult');
        if (saveResult['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported to gallery successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $saveResult')));
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isExporting = false;
          });
        }
        if (!context.mounted) return;
        debugPrint('Export error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final framesAsync = ref.watch(framesProvider);
    final editUseCase = ref.watch(editColorUseCaseProvider);
    final importedImageBytes = ref.watch(importedImageBytesProvider);

    return framesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (frames) {
        final frame = frames.firstWhere((f) => f.id == widget.frameId);

        final exportSpec = _tryParseExportSpec(frame.svgString);
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
                    context.go('/preview/${widget.frameId}');
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
                child: Center(
                  child: AspectRatio(
                    aspectRatio: exportSpec?.aspectRatio ?? 1.0,
                    child: RepaintBoundary(
                      key: widget._globalKey,
                      child: _isExporting
                          ? _ExportCanvas(
                              svgString: frame.svgString,
                              importedImageBytes: importedImageBytes,
                              imageOffset: _imageOffset,
                              imageScale: _imageScale,
                              imageRotation: _imageRotation,
                              exportSpec: exportSpec,
                            )
                          : CustomPaint(
                              painter: CheckerboardPainter(),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (importedImageBytes != null)
                                    Center(
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..translateByDouble(_imageOffset.dx, _imageOffset.dy, 0.0, 1.0)
                                          ..rotateZ(_imageRotation)
                                          ..scaleByDouble(_imageScale, _imageScale, 1.0, 1.0),
                                        child: Image.memory(
                                          importedImageBytes,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  SvgPicture.string(
                                    frame.svgString,
                                    fit: BoxFit.contain,
                                  ),
                                  if (!_isImportingImage && importedImageBytes != null && _editMode == EditMode.image)
                                    Positioned.fill(
                                      child: Builder(
                                        builder: (context) {
                                          return GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onScaleStart: (details) {
                                              final box = context.findRenderObject() as RenderBox?;
                                              final localFocal = box == null
                                                  ? details.focalPoint
                                                  : box.globalToLocal(details.focalPoint);
                                              setState(() {
                                                _startFocalPoint = localFocal;
                                                _baseOffset = _imageOffset;
                                                _baseScale = _imageScale;
                                                _baseRotation = _imageRotation;
                                              });
                                            },
                                            onScaleUpdate: (details) {
                                              final box = context.findRenderObject() as RenderBox?;
                                              final localFocal = box == null
                                                  ? details.focalPoint
                                                  : box.globalToLocal(details.focalPoint);
                                              final delta = localFocal - _startFocalPoint;
                                              setState(() {
                                                _imageOffset = _baseOffset + delta;
                                                _imageScale = (_baseScale * details.scale).clamp(0.2, 10.0);
                                                _imageRotation = _baseRotation + details.rotation;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  if (_isImportingImage)
                                    const Positioned.fill(
                                      child: ColoredBox(
                                        color: Color(0x66000000),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _editMode == EditMode.image
                    ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.palette),
                              onPressed: () {
                                setState(() {
                                  _editMode = EditMode.frame;
                                });
                              },
                              color: _editMode == EditMode.frame ? Theme.of(context).colorScheme.primary : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.image_outlined),
                              onPressed: importedImageBytes == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _editMode = EditMode.image;
                                      });
                                    },
                              color: _editMode == EditMode.image ? Theme.of(context).colorScheme.primary : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: importedImageBytes == null ? null : _resetImageTransform,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: importedImageBytes == null ? null : _removeImportedImage,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.palette),
                                onPressed: () {
                                  setState(() {
                                    _editMode = EditMode.frame;
                                  });
                                },
                                color: _editMode == EditMode.frame ? Theme.of(context).colorScheme.primary : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.image_outlined),
                                onPressed: importedImageBytes == null
                                    ? null
                                    : () {
                                        setState(() {
                                          _editMode = EditMode.image;
                                        });
                                      },
                                color: _editMode == EditMode.image ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: frame.pathColors.entries.map((entry) {
                                final pathId = entry.key;
                                final currentColor = entry.value;
                                return GestureDetector(
                                  onTap: () async {
                                    Color pickedColor =
                                        Color(int.parse(currentColor.replaceFirst('#', ''), radix: 16) + 0xFF000000);
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
                                              final argb = pickedColor.toARGB32();
                                              final hexColor =
                                                  '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
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
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExportSpec {
  final double minX;
  final double minY;
  final double width;
  final double height;
  final List<String> pathDs;

  const _ExportSpec({
    required this.minX,
    required this.minY,
    required this.width,
    required this.height,
    required this.pathDs,
  });

  double get aspectRatio => width == 0 ? 1.0 : (width / height);
}

_ExportSpec? _tryParseExportSpec(String svgString) {
  try {
    final doc = XmlDocument.parse(svgString);
    final svg = doc.findAllElements('svg').first;
    final viewBox = svg.getAttribute('viewBox');
    if (viewBox == null) return null;

    final parts = viewBox.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
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

    return _ExportSpec(minX: minX, minY: minY, width: w, height: h, pathDs: ds);
  } catch (_) {
    return null;
  }
}

class _SvgWindowClipper extends CustomClipper<Path> {
  final _ExportSpec? exportSpec;

  const _SvgWindowClipper(this.exportSpec);

  @override
  Path getClip(Size size) {
    final spec = exportSpec;
    if (spec == null || spec.width == 0 || spec.height == 0 || spec.pathDs.isEmpty) {
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
  bool shouldReclip(covariant _SvgWindowClipper oldClipper) {
    return oldClipper.exportSpec?.pathDs != exportSpec?.pathDs ||
        oldClipper.exportSpec?.minX != exportSpec?.minX ||
        oldClipper.exportSpec?.minY != exportSpec?.minY ||
        oldClipper.exportSpec?.width != exportSpec?.width ||
        oldClipper.exportSpec?.height != exportSpec?.height;
  }
}

class _ExportCanvas extends StatelessWidget {
  final String svgString;
  final Uint8List? importedImageBytes;
  final Offset imageOffset;
  final double imageScale;
  final double imageRotation;
  final _ExportSpec? exportSpec;

  const _ExportCanvas({
    required this.svgString,
    required this.importedImageBytes,
    required this.imageOffset,
    required this.imageScale,
    required this.imageRotation,
    required this.exportSpec,
  });

  @override
  Widget build(BuildContext context) {
    final spec = exportSpec;
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (importedImageBytes != null)
            ClipPath(
              clipper: _SvgWindowClipper(spec),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(imageOffset.dx, imageOffset.dy, 0.0, 1.0)
                    ..rotateZ(imageRotation)
                    ..scaleByDouble(imageScale, imageScale, 1.0, 1.0),
                  child: Image.memory(
                    importedImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          SvgPicture.string(
            svgString,
            fit: BoxFit.contain,
          ),
        ],
      ),
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
            initialValue: _selectedQuality,
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