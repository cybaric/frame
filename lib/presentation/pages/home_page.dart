import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../providers/frame_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final framesAsync = ref.watch(framesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Frame Collection')),
      body: framesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (frames) => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: frames.length,
        itemBuilder: (context, index) {
          final frame = frames[index];
          return GestureDetector(
            onTap: () => context.go('/edit/${Uri.encodeComponent(frame.id)}'),
            child: Card(
              child: SvgPicture.string(
                frame.svgString,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Import from gallery
          final repository = ref.read(svgRepositoryProvider);
          try {
            final newFrame = await repository.importFromGallery();
            ref.read(framesProvider.notifier).addFrame(newFrame);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}