import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/onboarding_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Handle Google redirect result (web only — no-op on other platforms)
  User? redirectUser;
  try {
    final result = await FirebaseAuth.instance.getRedirectResult();
    redirectUser = result.user;
    if (redirectUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(redirectUser.uid)
          .get();
      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(redirectUser.uid)
            .set({
          'uid': redirectUser.uid,
          'name': redirectUser.displayName ?? '',
          'email': redirectUser.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'sustainabilityScore': 0,
          'totalItemsSaved': 0,
          'wasteReduced': 0.0,
        });
      }
    }
  } catch (_) {}

  final currentUser = redirectUser ?? FirebaseAuth.instance.currentUser;

  // Load preferences before the widget tree
  final onboardingDone = await OnboardingNotifier.load();
  final darkMode = await ThemeModeNotifier.loadDarkMode();

  final container = ProviderContainer(
    overrides: [
      initialRouteProvider.overrideWithValue(
        currentUser != null
            ? '/home'
            : onboardingDone
                ? '/login'
                : '/onboarding',
      ),
      themeModeProvider.overrideWith(
        (ref) => ThemeModeNotifier()..setDark(darkMode),
      ),
    ],
  );

  await NotificationService.init(container);

  final notifEnabled = await NotificationsToggleNotifier.load();
  await container.read(dailyNotificationsEnabledProvider.notifier).setValue(notifEnabled);
  if (notifEnabled) await NotificationService.scheduleDailyNotification();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SmartWasteApp(),
    ),
  );
}

class SmartWasteApp extends ConsumerWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return MaterialApp.router(
      title: 'Smart Waste AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Sync status bar icon brightness with theme
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
