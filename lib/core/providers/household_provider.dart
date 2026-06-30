import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _householdsKey = 'households_v1';
const _activeHouseholdKey = 'active_household_v1';

class Household {
  final String id;
  final String name;
  final String emoji;

  const Household({required this.id, required this.name, required this.emoji});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};

  factory Household.fromJson(Map<String, dynamic> j) =>
      Household(id: j['id'] as String, name: j['name'] as String, emoji: j['emoji'] as String);
}

class HouseholdState {
  final List<Household> households;
  final String activeId;

  const HouseholdState({required this.households, required this.activeId});

  Household get active => households.firstWhere(
        (h) => h.id == activeId,
        orElse: () => households.first,
      );
}

final householdProvider =
    StateNotifierProvider<HouseholdNotifier, HouseholdState>(
  (ref) => HouseholdNotifier(),
);

class HouseholdNotifier extends StateNotifier<HouseholdState> {
  HouseholdNotifier()
      : super(const HouseholdState(
          households: [Household(id: 'default', name: 'My Home', emoji: '🏠')],
          activeId: 'default',
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_householdsKey);
    final activeId = prefs.getString(_activeHouseholdKey) ?? 'default';
    if (raw != null && raw.isNotEmpty) {
      final households = raw
          .map((s) => Household.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      state = HouseholdState(households: households, activeId: activeId);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _householdsKey,
      state.households.map((h) => jsonEncode(h.toJson())).toList(),
    );
    await prefs.setString(_activeHouseholdKey, state.activeId);
  }

  Future<void> switchTo(String id) async {
    state = HouseholdState(households: state.households, activeId: id);
    await _persist();
  }

  Future<void> addHousehold(String name, String emoji) async {
    final id = 'h_${DateTime.now().millisecondsSinceEpoch}';
    final updated = [...state.households, Household(id: id, name: name, emoji: emoji)];
    state = HouseholdState(households: updated, activeId: id);
    await _persist();
  }

  Future<void> removeHousehold(String id) async {
    if (state.households.length <= 1) return;
    final updated = state.households.where((h) => h.id != id).toList();
    final activeId = state.activeId == id ? updated.first.id : state.activeId;
    state = HouseholdState(households: updated, activeId: activeId);
    await _persist();
  }
}
