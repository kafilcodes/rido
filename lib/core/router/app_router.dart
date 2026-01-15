import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/registration/presentation/role_selection_screen.dart';
import '../../features/registration/presentation/profile_form_screen.dart';
import '../../features/driver_verification/presentation/verified_docs_screen.dart';
import '../../features/driver_verification/presentation/vehicle_details_screen.dart';
import '../../features/ride_booking/presentation/destination_search_screen.dart';
import '../../features/driver_home/presentation/driver_home_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/auth/data/auth_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authStream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.uri.path == '/auth' || 
                          state.uri.path == '/otp' ||
                          state.uri.path == '/role-selection' ||
                          state.uri.path == '/profile-form';
      final isOnboardingRoute = state.uri.path == '/onboarding';

      // 1. If not logged in
      if (!isLoggedIn) {
        // If already on an allowed path (auth/onboarding), let them be
        if (isAuthRoute || isOnboardingRoute) return null;
        
        return '/auth'; 
      }

      // 2. If logged in
      if (isLoggedIn) {
         // If trying to access login/onboarding, send them home
         if (isAuthRoute || isOnboardingRoute) {
           return '/home';
         }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>;
           return OtpScreen(
             verificationId: extra['verificationId'],
             phone: extra['phone'],
           );
        },
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/profile-form',
        builder: (context, state) {
           final role = state.extra as String;
           return ProfileFormScreen(role: role);
        },
      ),
      GoRoute(
        path: '/verified-docs',
        builder: (context, state) => const VerifiedDocsScreen(),
      ),
      GoRoute(
        path: '/vehicle-details',
        builder: (context, state) => const VehicleDetailsScreen(),
      ),
      GoRoute(
        path: '/destination-search',
        builder: (context, state) => const DestinationSearchScreen(),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
       GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
