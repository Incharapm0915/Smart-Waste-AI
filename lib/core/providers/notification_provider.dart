import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/recipes/data/models/recipe_model.dart';

/// Holds a recipe that arrived via notification tap, so RecipesScreen can auto-open it.
final pendingNotificationRecipeProvider = StateProvider<RecipeModel?>((ref) => null);

/// Stores the latest recipe notification so the bell icon inbox can show it.
final latestRecipeNotificationProvider = StateProvider<RecipeModel?>((ref) => null);

/// Persists the daily notifications toggle across app restarts.
class NotificationsToggleNotifier extends StateNotifier<bool> {
  static const _key = 'daily_notifications_enabled';

  NotificationsToggleNotifier(super.initial);

  Future<void> setValue(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }
}

final dailyNotificationsEnabledProvider =
    StateNotifierProvider<NotificationsToggleNotifier, bool>(
        (ref) => NotificationsToggleNotifier(false));
