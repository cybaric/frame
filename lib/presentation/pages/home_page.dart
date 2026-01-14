import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../providers/frame_provider.dart';

// Checkerboard painter for transparency background
class _CheckerboardPainter extends CustomPainter {
  final double squareSize = 16;
  final Paint lightPaint = Paint()..color = const Color(0xFFE0E0E0);
  final Paint darkPaint = Paint()..color = const Color(0xFFC0C0C0);

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isLight = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Color _cardColorForIndex(int index) {
    const palette = [
      Color(0xFFF5C2E7), // Soft Pink
      Color(0xFFCBA6F7), // Soft Mauve
      Color(0xFFA6E3A1), // Soft Green
      Color(0xFFF9E2AF), // Soft Yellow
      Color(0xFFFAB387), // Soft Peach
      Color(0xFF89B4FA), // Soft Blue
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final framesAsync = ref.watch(framesProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Frame Collection')),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              const Color(0xFF181825), // Slightly darker
            ],
          ),
        ),
        child: SafeArea(
          child: framesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            data: (frames) => GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,

                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              padding: const EdgeInsets.all(12),
              itemCount: frames.length,
              itemBuilder: (context, index) {
                final frame = frames[index];
                final accent = _cardColorForIndex(index);

                return GestureDetector(
                  onTap: () =>
                      context.go('/edit/${Uri.encodeComponent(frame.id)}'),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.15),
                                  theme.colorScheme.surfaceContainerHighest,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                children: [
                                  // Checkerboard background
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      painter: _CheckerboardPainter(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SvgPicture.string(
                                      frame.svgString,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
