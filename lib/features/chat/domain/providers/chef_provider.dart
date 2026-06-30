import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/chat_message_model.dart';

final chefProvider =
    StateNotifierProvider<ChefNotifier, List<ChatMessage>>(
  (ref) => ChefNotifier(),
);

const _uuid = Uuid();

const _welcomeText =
    "👨‍🍳 Bonjour! I'm Chef AI, your personal culinary expert!\n\nI can help you with:\n• Full recipes for any dish you name\n• Weekly meal planning from your inventory\n• Smart ingredient substitutions\n• Pro cooking tips & techniques";

class ChefNotifier extends StateNotifier<List<ChatMessage>> {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  ChefNotifier()
      : super([
          ChatMessage(
            id: 'welcome',
            text: _welcomeText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ]);

  Future<void> sendMessage(String text,
      {List<String> inventoryItems = const []}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    final loadingMsg = ChatMessage(
      id: 'loading',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = [...state, userMsg, loadingMsg];

    try {
      final response = await _dio.post(
        AppConstants.chatEndpoint,
        data: {
          'message': text.trim(),
          'context': 'ai_chef',
          'inventory': inventoryItems,
        },
      );
      final botText = response.data['response'] as String? ??
          _getResponse(text, inventoryItems);
      _replaceLoading(botText);
    } catch (_) {
      _replaceLoading(_getResponse(text, inventoryItems));
    }
  }

  void _replaceLoading(String text) {
    state = [
      ...state.where((m) => !m.isLoading),
      ChatMessage(
        id: _uuid.v4(),
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void clearChat() {
    state = [
      ChatMessage(
        id: 'welcome',
        text: _welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  String _getResponse(String query, List<String> inventory) {
    final q = query.toLowerCase();

    // Meal planning
    if (q.contains('plan') ||
        q.contains('weekly') ||
        q.contains('week') && q.contains('meal')) {
      return _mealPlan(inventory);
    }

    // Substitutions
    if (q.contains('substitut') ||
        q.contains('replace') ||
        q.contains('instead of') ||
        q.contains('out of') ||
        q.contains('alternative') ||
        q.contains('no ') && (q.contains('egg') || q.contains('butter') || q.contains('milk'))) {
      return _substitution(q);
    }

    // Named dish recipes
    if (q.contains('carbonara') || q.contains('pasta carbon')) {
      return _pastaCarbonaraRecipe();
    }
    if (q.contains('butter chicken') || q.contains('murgh makhani')) {
      return _butterChickenRecipe();
    }
    if (q.contains('fried rice')) {
      return _friedRiceRecipe();
    }
    if (q.contains('pancake')) {
      return _pancakeRecipe();
    }
    if (q.contains('omelette') || q.contains('omelet')) {
      return _omeletteRecipe();
    }
    if (q.contains('pizza')) {
      return _pizzaRecipe();
    }
    if (q.contains('dal') ||
        q.contains('lentil') ||
        q.contains('soup') && q.contains('lentil')) {
      return _lentilSoupRecipe();
    }
    if (q.contains('biryani')) {
      return _biryaniRecipe();
    }
    if (q.contains('dosa')) {
      return _dosaRecipe();
    }
    if (q.contains('pasta') && !q.contains('carbonara')) {
      return _simplePastaRecipe();
    }

    // What can I cook / recipe request without a specific dish
    if (q.contains('recipe') ||
        q.contains('cook') ||
        q.contains('make') ||
        q.contains('dish') ||
        q.contains('eat')) {
      if (inventory.isNotEmpty) {
        return "👨‍🍳 Based on your inventory (${inventory.take(4).join(', ')}…), here are my suggestions:\n\n${_suggestFromInventory(inventory)}\n\nAsk me for the full recipe of any dish! Try:\n*'Give me the pasta carbonara recipe'*";
      }
      return "👨‍🍳 Name any dish and I'll give you the full recipe!\n\nPopular picks:\n• *'Recipe for butter chicken'*\n• *'How do I make pasta carbonara?'*\n• *'Give me a fried rice recipe'*\n• *'Biryani recipe'*\n\nOr ask me to *plan your meals for the week*! 📅";
    }

    // Cooking tips
    if (q.contains('tip') || q.contains('trick') || q.contains('technique')) {
      return "👨‍🍳 Chef's pro tips:\n\n🔥 **Heat** — Most home cooks run too hot. Medium is your friend.\n\n🧂 **Salt** — Season at every stage, not just the end.\n\n🫙 **Mise en place** — Prep all ingredients before you start cooking.\n\n🍳 **Rest your meat** — Always rest for 5–10 min after cooking to keep juices.\n\n🧄 **Garlic** — Add it after onions are soft to prevent burning.\n\n🌡️ **Thermometer** — The single best tool you can own.";
    }

    // Greeting
    if (q.contains('hello') ||
        q.contains('hi') ||
        q.contains('hey') ||
        q.contains('bonjour')) {
      return "👨‍🍳 Bonjour! Ready to create something delicious?\n\nAsk me for any recipe, a weekly meal plan, or how to swap an ingredient you're missing. I'm here for all of it! 🍽️";
    }

    return "👨‍🍳 I'm your culinary expert! Here's what I can do:\n\n🍽️ **Recipes** — Name any dish: *'Recipe for biryani'*\n📅 **Meal planning** — *'Plan my meals for the week'*\n🔄 **Substitutions** — *'What can replace butter?'*\n💡 **Chef tips** — *'Give me cooking tips'*\n\nWhat shall we cook today? 🔥";
  }

  String _mealPlan(List<String> inventory) {
    return """📅 **Your Weekly Meal Plan**

**Monday**
🌅 Breakfast: Oats with banana & honey
🍽️ Lunch: Red lentil soup with bread
🌙 Dinner: Grilled chicken with roasted veg

**Tuesday**
🌅 Breakfast: Scrambled eggs & toast
🍽️ Lunch: Pasta with tomato sauce
🌙 Dinner: Stir-fried rice with egg & veggies

**Wednesday**
🌅 Breakfast: Greek yogurt with fruits & nuts
🍽️ Lunch: Veggie sandwich & salad
🌙 Dinner: Dal tadka with roti

**Thursday**
🌅 Breakfast: Fluffy pancakes with berries
🍽️ Lunch: Leftover dal & rice
🌙 Dinner: Butter chicken with naan

**Friday**
🌅 Breakfast: Fruit smoothie bowl
🍽️ Lunch: Egg fried rice
🌙 Dinner: Homemade pizza

**Saturday**
🌅 Breakfast: Avocado toast with eggs
🍽️ Lunch: Greek salad with feta
🌙 Dinner: Pasta carbonara

**Sunday**
🌅 Breakfast: Full cooked breakfast
🍽️ Lunch: Tomato soup & sandwich
🌙 Dinner: Slow-roasted chicken & veggies

👨‍🍳 Ask me for the full recipe of any meal above!""";
  }

  String _substitution(String query) {
    if (query.contains('egg')) {
      return "🥚 **Egg Substitutes:**\n\n• **Binding (baking)** → 1 tbsp flaxseed + 3 tbsp water, rest 5 min\n• **Moisture** → ¼ cup unsweetened applesauce per egg\n• **Leavening** → 1 tsp baking soda + 1 tbsp vinegar\n• **Richness** → 3 tbsp aquafaba (chickpea liquid)\n• **Scrambled eggs** → Silken tofu, crumbled & seasoned\n\n👨‍🍳 Flaxseed egg is my top pick for baking!";
    }
    if (query.contains('butter')) {
      return "🧈 **Butter Substitutes:**\n\n• **Baking (1:1)** → Coconut oil (adds subtle flavour)\n• **Baking** → ¾ amount of vegetable/sunflower oil\n• **Spreading** → Avocado or nut butter\n• **Sautéing** → Olive oil or ghee\n• **Dairy-free** → Vegan margarine (1:1)\n\n👨‍🍳 Ghee is my favourite — it has an even higher smoke point!";
    }
    if (query.contains('milk')) {
      return "🥛 **Milk Substitutes (1:1):**\n\n• **Best neutral** → Oat milk\n• **Lighter** → Almond milk\n• **Richer / creamy dishes** → Coconut milk\n• **Budget option** → Water + 1 tbsp butter per cup\n• **Smoothest texture** → Cashew milk\n\n👨‍🍳 Oat milk is my go-to — closest to cow's milk in baking.";
    }
    if (query.contains('oil') || query.contains('olive')) {
      return "🫒 **Oil Substitutes:**\n\n• **Baking** → Equal amount of melted butter\n• **Lighter baking** → Applesauce (reduces fat)\n• **High-heat frying** → Avocado oil (smoke point 270°C)\n• **Dressings** → Any neutral vegetable oil\n• **Sautéing** → Butter or ghee\n\n👨‍🍳 Avocado oil is the healthiest choice for high-heat cooking!";
    }
    if (query.contains('flour') || query.contains('wheat')) {
      return "🌾 **Flour Substitutes:**\n\n• **Gluten-free (1:1)** → Rice flour or almond flour\n• **Thickening** → Cornstarch (use half the amount)\n• **Lighter cakes** → Cake flour (−2 tbsp per cup)\n• **Protein-rich** → Chickpea flour\n• **Keto** → Coconut flour (use ¼ amount + extra eggs)\n\n👨‍🍳 Almond flour makes the most delicious gluten-free bakes!";
    }
    if (query.contains('sugar')) {
      return "🍬 **Sugar Substitutes:**\n\n• **Honey (1:1)** → Reduce liquid in recipe by ¼ cup\n• **Maple syrup** → Adds warm caramel notes\n• **Zero-calorie** → Stevia (use ⅛ the amount!)\n• **Brown sugar** → White sugar + 1 tsp molasses\n• **Natural & moist** → Mashed ripe banana\n\n👨‍🍳 Honey is my go-to for a natural, wholesome sweetener!";
    }
    if (query.contains('cream') || query.contains('heavy cream')) {
      return "🍶 **Heavy Cream Substitutes:**\n\n• **Richest** → Full-fat coconut cream (1:1)\n• **Lighter** → Half-and-half + 1 tbsp butter\n• **Dairy-free** → Cashew cream (blend soaked cashews)\n• **For soups** → Greek yogurt (don't boil)\n• **Whipping** → Coconut cream, chilled overnight\n\n👨‍🍳 Coconut cream whips beautifully for desserts!";
    }
    return "🔄 **Smart Substitutions**\n\nTell me which ingredient you're out of and I'll find the perfect swap!\n\nExamples:\n• *'What can replace eggs?'*\n• *'Substitute for butter in baking'*\n• *'I'm out of milk, what do I use?'*\n• *'Replace flour for gluten-free'*\n• *'Sugar substitute'*\n\n👨‍🍳 Never let a missing ingredient stop you!";
  }

  String _suggestFromInventory(List<String> items) {
    return "🍳 Egg fried rice (quick & easy)\n🍲 Vegetable stir-fry with whatever's fresh\n🍝 Simple pasta with pantry staples\n🥘 One-pot soup using your veg";
  }

  String _pastaCarbonaraRecipe() {
    return """🍝 **Pasta Carbonara**
*Classic Roman · 20 min · Easy*

**Ingredients (2 servings):**
• 200g spaghetti
• 100g pancetta or bacon, diced
• 2 large eggs + 1 yolk
• 50g Pecorino Romano, grated
• 2 garlic cloves
• Salt & black pepper

**Instructions:**
1️⃣ Cook pasta in well-salted water (save 1 cup pasta water before draining)
2️⃣ Fry pancetta with garlic until golden & crispy — remove garlic
3️⃣ Beat eggs with cheese and plenty of black pepper
4️⃣ Drain pasta, toss into the pancetta pan — take it **off the heat!**
5️⃣ Pour egg mixture over, toss rapidly while adding pasta water bit by bit until silky
6️⃣ Season and serve immediately

👨‍🍳 **Chef's secret:** Always take the pan off heat before adding eggs. That's what makes it creamy, not scrambled!""";
  }

  String _butterChickenRecipe() {
    return """🍛 **Butter Chicken** (Murgh Makhani)
*Restaurant-style · 45 min · Medium*

**Marinade:**
• 500g chicken breast, cubed
• 1 cup yogurt · 1 tsp each: turmeric, cumin, coriander, garam masala, chilli

**Sauce:**
• 3 tbsp butter · 1 large onion · 4 garlic cloves · 1 inch ginger
• 400g crushed tomatoes · 100ml heavy cream · 1 tsp sugar · salt

**Instructions:**
1️⃣ Marinate chicken 30 min (or overnight for best flavour)
2️⃣ Grill or pan-fry chicken until charred edges — set aside
3️⃣ Sauté onion in butter until deep golden (10 min)
4️⃣ Add garlic & ginger paste, cook 2 min
5️⃣ Add tomatoes, simmer 15 min until thick
6️⃣ Blend sauce smooth, return to pan
7️⃣ Add cream, butter, sugar — simmer 5 min
8️⃣ Add chicken, simmer 10 min — done!

🍽️ Serve with butter naan or basmati rice
👨‍🍳 **Tip:** The char on the chicken is the secret to that restaurant flavour!""";
  }

  String _friedRiceRecipe() {
    return """🍳 **Egg Fried Rice**
*15 min · Easy · Perfect for leftover rice*

**Ingredients (2 servings):**
• 2 cups cooked rice (day-old is best!)
• 2 eggs, beaten
• ½ cup frozen peas & carrots
• 3 spring onions, sliced
• 2 tbsp soy sauce
• 1 tsp sesame oil
• 2 garlic cloves, minced
• Oil for frying

**Instructions:**
1️⃣ Heat oil in wok/pan on **high** heat
2️⃣ Add garlic, stir 30 seconds
3️⃣ Push aside, pour in eggs — scramble until just set
4️⃣ Add vegetables, stir fry 2 min
5️⃣ Add rice, break up clumps, stir fry 3–4 min on high heat
6️⃣ Add soy sauce, toss everything together
7️⃣ Drizzle sesame oil, toss with spring onions

👨‍🍳 **Secret:** Day-old cold rice makes ALL the difference — fresh rice turns mushy!""";
  }

  String _pancakeRecipe() {
    return """🥞 **Fluffy Pancakes**
*20 min · Easy · Weekend favourite*

**Ingredients (8 pancakes):**
• 1 cup all-purpose flour
• 1 tbsp sugar · 1 tsp baking powder · ½ tsp baking soda · pinch of salt
• 1 cup buttermilk (or milk + 1 tbsp lemon juice, rest 5 min)
• 1 egg · 2 tbsp melted butter · 1 tsp vanilla

**Instructions:**
1️⃣ Mix all dry ingredients in a bowl
2️⃣ Whisk all wet ingredients separately
3️⃣ Pour wet into dry — mix until *just combined* (lumps are totally fine!)
4️⃣ Rest batter 5 minutes — this is important!
5️⃣ Heat non-stick pan on medium, lightly butter
6️⃣ Pour ¼ cup batter per pancake
7️⃣ Cook until bubbles form & edges look set (~2 min)
8️⃣ Flip once, cook 1–2 min more

👨‍🍳 **Secret:** NEVER overmix! Lumpy batter = fluffy pancakes. Overmixing = dense, chewy pancakes.

Serve with maple syrup, fresh berries & butter! 🍓""";
  }

  String _omeletteRecipe() {
    return """🍳 **Classic French Omelette**
*5 min · Easy once you know the technique*

**Ingredients (1 serving):**
• 3 large eggs
• 1 tbsp cold butter
• Salt & white pepper
• Optional filling: grated cheese, fresh herbs, ham

**Instructions:**
1️⃣ Beat eggs vigorously with a fork — 30 seconds. No air bubbles.
2️⃣ Season with salt & white pepper
3️⃣ Heat pan on medium-high, add butter
4️⃣ When butter foams & foam starts to subside, pour in eggs
5️⃣ Immediately stir with fork in small circular motions
6️⃣ When 80% set, stop stirring — leave to cook 15 seconds
7️⃣ Add filling on one side
8️⃣ Fold in thirds and slide onto plate

The perfect omelette is **pale yellow** — never browned!

👨‍🍳 **Chef's note:** The whole thing takes 90 seconds. It's all about confidence and the right heat. Practice makes perfect!""";
  }

  String _pizzaRecipe() {
    return """🍕 **Homemade Pizza**
*Better than delivery · 90 min (inc. rise)*

**Dough (2 pizzas):**
• 2 cups bread flour · 1 tsp instant yeast · 1 tsp salt · 1 tsp sugar
• ¾ cup warm water · 2 tbsp olive oil

**Quick Tomato Sauce:**
• 400g crushed tomatoes · 2 garlic cloves · 1 tsp oregano · salt & pepper

**Toppings:** Mozzarella + your favourites!

**Instructions:**
1️⃣ Mix dough ingredients, knead 8 min until smooth & elastic
2️⃣ Cover, rise in warm place 1 hour until doubled
3️⃣ Sauce: simmer tomatoes + garlic + herbs 15 min
4️⃣ Preheat oven to **250°C (max heat!)** — preheat tray too
5️⃣ Stretch dough thin on oiled tray (don't use rolling pin!)
6️⃣ Spread sauce thinly, add cheese & toppings
7️⃣ Bake 10–12 min until crust is golden & cheese bubbly

👨‍🍳 **Secret:** Max oven temperature + preheated tray = crispy base!""";
  }

  String _lentilSoupRecipe() {
    return """🍲 **Red Lentil Soup**
*30 min · Easy · Nutritious*

**Ingredients (4 servings):**
• 1 cup red lentils, rinsed
• 1 large onion, diced · 3 garlic cloves · 2 carrots, diced
• 400g crushed tomatoes · 4 cups veg stock
• 2 tsp cumin · 1 tsp turmeric · 1 tsp smoked paprika
• 2 tbsp olive oil · Lemon juice, salt & pepper
• Fresh parsley to serve

**Instructions:**
1️⃣ Sauté onion in olive oil until soft (5 min)
2️⃣ Add garlic & carrots, cook 2 min
3️⃣ Add spices, stir 1 min until fragrant
4️⃣ Add lentils, tomatoes & stock — bring to boil
5️⃣ Simmer 20 min until lentils are soft
6️⃣ Blend half the soup for a creamy texture
7️⃣ Season with lemon juice, salt & pepper
8️⃣ Top with parsley & a drizzle of olive oil

👨‍🍳 **Tip:** That squeeze of lemon at the end brightens the whole dish!""";
  }

  String _biryaniRecipe() {
    return """🍛 **Chicken Biryani**
*Layered fragrant rice · 1 hr · Worth every minute*

**Ingredients (4 servings):**
🍗 **Chicken:**
• 500g chicken, bone-in pieces
• 1 cup yogurt · 2 tsp biryani masala · 1 tsp each: turmeric, chilli, salt
• 1 tbsp ginger-garlic paste

🍚 **Rice:**
• 2 cups basmati rice, soaked 30 min
• Whole spices: 2 bay leaves, 4 cardamom, 4 cloves, 1 cinnamon stick

**Aromatics:** 2 large onions (thinly sliced, deep fried until golden)
Saffron in 4 tbsp warm milk · Fresh mint & coriander

**Instructions:**
1️⃣ Marinate chicken 1 hr (or overnight)
2️⃣ Cook rice with whole spices until 70% done — drain
3️⃣ Brown marinated chicken in oil 5–7 min each side
4️⃣ Layer: chicken → rice → fried onions → mint → saffron milk
5️⃣ Seal pot tightly (use dough or foil), cook on dum (low heat) 25 min
6️⃣ Rest 10 min before opening — gently fluff and serve

👨‍🍳 **Chef's note:** The dum (steam cooking) is the magic. Don't lift the lid early!""";
  }

  String _dosaRecipe() {
    return """🫓 **Masala Dosa**
*South Indian classic · Batter: overnight · Cooking: 20 min*

**Batter:**
• 2 cups rice + ½ cup urad dal — soak separately 6 hrs
• Blend together with water to smooth batter
• Ferment overnight (8–12 hrs in warm place)

**Potato Masala (filling):**
• 4 boiled potatoes, roughly mashed
• 1 onion, 2 green chillies, 1 tsp mustard seeds
• ½ tsp turmeric · Curry leaves · Oil · Salt

**Instructions:**
1️⃣ Make masala: splutter mustard seeds, add onion + chillies + curry leaves
2️⃣ Add turmeric, potatoes — mix and season well
3️⃣ Heat tawa/griddle on medium-high, lightly oil
4️⃣ Pour ½ cup batter, spread in thin circle immediately
5️⃣ Drizzle oil on edges, cook until crispy & golden
6️⃣ Add masala in centre, fold and serve

🍽️ Serve with sambar & coconut chutney
👨‍🍳 **Key:** A hot, well-seasoned pan is the secret to a crispy dosa!""";
  }

  String _simplePastaRecipe() {
    return """🍝 **Simple Pasta Pomodoro**
*Italian classic · 20 min · Easy*

**Ingredients (2 servings):**
• 200g pasta (spaghetti or penne)
• 400g crushed tomatoes
• 4 garlic cloves, thinly sliced
• 3 tbsp good olive oil
• Fresh basil · Salt & pepper
• Parmesan to serve

**Instructions:**
1️⃣ Cook pasta in well-salted water until al dente (save 1 cup pasta water)
2️⃣ Gently sauté garlic in olive oil on low heat until golden (3–4 min)
3️⃣ Add tomatoes, season with salt — simmer 10 min
4️⃣ Add drained pasta + splash of pasta water, toss to combine
5️⃣ Tear fresh basil over the top

👨‍🍳 **Secret:** Low & slow garlic in good olive oil is the base of Italian cooking. Never rush it!

Want pasta carbonara or another pasta dish? Just ask! 🍝""";
  }
}
