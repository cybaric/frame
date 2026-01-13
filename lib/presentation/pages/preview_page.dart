import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../providers/frame_provider.dart';
import '../providers/image_edit_provider.dart';

class PreviewPage extends ConsumerStatefulWidget {
  final String frameId;

  const PreviewPage({super.key, required this.frameId});

  @override
  ConsumerState<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends ConsumerState<PreviewPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final framesAsync = ref.watch(framesProvider);
    final imageEditState = ref.watch(imageEditStateProvider);
    final importedImageBytes = imageEditState.bytes;

    return framesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (frames) {
        final frame = frames.firstWhere((f) => f.id == widget.frameId);
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (importedImageBytes != null)
                Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translateByDouble(imageEditState.offset.dx, imageEditState.offset.dy, 0.0, 1.0)
                      ..rotateZ(imageEditState.rotation)
                      ..scaleByDouble(imageEditState.scale, imageEditState.scale, 1.0, 1.0),
                    child: Image.memory(
                      importedImageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Center(
                child: SvgPicture.string(
                  frame.svgString,
                  fit: BoxFit.contain,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/edit/${Uri.encodeComponent(widget.frameId)}'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}