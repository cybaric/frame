import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../providers/frame_provider.dart';

class PreviewPage extends ConsumerWidget {
  final String frameId;

  const PreviewPage({super.key, required this.frameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final framesAsync = ref.watch(framesProvider);

    return framesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (frames) {
        final frame = frames.firstWhere((f) => f.id == frameId);
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
            title: Text(frame.name),
          ),
          body: Center(
            child: SvgPicture.string(frame.svgString),
          ),
        );
      },
    );
  }
}