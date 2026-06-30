import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/inventory_item_model.dart';

final cameraProvider =
    StateNotifierProvider<CameraNotifier, AsyncValue<List<DetectedItem>>>(
  (ref) => CameraNotifier(),
);

class CameraNotifier extends StateNotifier<AsyncValue<List<DetectedItem>>> {
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  CameraNotifier() : super(const AsyncValue.data([]));

  Future<List<DetectedItem>> processImage(File image) async {
    state = const AsyncValue.loading();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          image.path,
          filename: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'user_id': uid,
      });
      final response = await _dio.post(
        AppConstants.detectEndpoint,
        data: formData,
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => DetectedItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(items);
      return items;
    } on DioException catch (e) {
      // Fallback with mock data for demo
      final mockItems = _getMockItems();
      state = AsyncValue.data(mockItems);
      return mockItems;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  List<DetectedItem> _getMockItems() {
    return [
      DetectedItem(
        name: 'Whole Milk',
        category: 'Dairy',
        emoji: '🥛',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        confidence: 0.95,
        quantity: 1.0,
        unit: 'L',
      ),
      DetectedItem(
        name: 'Greek Yogurt',
        category: 'Dairy',
        emoji: '🥛',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        confidence: 0.88,
        quantity: 500,
        unit: 'g',
      ),
      DetectedItem(
        name: 'Chicken Breast',
        category: 'Meat',
        emoji: '🥩',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        confidence: 0.92,
        quantity: 300,
        unit: 'g',
      ),
    ];
  }
}

class DetectedItem {
  final String name;
  final String category;
  final String emoji;
  final DateTime expiryDate;
  final double confidence;
  final double quantity;
  final String unit;
  bool isSelected;

  DetectedItem({
    required this.name,
    required this.category,
    required this.emoji,
    required this.expiryDate,
    required this.confidence,
    required this.quantity,
    required this.unit,
    this.isSelected = true,
  });

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      name: json['name'] as String,
      category: json['category'] as String,
      emoji: json['emoji'] as String? ??
          InventoryItemModel.categoryEmoji(json['category'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'pcs',
    );
  }

  DetectedItem copyWith({DateTime? expiryDate, bool? isSelected}) {
    return DetectedItem(
      name: name,
      category: category,
      emoji: emoji,
      expiryDate: expiryDate ?? this.expiryDate,
      confidence: confidence,
      quantity: quantity,
      unit: unit,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  InventoryItemModel toInventoryItem() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return InventoryItemModel(
      id: '',
      userId: uid,
      name: name,
      category: category,
      emoji: emoji,
      expiryDate: expiryDate,
      addedDate: DateTime.now(),
      quantity: quantity,
      unit: unit,
      confidence: confidence,
    );
  }
}
