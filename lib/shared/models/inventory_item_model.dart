import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String emoji;
  final DateTime expiryDate;
  final DateTime addedDate;
  final double quantity;
  final String unit;
  final String? barcode;
  final String? imageUrl;
  final double? confidence;
  final bool isConsumed;
  final String? notes;

  const InventoryItemModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.emoji,
    required this.expiryDate,
    required this.addedDate,
    required this.quantity,
    required this.unit,
    this.barcode,
    this.imageUrl,
    this.confidence,
    this.isConsumed = false,
    this.notes,
  });

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Other',
      emoji: data['emoji'] ?? '🥫',
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      addedDate: (data['addedDate'] as Timestamp).toDate(),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: data['unit'] ?? 'pcs',
      barcode: data['barcode'],
      imageUrl: data['imageUrl'],
      confidence: (data['confidence'] as num?)?.toDouble(),
      isConsumed: data['isConsumed'] ?? false,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'emoji': emoji,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'addedDate': Timestamp.fromDate(addedDate),
      'quantity': quantity,
      'unit': unit,
      if (barcode != null) 'barcode': barcode,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (confidence != null) 'confidence': confidence,
      'isConsumed': isConsumed,
      if (notes != null) 'notes': notes,
    };
  }

  InventoryItemModel copyWith({
    String? name,
    String? category,
    String? emoji,
    DateTime? expiryDate,
    double? quantity,
    String? unit,
    bool? isConsumed,
    String? notes,
  }) {
    return InventoryItemModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      barcode: barcode,
      imageUrl: imageUrl,
      confidence: confidence,
      isConsumed: isConsumed ?? this.isConsumed,
      notes: notes ?? this.notes,
    );
  }

  static String categoryEmoji(String category) {
    const emojis = {
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
    return emojis[category] ?? '🥫';
  }
}
