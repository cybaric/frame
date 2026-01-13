import '../entities/frame.dart';
import '../repositories/svg_repository.dart';

class LoadSvgUseCase {
  final SvgRepository repository;

  LoadSvgUseCase(this.repository);

  Future<Frame> call(String id) async {
    return await repository.loadSvg(id);
  }
}