import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _darkModeKey = 'dark_mode_enabled';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  static Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> _load() async {
    final dark = await loadDarkMode();
    state = dark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final nowDark = state != ThemeMode.dark;
    state = nowDark ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool(_darkModeKey, nowDark);
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light; // set immediately, persist after
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, dark);
  }
}
