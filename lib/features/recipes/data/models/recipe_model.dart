class RecipeModel {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final int cookTimeMinutes;
  final String difficulty;
  final String cuisine;
  final int servings;
  final List<String> requiredItems;
  final int expiryUrgency;
  final String? emoji;
  final Map<String, dynamic>? nutrition;
  bool isSaved;

  RecipeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.cuisine,
    required this.servings,
    required this.requiredItems,
    required this.expiryUrgency,
    this.emoji,
    this.nutrition,
    this.isSaved = false,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      ingredients: List<String>.from(json['ingredients'] as List),
      steps: List<String>.from(json['steps'] as List),
      cookTimeMinutes: json['cook_time_minutes'] as int? ?? 30,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      cuisine: json['cuisine'] as String? ?? 'International',
      servings: json['servings'] as int? ?? 2,
      requiredItems: List<String>.from(json['required_items'] as List? ?? []),
      expiryUrgency: json['expiry_urgency'] as int? ?? 0,
      emoji: json['emoji'] as String?,
      nutrition: json['nutrition'] as Map<String, dynamic>?,
    );
  }

  static List<RecipeModel> mockRecipes() {
    return [
      RecipeModel(
        id: '1',
        name: 'Creamy Chicken Pasta',
        description: 'A rich and creamy pasta using your chicken breast and dairy items expiring soon.',
        ingredients: [
          '300g chicken breast',
          '200g pasta',
          '200ml heavy cream',
          '2 cloves garlic',
          'Salt & pepper',
          'Parmesan cheese',
        ],
        steps: [
          'Boil pasta until al dente, reserve 1 cup pasta water.',
          'Season chicken with salt, pepper, and garlic.',
          'Cook chicken in a pan over medium-high heat until golden.',
          'Add cream to the pan, simmer for 5 minutes.',
          'Toss pasta in the cream sauce, add pasta water to adjust consistency.',
          'Serve with grated parmesan.',
        ],
        cookTimeMinutes: 25,
        difficulty: 'Easy',
        cuisine: 'Italian',
        servings: 2,
        requiredItems: ['Chicken Breast', 'Whole Milk'],
        expiryUrgency: 2,
        emoji: '🍝',
        nutrition: {'calories': 480, 'protein': 38, 'carbs': 45, 'fat': 18},
      ),
      RecipeModel(
        id: '2',
        name: 'Yogurt Parfait Bowl',
        description: 'Use that Greek yogurt before it expires — a quick nutritious breakfast.',
        ingredients: [
          '500g Greek yogurt',
          'Mixed berries',
          'Granola',
          'Honey',
          'Chia seeds',
        ],
        steps: [
          'Layer yogurt in a bowl.',
          'Top with granola and berries.',
          'Drizzle with honey.',
          'Sprinkle chia seeds.',
        ],
        cookTimeMinutes: 5,
        difficulty: 'Easy',
        cuisine: 'American',
        servings: 1,
        requiredItems: ['Greek Yogurt'],
        expiryUrgency: 1,
        emoji: '🥣',
        nutrition: {'calories': 320, 'protein': 22, 'carbs': 38, 'fat': 8},
      ),
      RecipeModel(
        id: '3',
        name: 'Chicken Stir-Fry',
        description: 'Quick weeknight dinner using chicken and fresh vegetables.',
        ingredients: [
          '300g chicken breast',
          'Bell peppers',
          'Onion',
          'Soy sauce',
          'Ginger',
          'Sesame oil',
        ],
        steps: [
          'Slice chicken and vegetables thinly.',
          'Heat wok or pan to high heat.',
          'Cook chicken until browned, set aside.',
          'Stir-fry vegetables for 3 minutes.',
          'Add chicken back, season with soy sauce and ginger.',
          'Finish with sesame oil.',
        ],
        cookTimeMinutes: 20,
        difficulty: 'Easy',
        cuisine: 'Asian',
        servings: 2,
        requiredItems: ['Chicken Breast'],
        expiryUrgency: 2,
        emoji: '🥘',
        nutrition: {'calories': 290, 'protein': 35, 'carbs': 15, 'fat': 10},
      ),
    ];
  }
}
