import 'package:flutter/material.dart';
import '../../services/export_service.dart';

class ExportProgressDialog extends StatelessWidget {
  final Stream<ExportProgress> progressStream;

  const ExportProgressDialog({super.key, required this.progressStream});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest;
    final accent = theme.colorScheme.secondary;
    final text = theme.colorScheme.onSurface;

    return PopScope(
      canPop: false, // Prevent dismissing during export
      child: Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: StreamBuilder<ExportProgress>(
            stream: progressStream,
            builder: (context, snapshot) {
              final progress = snapshot.data;

              if (progress == null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: accent),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: theme.textTheme.bodyMedium?.copyWith(color: text),
                    ),
                  ],
                );
              }

              // Auto close on complete
              if (progress.isComplete && progress.error == null) {
                Future.microtask(() {
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              }

              // Show error
              if (progress.error != null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Export Failed',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: text.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Icon(Icons.downloading, size: 48, color: accent),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Exporting Image',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status text
                  Text(
                    progress.status,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: text.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 8,
                      backgroundColor: text.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Percentage
                  Text(
                    '${(progress.progress * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
