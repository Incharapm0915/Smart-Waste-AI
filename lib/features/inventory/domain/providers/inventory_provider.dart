import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/inventory_item_model.dart';

CollectionReference<Map<String, dynamic>> _inventoryCol(String uid) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inventory');

final inventoryProvider =
    StreamProvider<List<InventoryItemModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return _inventoryCol(uid)
      .orderBy('expiryDate')
      .snapshots()
      .map((snap) => snap.docs
          .map(InventoryItemModel.fromFirestore)
          .where((item) => !item.isConsumed)
          .toList());
});

final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<void>>(
  (ref) => InventoryNotifier(),
);

class InventoryNotifier extends StateNotifier<AsyncValue<void>> {
  final _firestore = FirebaseFirestore.instance;

  InventoryNotifier() : super(const AsyncValue.data(null));

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _inventoryCol(uid);
  }

  Future<void> addItem(InventoryItemModel item) async {
    state = const AsyncValue.loading();
    try {
      await _col?.add(item.toFirestore());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateItem(InventoryItemModel item) async {
    state = const AsyncValue.loading();
    try {
      await _col?.doc(item.id).update(item.toFirestore());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markConsumed(String itemId) async {
    try {
      await _col?.doc(itemId).update({
        'isConsumed': true,
        'consumedAt': FieldValue.serverTimestamp(),
      });
      await _logUsage(itemId, 'consumed');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markWasted(String itemId) async {
    try {
      await _col?.doc(itemId).update({
        'isConsumed': true,
        'wasted': true,
        'wastedAt': FieldValue.serverTimestamp(),
      });
      await _logWaste(itemId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    await _col?.doc(itemId).delete();
  }

  Future<void> _logUsage(String itemId, String action) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('usage_history')
        .add({
      'itemId': itemId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _logWaste(String itemId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('waste_logs')
        .add({
      'itemId': itemId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
