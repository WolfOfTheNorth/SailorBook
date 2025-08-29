import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'themes/app_theme.dart';
import 'views/home/library_view.dart';
import 'views/book/book_details_view.dart';
import 'views/player/player_view.dart';
import 'views/settings/settings_view.dart';
import 'utils/test_helpers.dart';
import 'generated/native.dart' as native;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web-specific configurations for better E2E testing
  if (kIsWeb) {
    // Ensure proper web renderer for testing compatibility
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
  }
  
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
            // Enhanced builder for web testing compatibility
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
                // Add web-specific viewport configuration
                padding: kIsWeb ? EdgeInsets.zero : MediaQuery.of(context).padding,
              ),
              child: Semantics(
                container: true,
                identifier: 'flutter-app-container',
                explicitChildNodes: true,
                enabled: true,
                label: 'SailorBook Application',
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    key: const Key('flutter-app'),
                    width: kIsWeb ? double.infinity : null,
                    height: kIsWeb ? double.infinity : null,
                    decoration: kIsWeb ? const BoxDecoration(
                      color: Colors.transparent,
                    ) : null,
                    // Add gesture detection for web testing
                    child: kIsWeb 
                      ? GestureDetector(
                          key: const Key('app-gesture-detector'),
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            // Ensure web interactions are captured
                            debugPrint('Flutter app interaction detected');
                          },
                          child: child,
                        ).withTestId('app-gesture-detector', label: 'App Interaction Area')
                      : child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}