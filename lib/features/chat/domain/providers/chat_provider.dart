import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/chat_message_model.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(),
);

const _uuid = Uuid();

const _welcomeText =
    "Hi! I'm your AI Food Assistant 🌱\n\nAsk me anything about:\n• Recipes using your ingredients\n• Food storage tips\n• Expiry & waste reduction\n• Nutrition advice";

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  ChatNotifier()
      : super([
          ChatMessage(
            id: 'welcome',
            text: _welcomeText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ]);

  Future<void> sendMessage(String text) async {
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
        data: {'message': text.trim(), 'context': 'food_management'},
      );
      final botText = response.data['response'] as String? ??
          _getMockResponse(text);
      _replaceLoading(botText);
    } catch (_) {
      _replaceLoading(_getMockResponse(text));
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

  String _getMockResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('expir') || q.contains('spoil') || q.contains('old')) {
      return "🕐 Check items expiring soon in your Inventory screen — they're sorted by urgency.\n\nQuick tip: FIFO rule — First In, First Out. Always use older items before newer ones!";
    }
    if (q.contains('recipe') || q.contains('cook') || q.contains('make') || q.contains('eat')) {
      return "🍳 Head to the Recipes tab! Your AI generates personalised recipes based on ingredients that are about to expire.\n\nThis helps you cook something delicious *and* reduce waste at the same time. Win-win! 🌱";
    }
    if (q.contains('store') || q.contains('storage') || q.contains('keep') || q.contains('refrigerat')) {
      return "📦 Storage tips:\n\n• **Fruits & veggies**: Most keep longer in the fridge crisper drawer.\n• **Herbs**: Store in a glass of water like flowers.\n• **Bread**: Freeze if you won't use it in 3 days.\n• **Leftovers**: Always cover and refrigerate within 2 hours.";
    }
    if (q.contains('waste') || q.contains('reduce') || q.contains('save') || q.contains('money')) {
      return "♻️ Top waste-reduction tips:\n\n1. Plan meals before shopping.\n2. Buy only what you need.\n3. Use the Scan feature to track inventory.\n4. Cook in batches and freeze leftovers.\n5. Compost unavoidable scraps!\n\nYour Sustainability Score improves as you reduce waste 🌍";
    }
    if (q.contains('nutrition') || q.contains('healthy') || q.contains('calori') || q.contains('protein')) {
      return "🥦 Nutrition basics:\n\n• Balance protein, carbs, and healthy fats in every meal.\n• Leafy greens are your best friends — low calorie, high nutrients.\n• Each recipe in the app shows calorie and macro info.\n\nWant me to suggest a healthy recipe idea? 😊";
    }
    if (q.contains('fruit') || q.contains('vegetable') || q.contains('meat') || q.contains('dairy')) {
      return "🛒 A balanced kitchen should have:\n\n🥩 Protein: meat, fish, eggs, legumes\n🥛 Dairy: milk, cheese, yogurt\n🍎 Fruits: 2–3 servings/day\n🥦 Vegetables: 5+ servings/day\n🌾 Grains: choose whole grains\n\nScan your groceries to keep track easily!";
    }
    if (q.contains('shopping') || q.contains('buy') || q.contains('grocery') || q.contains('list')) {
      return "🛍️ Check your Shopping screen — your AI assistant has already suggested items based on your current inventory gaps!\n\nPro tip: Always shop with a list and never on an empty stomach 😄";
    }
    if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('how are')) {
      return "Hey there! 👋 I'm doing great, ready to help you manage your food smarter!\n\nWhat would you like to know? You can ask about recipes, storage tips, expiry tracking, or waste reduction. 🌿";
    }
    if (q.contains('thank')) {
      return "You're welcome! 😊 Happy to help. Remember — every small action to reduce food waste makes a big difference for our planet 🌍\n\nAnything else I can help with?";
    }

    return "🤖 Great question! Here's what I suggest:\n\n• Use the **Scan** feature to keep your inventory up to date.\n• Check **Recipes** for AI-generated ideas using expiring items.\n• Visit **Analytics** to track your waste reduction progress.\n\nFeel free to ask me anything specific! 🌱";
  }
}
