import 'package:flutter/material.dart';

enum EditMode { frame, image }

class EditModeSwitcher extends StatelessWidget {
  final EditMode editMode;
  final bool hasImages;
  final ValueChanged<EditMode> onModeChanged;
  final Color activeColorFrame;
  final Color activeColorImage;
  final Color inactiveColor;

  const EditModeSwitcher({
    super.key,
    required this.editMode,
    required this.hasImages,
    required this.onModeChanged,
    required this.activeColorFrame,
    required this.activeColorImage,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.palette),
          onPressed: () => onModeChanged(EditMode.frame),
          color: editMode == EditMode.frame ? activeColorFrame : inactiveColor,
        ),
        IconButton(
          icon: const Icon(Icons.image_outlined),
          onPressed: hasImages ? () => onModeChanged(EditMode.image) : null,
          color: editMode == EditMode.image ? activeColorImage : inactiveColor,
        ),
      ],
    );
  }
}
