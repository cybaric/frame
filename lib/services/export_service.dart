import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

/// Progress model for export operation
class ExportProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final bool isComplete;
  final String? error;

  const ExportProgress({
    required this.progress,
    required this.status,
    this.isComplete = false,
    this.error,
  });

  ExportProgress.rendering()
    : progress = 0.0,
      status = 'Rendering image...',
      isComplete = false,
      error = null;

  ExportProgress.encoding(double percent)
    : progress = 0.3 + (percent * 0.5),
      status = 'Encoding PNG...',
      isComplete = false,
      error = null;

  ExportProgress.saving(double percent)
    : progress = 0.8 + (percent * 0.2),
      status = 'Saving to gallery...',
      isComplete = false,
      error = null;

  ExportProgress.complete()
    : progress = 1.0,
      status = 'Export complete!',
      isComplete = true,
      error = null;

  ExportProgress.failed(String errorMessage)
    : progress = 0.0,
      status = 'Export failed',
      isComplete = true,
      error = errorMessage;
}

/// Service for exporting images with progress tracking
class ExportService {
  /// Export image to gallery with progress tracking
  /// Note: All operations run on main thread due to plugin requirements
  static Stream<ExportProgress> exportImageToGallery({
    required RenderRepaintBoundary boundary,
    required String fileName,
    required double pixelRatio,
  }) async* {
    try {
      // Step 1: Rendering (0-30%)
      yield ExportProgress.rendering();

      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture image on main thread (required for rendering)
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      // Step 2: Start encoding (30%)
      yield ExportProgress.encoding(0.0);
      await Future.delayed(const Duration(milliseconds: 50));

      // Convert to PNG bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        yield ExportProgress.failed('Failed to convert image to bytes');
        return;
      }

      // Step 3: Encoding progress (50%)
      yield ExportProgress.encoding(0.5);
      await Future.delayed(const Duration(milliseconds: 50));

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Step 4: Encoding complete (80%)
      yield ExportProgress.encoding(1.0);
      await Future.delayed(const Duration(milliseconds: 50));

      // Step 5: Saving to gallery (80-100%)
      yield ExportProgress.saving(0.0);
      await Future.delayed(const Duration(milliseconds: 50));

      // Save to gallery on main thread (plugin requires this)
      final saveResult = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        name: '$fileName.png',
      );

      yield ExportProgress.saving(0.5);
      await Future.delayed(const Duration(milliseconds: 50));

      // Check result
      if (saveResult['isSuccess'] == true) {
        yield ExportProgress.saving(1.0);
        await Future.delayed(const Duration(milliseconds: 100));
        yield ExportProgress.complete();
      } else {
        yield ExportProgress.failed(
          'Failed to save: ${saveResult['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      yield ExportProgress.failed(e.toString());
    }
  }
}
