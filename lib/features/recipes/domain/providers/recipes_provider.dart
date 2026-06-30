import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/inventory/domain/providers/inventory_provider.dart';
// InventoryItemModel referenced through inventory provider (no direct import needed)
import '../../data/models/recipe_model.dart';

final recipesProvider =
    StateNotifierProvider<RecipesNotifier, AsyncValue<List<RecipeModel>>>(
  (ref) => RecipesNotifier(ref),
);

class RecipesNotifier extends StateNotifier<AsyncValue<List<RecipeModel>>> {
  final Ref _ref;
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  RecipesNotifier(this._ref) : super(const AsyncValue.data([]));

  Future<void> generateRecipes() async {
    state = const AsyncValue.loading();
    try {
      final inventoryAsync = _ref.read(inventoryProvider);
      final items = inventoryAsync.value ?? [];
      final ingredientNames = items
          .where((i) => !i.isConsumed)
          .map((i) => i.name)
          .take(15)
          .toList();

      if (ingredientNames.isEmpty) {
        state = AsyncValue.data(RecipeModel.mockRecipes());
        return;
      }

      final response = await _dio.post(
        AppConstants.recipesEndpoint,
        data: {'ingredients': ingredientNames},
      );
      final recipes = (response.data['recipes'] as List)
          .map((r) => RecipeModel.fromJson(r as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(recipes);
    } catch (_) {
      state = AsyncValue.data(RecipeModel.mockRecipes());
    }
  }
}
