import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/recipes/data/models/recipe_model.dart';
import '../providers/notification_provider.dart';
import '../routes/app_router.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static ProviderContainer? _container;

  // Curated daily recipes — one shown per weekday (1=Mon … 7=Sun)
  static final _dailyRecipes = <String, RecipeModel>{
    'lemon_pasta': RecipeModel(
      id: 'notif_1',
      name: 'Lemon Herb Pasta',
      description: 'Bright and zesty pasta with fresh herbs — ready in 15 minutes using pantry staples.',
      ingredients: ['200g spaghetti', '3 tbsp olive oil', '3 garlic cloves', 'Zest of 1 lemon', '2 tbsp lemon juice', 'Fresh parsley', 'Parmesan', 'Salt & pepper'],
      steps: [
        'Cook spaghetti in salted boiling water until al dente.',
        'Warm olive oil in a pan over medium heat, add sliced garlic until golden.',
        'Add lemon zest and juice, stir for 30 seconds.',
        'Toss in drained pasta with a splash of pasta water.',
        'Finish with chopped parsley and grated parmesan.',
      ],
      cookTimeMinutes: 15,
      difficulty: 'Easy',
      cuisine: 'Italian',
      servings: 2,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🍋',
      nutrition: {'calories': 380, 'protein': 12, 'carbs': 58, 'fat': 11},
    ),
    'avocado_toast': RecipeModel(
      id: 'notif_2',
      name: 'Smashed Avocado Toast',
      description: 'Creamy smashed avocado on sourdough — the ultimate nutritious breakfast.',
      ingredients: ['2 slices sourdough', '1 ripe avocado', '1 lemon', 'Red chilli flakes', 'Everything bagel seasoning', '2 eggs (optional)', 'Salt & pepper'],
      steps: [
        'Toast sourdough slices until golden and crispy.',
        'Halve avocado, remove pit, scoop flesh into a bowl.',
        'Add lemon juice, salt, and pepper; smash roughly.',
        'Spread onto toast and sprinkle seasoning and chilli flakes.',
        'Top with a poached or fried egg if desired.',
      ],
      cookTimeMinutes: 10,
      difficulty: 'Easy',
      cuisine: 'Australian',
      servings: 1,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🥑',
      nutrition: {'calories': 310, 'protein': 9, 'carbs': 32, 'fat': 18},
    ),
    'chicken_curry': RecipeModel(
      id: 'notif_3',
      name: 'Coconut Chicken Curry',
      description: 'Rich, aromatic curry with tender chicken and creamy coconut milk.',
      ingredients: ['400g chicken breast', '400ml coconut milk', '2 tbsp curry paste', '1 onion', '3 garlic cloves', 'Fresh ginger', 'Basmati rice', 'Coriander'],
      steps: [
        'Dice chicken and onion into bite-sized pieces.',
        'Fry onion in oil until soft, add garlic and ginger.',
        'Stir in curry paste and cook for 1 minute.',
        'Add chicken pieces and cook until sealed.',
        'Pour in coconut milk, simmer 15 minutes until chicken is cooked.',
        'Serve over steamed basmati rice, garnish with coriander.',
      ],
      cookTimeMinutes: 30,
      difficulty: 'Medium',
      cuisine: 'Indian',
      servings: 3,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🍛',
      nutrition: {'calories': 520, 'protein': 42, 'carbs': 38, 'fat': 22},
    ),
    'mushroom_risotto': RecipeModel(
      id: 'notif_4',
      name: 'Mushroom Risotto',
      description: 'Silky, comforting risotto loaded with earthy mushrooms and parmesan.',
      ingredients: ['300g arborio rice', '400g mixed mushrooms', '1L vegetable stock', '1 onion', '100ml white wine', '50g parmesan', '2 tbsp butter', 'Thyme'],
      steps: [
        'Heat stock in a separate pot and keep warm.',
        'Sauté onion in butter until translucent.',
        'Add mushrooms and cook until golden.',
        'Stir in rice, toast for 1 minute, add wine.',
        'Add warm stock one ladle at a time, stirring continuously.',
        'Finish with parmesan and butter, season to taste.',
      ],
      cookTimeMinutes: 35,
      difficulty: 'Medium',
      cuisine: 'Italian',
      servings: 2,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🍄',
      nutrition: {'calories': 460, 'protein': 14, 'carbs': 72, 'fat': 12},
    ),
    'veggie_wrap': RecipeModel(
      id: 'notif_5',
      name: 'Rainbow Veggie Wrap',
      description: 'Colourful, crunchy veggie wrap with hummus — perfect lunch under 10 minutes.',
      ingredients: ['2 large tortillas', '4 tbsp hummus', 'Shredded lettuce', '1 bell pepper', '1 carrot (grated)', 'Cucumber', 'Cherry tomatoes', 'Feta cheese'],
      steps: [
        'Spread hummus generously over each tortilla.',
        'Layer lettuce, sliced pepper, grated carrot, and cucumber.',
        'Add cherry tomatoes and crumbled feta.',
        'Roll tightly, slice diagonally and serve.',
      ],
      cookTimeMinutes: 8,
      difficulty: 'Easy',
      cuisine: 'Mediterranean',
      servings: 2,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🌯',
      nutrition: {'calories': 280, 'protein': 10, 'carbs': 38, 'fat': 10},
    ),
    'berry_smoothie': RecipeModel(
      id: 'notif_6',
      name: 'Berry Protein Smoothie Bowl',
      description: 'Thick, vibrant smoothie bowl packed with antioxidants and protein — start your day right.',
      ingredients: ['1 frozen banana', '150g frozen mixed berries', '120ml almond milk', '2 tbsp Greek yogurt', 'Granola', 'Fresh berries', 'Chia seeds', 'Honey'],
      steps: [
        'Blend frozen banana, berries, almond milk, and yogurt until thick.',
        'Pour into a bowl — it should be thick enough to hold toppings.',
        'Top with granola, fresh berries, and chia seeds.',
        'Drizzle with honey and serve immediately.',
      ],
      cookTimeMinutes: 5,
      difficulty: 'Easy',
      cuisine: 'American',
      servings: 1,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🫐',
      nutrition: {'calories': 340, 'protein': 11, 'carbs': 62, 'fat': 6},
    ),
    'steak_salad': RecipeModel(
      id: 'notif_7',
      name: 'Seared Steak & Arugula Salad',
      description: 'Restaurant-quality salad with seared steak, peppery arugula, and shaved parmesan.',
      ingredients: ['200g sirloin steak', '80g arugula', '30g parmesan (shaved)', '2 tbsp balsamic glaze', '1 tbsp olive oil', 'Cherry tomatoes', 'Lemon juice', 'Salt & pepper'],
      steps: [
        'Season steak generously with salt and pepper.',
        'Sear in a hot pan with olive oil, 2-3 min each side for medium-rare.',
        'Rest steak for 5 minutes, then slice thinly against the grain.',
        'Toss arugula with lemon juice, salt, and olive oil.',
        'Arrange salad, top with steak slices, parmesan, and tomatoes.',
        'Drizzle with balsamic glaze.',
      ],
      cookTimeMinutes: 20,
      difficulty: 'Medium',
      cuisine: 'American',
      servings: 2,
      requiredItems: [],
      expiryUrgency: 0,
      emoji: '🥩',
      nutrition: {'calories': 420, 'protein': 38, 'carbs': 12, 'fat': 24},
    ),
  };

  static final _payloadKeys = [
    'lemon_pasta',
    'avocado_toast',
    'chicken_curry',
    'mushroom_risotto',
    'veggie_wrap',
    'berry_smoothie',
    'steak_salad',
  ];

  static RecipeModel get _todayRecipe {
    final index = DateTime.now().weekday - 1; // 0-6
    return _dailyRecipes[_payloadKeys[index]]!;
  }

  static RecipeModel get todayRecipe => _todayRecipe;

  static RecipeModel? getRecipeByPayload(String? payload) {
    if (payload == null) return null;
    return _dailyRecipes[payload];
  }

  static Future<void> init(ProviderContainer container) async {
    if (kIsWeb) return;
    _container = container;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Check if app was launched from a notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      _handlePayload(payload);
    }

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onTap(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  // Top-level function required for background isolate
  static void _handlePayload(String? payload) {
    final recipe = getRecipeByPayload(payload);
    if (recipe == null) return;
    _container?.read(pendingNotificationRecipeProvider.notifier).state = recipe;
    // Navigate to recipes
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      Future.microtask(() {
        try {
          rootNavigatorKey.currentContext?.go('/recipes');
        } catch (_) {}
      });
    }
  }

  static Future<void> scheduleDailyNotification() async {
    if (kIsWeb) return;
    final recipe = _todayRecipe;
    final payload = _payloadKeys[(DateTime.now().weekday - 1)];

    const androidDetails = AndroidNotificationDetails(
      'daily_recipe_channel',
      'Daily Recipe',
      channelDescription: 'Daily recipe suggestions based on your inventory',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      color: Color(0xFF22C55E),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.periodicallyShow(
      42,
      '🍽️ Recipe of the Day',
      '${recipe.emoji ?? ''} ${recipe.name} — ${recipe.description.split('—').first.trim()}',
      RepeatInterval.daily,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> cancelDailyNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(42);
  }

  /// Show an immediate demo notification (for testing from settings)
  static Future<void> showDemoNotification() async {
    if (kIsWeb) return;
    final recipe = _todayRecipe;
    final payload = _payloadKeys[(DateTime.now().weekday - 1)];
    _container?.read(latestRecipeNotificationProvider.notifier).state = recipe;

    const androidDetails = AndroidNotificationDetails(
      'daily_recipe_channel',
      'Daily Recipe',
      channelDescription: 'Daily recipe suggestions based on your inventory',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF22C55E),
    );

    await _plugin.show(
      99,
      '🍽️ Recipe of the Day',
      '${recipe.emoji ?? ''} ${recipe.name} — ${recipe.description.split('—').first.trim()}',
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  // Background tap is handled when app comes to foreground via getNotificationAppLaunchDetails
}
