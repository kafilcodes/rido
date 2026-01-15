import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Initialize Logger globally or via provider. 
// Using top-level for now as requested for "Logger().i(...)".
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    // printTime: true, // Deprecated
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  try {
    // Note: Add DefaultFirebaseOptions.currentPlatform if generated
    await Firebase.initializeApp();
    logger.i("Firebase Initialized Successfully");
  } catch (e) {
    logger.e("Firebase Initialization Failed: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp.router(
          title: 'Rido',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark, // Default to Dark as requested
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
