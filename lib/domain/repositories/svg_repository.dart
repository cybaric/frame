import '../entities/frame.dart';

abstract class SvgRepository {
  Future<List<Frame>> getAllFrames();
  Future<Frame> loadSvg(String id);
  Future<Frame> editColor(Frame frame, String pathId, String color);
  Future<Frame> importFromGallery();
  Future<void> exportToPng(Frame frame, String path);
}