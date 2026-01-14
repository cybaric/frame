import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../domain/entities/frame_path_style.dart';

class GradientPickerDialog extends StatefulWidget {
  final FramePathStyle initialStyle;
  final Function(FramePathStyle) onStyleChanged;

  const GradientPickerDialog({
    super.key,
    required this.initialStyle,
    required this.onStyleChanged,
  });

  @override
  State<GradientPickerDialog> createState() => _GradientPickerDialogState();
}

class _GradientPickerDialogState extends State<GradientPickerDialog> {
  late bool _isGradient;
  late Color _solidColor;
  late List<Color> _gradientColors;
  late List<double> _gradientStops;
  Alignment _beginAlignment = Alignment.centerLeft;
  Alignment _endAlignment = Alignment.centerRight;

  @override
  void initState() {
    super.initState();
    if (widget.initialStyle is SolidColorStyle) {
      _isGradient = false;
      _solidColor = (widget.initialStyle as SolidColorStyle).color;
      _gradientColors = [Colors.blue, Colors.purple];
      _gradientStops = [0.0, 1.0];
      // Default to Left-Right
      _beginAlignment = Alignment.centerLeft;
      _endAlignment = Alignment.centerRight;
    } else {
      _isGradient = true;
      final style = widget.initialStyle as GradientStyle;
      _solidColor = style.colors.firstOrNull ?? Colors.black;
      _gradientColors = List.from(style.colors);
      _gradientStops = List.from(style.stops);
      _beginAlignment = style.begin;
      _endAlignment = style.end;
      if (_gradientColors.isEmpty) {
        _gradientColors = [Colors.blue, Colors.purple];
        _gradientStops = [0.0, 1.0];
      }
    }
  }

  void _submit() {
    if (_isGradient) {
      widget.onStyleChanged(
        GradientStyle(
          id: 'linearGradient${DateTime.now().millisecondsSinceEpoch}',
          colors: _gradientColors,
          stops: _gradientStops,
          begin: _beginAlignment,
          end: _endAlignment,
        ),
      );
    } else {
      widget.onStyleChanged(SolidColorStyle(_solidColor));
    }
  }

  void _setDirection(String type) {
    setState(() {
      switch (type) {
        case 'Horizontal':
          _beginAlignment = Alignment.centerLeft;
          _endAlignment = Alignment.centerRight;
          break;
        case 'Vertical':
          _beginAlignment = Alignment.topCenter;
          _endAlignment = Alignment.bottomCenter;
          break;
        case 'Diagonal':
          _beginAlignment = Alignment.bottomLeft;
          _endAlignment = Alignment.topRight;
          break;
      }
    });
  }

  String _getCurrentDirection() {
    if (_beginAlignment == Alignment.centerLeft &&
        _endAlignment == Alignment.centerRight) {
      return 'Horizontal';
    }
    if (_beginAlignment == Alignment.topCenter &&
        _endAlignment == Alignment.bottomCenter) {
      return 'Vertical';
    }
    if (_beginAlignment == Alignment.bottomLeft &&
        _endAlignment == Alignment.topRight) {
      return 'Diagonal';
    }
    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Style'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<bool>(
              groupValue: _isGradient,
              onChanged: (v) => setState(() => _isGradient = v!),
              child: Column(
                children: [
                  RadioListTile<bool>(title: const Text('Solid'), value: false),
                  RadioListTile<bool>(
                    title: const Text('Gradient'),
                    value: true,
                  ),
                ],
              ),
            ),
            const Divider(),
            if (!_isGradient) ...[
              ColorPicker(
                pickerColor: _solidColor,
                onColorChanged: (c) => setState(() => _solidColor = c),
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
              ),
            ] else ...[
              DropdownButton<String>(
                value:
                    [
                      'Horizontal',
                      'Vertical',
                      'Diagonal',
                    ].contains(_getCurrentDirection())
                    ? _getCurrentDirection()
                    : null,
                hint: const Text('Direction'),
                isExpanded: true,
                items: ['Horizontal', 'Vertical', 'Diagonal'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _setDirection(val);
                },
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientColors,
                    stops: _gradientStops,
                    begin: _beginAlignment,
                    end: _endAlignment,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorButton(0),
                  const Icon(Icons.arrow_right_alt),
                  _buildColorButton(1),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _submit();
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildColorButton(int index) {
    if (index >= _gradientColors.length) return const SizedBox();
    return GestureDetector(
      onTap: () async {
        Color tempColor = _gradientColors[index];
        final newColor = await showDialog<Color>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Pick Color'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: tempColor,
                      onColorChanged: (c) => setState(() => tempColor = c),
                      enableAlpha: false,
                      displayThumbColor: true,
                      pickerAreaHeightPercent: 0.7,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, tempColor),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (newColor != null && mounted) {
          setState(() {
            _gradientColors[index] = newColor;
          });
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _gradientColors[index],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
}
