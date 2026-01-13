import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ImageEditState {
  final Uint8List? bytes;
  final Offset offset;
  final double scale;
  final double rotation;

  const ImageEditState({
    this.bytes,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  ImageEditState copyWith({
    Uint8List? bytes,
    bool clearBytes = false,
    Offset? offset,
    double? scale,
    double? rotation,
  }) {
    return ImageEditState(
      bytes: clearBytes ? null : (bytes ?? this.bytes),
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

final imageEditStateProvider = StateProvider<ImageEditState>((ref) => const ImageEditState());
