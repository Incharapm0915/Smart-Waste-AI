import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/camera/presentation/screens/camera_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/recipes/presentation/screens/recipes_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/shopping/presentation/screens/shopping_screen.dart';
import '../../features/shopping/presentation/screens/shopping_analytics_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/inventory/presentation/screens/barcode_scanner_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

// Overridden in main() before the widget tree builds.
final initialRouteProvider = Provider<String>((ref) => '/login');

final routerProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(initialRouteProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/barcode-scanner',
        name: 'barcode-scanner',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BarcodeScannerScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/shopping-analytics',
        name: 'shopping-analytics',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ShoppingAnalyticsScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const InventoryScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/camera',
            name: 'camera',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CameraScreen(),
              transitionsBuilder: _slideUpTransition,
            ),
          ),
          GoRoute(
            path: '/recipes',
            name: 'recipes',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RecipesScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AnalyticsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/shopping',
            name: 'shopping',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ShoppingScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),
    ],
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0.0, 0.05);
  const end = Offset.zero;
  final tween =
      Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
  return SlideTransition(
    position: animation.drive(tween),
    child: FadeTransition(opacity: animation, child: child),
  );
}
