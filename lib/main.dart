import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/pages/edit_page.dart';
import 'presentation/pages/splash_page.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/edit/:id',
          builder: (context, state) => EditPage(
            frameId: Uri.decodeComponent(state.pathParameters['id']!),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E2E), // Mocha Base
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCBA6F7), // Mocha Mauve
          secondary: Color(0xFF89B4FA), // Mocha Blue
          surface: Color(0xFF1E1E2E),
          surfaceContainerHighest: Color(0xFF313244), // Surface0
          onSurface: Color(0xFFCDD6F4), // Text
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFCDD6F4),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF313244),
          contentTextStyle: const TextStyle(color: Color(0xFFCDD6F4)),
          actionTextColor: const Color(0xFF89B4FA),
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
