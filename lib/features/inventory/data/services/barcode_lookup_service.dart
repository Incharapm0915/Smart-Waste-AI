import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductInfo {
  final String name;
  final String category;
  final String emoji;
  final String? brand;
  final String barcode;

  const ProductInfo({
    required this.name,
    required this.category,
    required this.emoji,
    required this.barcode,
    this.brand,
  });
}

class BarcodeLookupService {
  static Future<ProductInfo?> lookup(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'SmartWasteAI/1.0',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>;
      final name = (product['product_name'] as String? ?? '').trim();
      if (name.isEmpty) return null;

      final tags = (product['categories_tags'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [];
      final category = _mapCategory(tags);

      return ProductInfo(
        name: name,
        category: category,
        emoji: _categoryEmoji(category),
        brand: product['brands'] as String?,
        barcode: barcode,
      );
    } catch (_) {
      return null;
    }
  }

  static String _mapCategory(List<String> tags) {
    for (final tag in tags) {
      if (_matches(tag, ['dairy', 'milk', 'cheese', 'yogurt', 'cream', 'butter'])) return 'Dairy';
      if (_matches(tag, ['meat', 'beef', 'chicken', 'pork', 'lamb', 'turkey', 'poultry'])) return 'Meat';
      if (_matches(tag, ['seafood', 'fish', 'salmon', 'tuna', 'shrimp'])) return 'Seafood';
      if (_matches(tag, ['vegetable', 'veggie', 'salad', 'lettuce', 'broccoli', 'carrot'])) return 'Vegetables';
      if (_matches(tag, ['fruit', 'apple', 'banana', 'berry', 'citrus', 'mango'])) return 'Fruits';
      if (_matches(tag, ['bread', 'bakery', 'pastry', 'cake', 'biscuit'])) return 'Bakery';
      if (_matches(tag, ['cereal', 'pasta', 'rice', 'grain', 'flour', 'oat'])) return 'Grains';
      if (_matches(tag, ['snack', 'chip', 'crisp', 'popcorn', 'cracker', 'chocolate', 'candy', 'sweet'])) return 'Snacks';
      if (_matches(tag, ['beverage', 'drink', 'juice', 'water', 'soda', 'coffee', 'tea'])) return 'Beverages';
      if (_matches(tag, ['sauce', 'condiment', 'spice', 'seasoning', 'dressing', 'oil', 'vinegar', 'jam', 'spread'])) return 'Condiments';
      if (_matches(tag, ['frozen'])) return 'Frozen';
      if (_matches(tag, ['egg'])) return 'Eggs';
    }
    return 'Other';
  }

  static bool _matches(String tag, List<String> keywords) =>
      keywords.any((k) => tag.contains(k));

  static String _categoryEmoji(String category) {
    const map = {
      'Dairy': '🥛',
      'Meat': '🥩',
      'Vegetables': '🥦',
      'Fruits': '🍎',
      'Grains': '🌾',
      'Snacks': '🍿',
      'Beverages': '🧃',
      'Condiments': '🫙',
      'Frozen': '🧊',
      'Bakery': '🍞',
      'Seafood': '🐟',
      'Eggs': '🥚',
    };
    return map[category] ?? '🥫';
  }
}
