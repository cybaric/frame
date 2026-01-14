import 'package:flutter/material.dart';
import '../../domain/models/export_models.dart';

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
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final accent2 = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final border = theme.colorScheme.outline;
    final text = theme.colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: surface,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: text),
      title: const Text('Export Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: text),
            cursorColor: accent,
            decoration: InputDecoration(
              labelText: 'File Name',
              hintText: 'Enter file name',
              labelStyle: TextStyle(color: text),
              hintStyle: TextStyle(color: text.withValues(alpha: 0.6)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExportQuality>(
            initialValue: _selectedQuality,
            dropdownColor: surface,
            iconEnabledColor: accent2,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              labelText: 'Quality',
              labelStyle: TextStyle(color: text),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent2, width: 1.5),
              ),
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
                child: Text(label, style: TextStyle(color: text)),
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
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        TextButton(
          style: TextButton.styleFrom(foregroundColor: accent),
          onPressed: () {
            Navigator.of(context).pop({
              'name': _nameController.text.trim().isEmpty
                  ? widget.defaultName
                  : _nameController.text.trim(),
              'quality': _selectedQuality,
            });
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
