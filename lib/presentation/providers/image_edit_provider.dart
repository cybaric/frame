import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ImageLayer {
  final String id;
  final Uint8List bytes;
  final Offset offset;
  final double scale;
  final double rotation;

  const ImageLayer({
    required this.id,
    required this.bytes,
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  ImageLayer copyWith({
    Uint8List? bytes,
    Offset? offset,
    double? scale,
    double? rotation,
  }) {
    return ImageLayer(
      id: id,
      bytes: bytes ?? this.bytes,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

@immutable
class ImageLayersState {
  final List<ImageLayer> layers;
  final String? activeLayerId;

  const ImageLayersState({
    this.layers = const [],
    this.activeLayerId,
  });

  ImageLayer? get activeLayer {
    final id = activeLayerId;
    if (id == null) return null;
    for (final l in layers) {
      if (l.id == id) return l;
    }
    return null;
  }

  ImageLayersState copyWith({
    List<ImageLayer>? layers,
    String? activeLayerId,
    bool clearActive = false,
  }) {
    return ImageLayersState(
      layers: layers ?? this.layers,
      activeLayerId: clearActive ? null : (activeLayerId ?? this.activeLayerId),
    );
  }
}

class ImageLayersNotifier extends StateNotifier<ImageLayersState> {
  ImageLayersNotifier() : super(const ImageLayersState());

  void addLayer(Uint8List bytes) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final next = [...state.layers, ImageLayer(id: id, bytes: bytes)];
    state = state.copyWith(layers: next, activeLayerId: id);
  }

  void setActive(String id) {
    if (state.layers.any((l) => l.id == id)) {
      state = state.copyWith(activeLayerId: id);
    }
  }

  void updateActiveTransform({
    Offset? offset,
    double? scale,
    double? rotation,
  }) {
    final activeId = state.activeLayerId;
    if (activeId == null) return;
    final idx = state.layers.indexWhere((l) => l.id == activeId);
    if (idx < 0) return;
    final updated = state.layers[idx].copyWith(
      offset: offset,
      scale: scale,
      rotation: rotation,
    );
    final next = [...state.layers];
    next[idx] = updated;
    state = state.copyWith(layers: next);
  }

  void resetActiveTransform() {
    updateActiveTransform(offset: Offset.zero, scale: 1.0, rotation: 0.0);
  }

  void removeActiveLayer() {
    final activeId = state.activeLayerId;
    if (activeId == null) return;
    final next = state.layers.where((l) => l.id != activeId).toList();
    final newActive = next.isEmpty ? null : next.last.id;
    state = ImageLayersState(layers: next, activeLayerId: newActive);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.layers.length) return;
    var target = newIndex;
    if (target < 0) target = 0;
    if (target > state.layers.length) target = state.layers.length;
    if (target > oldIndex) target -= 1;

    final next = [...state.layers];
    final item = next.removeAt(oldIndex);
    next.insert(target, item);
    state = state.copyWith(layers: next);
  }

  void clearAll() {
    state = const ImageLayersState();
  }
}

final imageLayersProvider = StateNotifierProvider<ImageLayersNotifier, ImageLayersState>(
  (ref) => ImageLayersNotifier(),
);
