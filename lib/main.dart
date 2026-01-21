import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'core/theme/ui_theme.dart';
import 'core/theme/theme_provider.dart';
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
  material.WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  try {
    // Note: Add DefaultFirebaseOptions.currentPlatform if generated
    await Firebase.initializeApp();
    logger.i("Firebase Initialized Successfully");
  } catch (e) {
    logger.e("Firebase Initialization Failed: $e");
  }

  material.runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  material.Widget build(material.BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final materialThemeMode = ref.watch(themeProvider);
    
    // Map Material ThemeMode to Shadcn ThemeMode
    final shadcnThemeMode = materialThemeMode == material.ThemeMode.dark 
        ? ThemeMode.dark 
        : ThemeMode.light;

    return Sizer(
      builder: (context, orientation, deviceType) {
        return ShadcnApp.router(
          title: 'Rido',
          theme: UITheme.shadcnLight,
          darkTheme: UITheme.shadcnDark,
          themeMode: shadcnThemeMode, 
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
