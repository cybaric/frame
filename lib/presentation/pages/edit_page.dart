import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../providers/frame_provider.dart';
import '../providers/image_edit_provider.dart';
import '../../domain/entities/frame_path_style.dart';
import '../../domain/models/export_models.dart';
import '../../utils/svg_utils.dart';
import '../../services/export_service.dart';
import '../widgets/gradient_picker_dialog.dart';
import '../widgets/checkerboard_painter.dart';
import '../widgets/export_canvas.dart';
import '../widgets/export_options_dialog.dart';
import '../widgets/export_progress_dialog.dart';
import '../widgets/edit_mode_switcher.dart';

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
      ref.read(imageLayersProvider.notifier).addLayer(bytes);
      if (!mounted) return;
      setState(() {
        _isImportingImage = false;
        _editMode = EditMode.image;
      });
    } catch (e) {
      if (!context.mounted) return;
      if (mounted) {
        setState(() {
          _isImportingImage = false;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _resetImageTransform() {
    ref.read(imageLayersProvider.notifier).resetActiveTransform();
  }

  void _removeImportedImage() {
    ref.read(imageLayersProvider.notifier).removeActiveLayer();
    setState(() {
      final state = ref.read(imageLayersProvider);
      _editMode = state.layers.isEmpty ? EditMode.frame : EditMode.image;
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

    // Request permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }

    try {
      // Set exporting state to show export canvas
      if (mounted) {
        setState(() {
          _isExporting = true;
        });
      }

      // Let the UI rebuild and paint the export-only canvas
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export failed: export canvas not ready'),
          ),
        );
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

      // Calculate pixel ratio based on quality
      double pixelRatio;
      switch (quality) {
        case ExportQuality.low:
          pixelRatio = 2.0;
          break;
        case ExportQuality.medium:
          pixelRatio = 4.0;
          break;
        case ExportQuality.high:
          pixelRatio = 8.0;
          break;
      }

      // Create export stream
      final exportStream = ExportService.exportImageToGallery(
        boundary: boundary,
        fileName: fileName,
        pixelRatio: pixelRatio,
      );

      // Show progress dialog
      if (!context.mounted) return;
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            ExportProgressDialog(progressStream: exportStream),
      );

      // Reset exporting state
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }

      // Show result
      if (!context.mounted) return;
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported to gallery successfully!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export failed')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
      if (!context.mounted) return;
      debugPrint('Export error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final framesAsync = ref.watch(framesProvider);
    final editUseCase = ref.watch(editColorUseCaseProvider);
    final imageLayersState = ref.watch(imageLayersProvider);
    final activeLayer = imageLayersState.activeLayer;

    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final accent2 = theme.colorScheme.primary;
    final inactive = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return framesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (frames) {
        final frame = frames.firstWhere((f) => f.id == widget.frameId);

        final exportSpec = tryParseExportSpec(frame.svgString);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            context.go('/');
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              foregroundColor: theme.colorScheme.onSurface,
              titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              title: Text('Edit ${frame.name}'),
              actions: [
                PopupMenuButton<String>(
                  iconColor: accent,
                  onSelected: (value) {
                    if (value == 'export') {
                      _exportToPng(context, frame);
                    } else if (value == 'import') {
                      _importImage(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'export', child: Text('Export')),
                    const PopupMenuItem(
                      value: 'import',
                      child: Text('Import Image'),
                    ),
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
                            ? ExportCanvas(
                                svgString: frame.svgString,
                                layers: imageLayersState.layers,
                                exportSpec: exportSpec,
                              )
                            : CustomPaint(
                                painter: CheckerboardPainter(),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    for (final layer in imageLayersState.layers)
                                      ClipRect(
                                        child: Center(
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
                                              ..scaleByDouble(
                                                layer.scale,
                                                layer.scale,
                                                1.0,
                                                1.0,
                                              ),
                                            child: Image.memory(
                                              layer.bytes,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    SvgPicture.string(
                                      frame.svgString,
                                      fit: BoxFit.contain,
                                    ),
                                    if (!_isImportingImage &&
                                        activeLayer != null &&
                                        _editMode == EditMode.image)
                                      Positioned.fill(
                                        child: Builder(
                                          builder: (context) {
                                            return GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onScaleStart: (details) {
                                                final box =
                                                    context.findRenderObject()
                                                        as RenderBox?;
                                                final localFocal = box == null
                                                    ? details.focalPoint
                                                    : box.globalToLocal(
                                                        details.focalPoint,
                                                      );
                                                final current = ref
                                                    .read(imageLayersProvider)
                                                    .activeLayer;
                                                if (current == null) return;
                                                setState(() {
                                                  _startFocalPoint = localFocal;
                                                  _baseOffset = current.offset;
                                                  _baseScale = current.scale;
                                                  _baseRotation =
                                                      current.rotation;
                                                });
                                              },
                                              onScaleUpdate: (details) {
                                                final box =
                                                    context.findRenderObject()
                                                        as RenderBox?;
                                                final localFocal = box == null
                                                    ? details.focalPoint
                                                    : box.globalToLocal(
                                                        details.focalPoint,
                                                      );
                                                final delta =
                                                    localFocal -
                                                    _startFocalPoint;
                                                final updatedOffset =
                                                    _baseOffset + delta;
                                                final updatedScale =
                                                    (_baseScale * details.scale)
                                                        .clamp(0.2, 10.0);
                                                final updatedRotation =
                                                    _baseRotation +
                                                    details.rotation;
                                                ref
                                                    .read(
                                                      imageLayersProvider
                                                          .notifier,
                                                    )
                                                    .updateActiveTransform(
                                                      offset: updatedOffset,
                                                      scale: updatedScale,
                                                      rotation: updatedRotation,
                                                    );
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
                          child: Column(
                            children: [
                              Expanded(
                                child: ReorderableListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  itemCount: imageLayersState.layers.length,
                                  onReorder: (oldIndex, newIndex) {
                                    ref
                                        .read(imageLayersProvider.notifier)
                                        .reorder(oldIndex, newIndex);
                                  },
                                  itemBuilder: (context, index) {
                                    final layer =
                                        imageLayersState.layers[index];
                                    final isActive =
                                        layer.id ==
                                        imageLayersState.activeLayerId;
                                    return ListTile(
                                      key: ValueKey(layer.id),
                                      onTap: () => ref
                                          .read(imageLayersProvider.notifier)
                                          .setActive(layer.id),
                                      leading: Icon(
                                        isActive
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isActive ? accent : inactive,
                                      ),
                                      title: Text(
                                        'Gambar ${index + 1}',
                                        style: TextStyle(
                                          color: isActive
                                              ? theme.colorScheme.onSurface
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isActive
                                            ? 'Aktif'
                                            : 'Ketuk untuk pilih',
                                        style: TextStyle(color: inactive),
                                      ),
                                      trailing: Icon(
                                        Icons.drag_handle,
                                        color: inactive.withValues(alpha: 0.9),
                                      ),
                                    );
                                  },
                                ),
                              ),
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
                                    color: _editMode == EditMode.frame
                                        ? accent2
                                        : inactive,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.image_outlined),
                                    onPressed: imageLayersState.layers.isEmpty
                                        ? null
                                        : () {
                                            setState(() {
                                              _editMode = EditMode.image;
                                            });
                                          },
                                    color: _editMode == EditMode.image
                                        ? accent
                                        : inactive,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                    ),
                                    onPressed: _isImportingImage
                                        ? null
                                        : () => _importImage(context),
                                    color: _isImportingImage
                                        ? inactive.withValues(alpha: 0.45)
                                        : accent2,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: activeLayer == null
                                        ? null
                                        : _resetImageTransform,
                                    color: activeLayer == null
                                        ? inactive.withValues(alpha: 0.45)
                                        : accent,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: activeLayer == null
                                        ? null
                                        : _removeImportedImage,
                                    color: activeLayer == null
                                        ? inactive.withValues(alpha: 0.45)
                                        : theme.colorScheme.error,
                                  ),
                                ],
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
                                  color: _editMode == EditMode.frame
                                      ? accent2
                                      : inactive,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.image_outlined),
                                  onPressed: imageLayersState.layers.isEmpty
                                      ? null
                                      : () {
                                          setState(() {
                                            _editMode = EditMode.image;
                                          });
                                        },
                                  color: _editMode == EditMode.image
                                      ? accent
                                      : inactive,
                                ),
                              ],
                            ),
                            Expanded(
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: frame.pathStyles.entries.map((entry) {
                                  final pathId = entry.key;
                                  final currentStyle = entry.value;
                                  return GestureDetector(
                                    onTap: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (context) =>
                                            GradientPickerDialog(
                                              initialStyle: currentStyle,
                                              onStyleChanged: (newStyle) {
                                                editUseCase
                                                    .call(
                                                      frame,
                                                      pathId,
                                                      newStyle,
                                                    )
                                                    .then((updatedFrame) {
                                                      ref
                                                          .read(
                                                            framesProvider
                                                                .notifier,
                                                          )
                                                          .updateFrame(
                                                            updatedFrame,
                                                          );
                                                    });
                                              },
                                            ),
                                      );
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: currentStyle is SolidColorStyle
                                            ? currentStyle.color
                                            : null,
                                        gradient: currentStyle is GradientStyle
                                            ? LinearGradient(
                                                colors: currentStyle.colors
                                                    .map(
                                                      (
                                                        c,
                                                      ) => HSLColor.fromColor(c)
                                                          .withSaturation(0.9)
                                                          .withLightness(0.6)
                                                          .toColor(),
                                                    )
                                                    .toList(),
                                                stops: currentStyle.stops,
                                                begin: currentStyle.begin,
                                                end: currentStyle.end,
                                              )
                                            : null,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black.withValues(
                                            alpha: 0.18,
                                          ),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
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
          ),
        );
      },
    );
  }
}
