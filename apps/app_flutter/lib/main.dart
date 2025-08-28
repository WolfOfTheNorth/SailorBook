import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'themes/app_theme.dart';
import 'views/home/library_view.dart';
import 'views/book/book_details_view.dart';
import 'views/player/player_view.dart';
import 'views/settings/settings_view.dart';
import 'generated/native.dart' as native;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Rust logger
  try {
    native.initLogger();
  } catch (e) {
    debugPrint('Failed to initialize native logger: $e');
  }
  
  runApp(
    const ProviderScope(
      child: PDReaderApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LibraryView(),
    ),
    GoRoute(
      path: '/book/:bookId',
      builder: (context, state) => BookDetailsView(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/player/:bookId',
      builder: (context, state) => PlayerView(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsView(),
    ),
  ],
);

class PDReaderApp extends StatelessWidget {
  const PDReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Public-Domain Reader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: _router,
          builder: (context, child) {
            return Container(
              key: const Key('flutter-app'),
              child: child,
            );
          },
        );
      },
    );
  }
}