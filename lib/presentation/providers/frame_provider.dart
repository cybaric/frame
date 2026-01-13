import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/frame.dart';
import '../../domain/usecases/load_svg_usecase.dart';
import '../../domain/usecases/edit_color_usecase.dart';
import '../../data/repositories/svg_repository_impl.dart';

// Providers
final svgRepositoryProvider = Provider((ref) => SvgRepositoryImpl());

final loadSvgUseCaseProvider = Provider((ref) => LoadSvgUseCase(ref.watch(svgRepositoryProvider)));

final editColorUseCaseProvider = Provider((ref) => EditColorUseCase(ref.watch(svgRepositoryProvider)));

final framesProvider = StateNotifierProvider<FramesNotifier, AsyncValue<List<Frame>>>((ref) {
  return FramesNotifier(ref.watch(svgRepositoryProvider));
});

class FramesNotifier extends StateNotifier<AsyncValue<List<Frame>>> {
  final SvgRepositoryImpl repository;

  FramesNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadFrames();
  }

  Future<void> loadFrames() async {
    state = const AsyncValue.loading();
    try {
      final frames = await repository.getAllFrames();
      state = AsyncValue.data(frames);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void updateFrame(Frame updatedFrame) {
    state = state.whenData((frames) =>
      frames.map((f) => f.id == updatedFrame.id ? updatedFrame : f).toList()
    );
  }

  Future<void> addFrame(Frame frame) async {
    state = state.whenData((frames) => [...frames, frame]);
  }
}