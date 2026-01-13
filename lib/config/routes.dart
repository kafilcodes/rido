import 'package:go_router/go_router.dart';
import 'package:rido/features/auth/presentation/screens/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    // TODO: Add Auth, Home, and other routes
  ],
);
