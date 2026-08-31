// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: subscription_repository.dart
//
// Purpose:
// Abstract contract and local Hive repository implementation for recurring subscriptions.
//
// Responsibilities:
// - Read all subscriptions from Hive `subscriptionsBox` sorted by next payment date ascending.
// - Save or update `SubscriptionModel` using `subscription.id` as primary key.
// - Delete subscriptions from `subscriptionsBox`.
//
// Data Flow:
// SubscriptionNotifier → SubscriptionRepository → HiveService.subscriptionsBox
//
// Important Rules:
// - Sorts read subscriptions by `nextPaymentDate` ascending.
//
// Main Operations:
// - getSubscriptions(): Fetch sorted active subscriptions
// - saveSubscription(subscription): Upsert subscription model by ID
// - deleteSubscription(id): Delete subscription from Hive
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl();
});

abstract class SubscriptionRepository {
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<void> saveSubscription(SubscriptionModel subscription);
  Future<void> deleteSubscription(String id);
  Stream<List<SubscriptionModel>>? watchSubscriptions();
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final List<SubscriptionModel> _memoryStore = [];

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUid => _auth?.currentUser?.uid;

  @override
  Stream<List<SubscriptionModel>>? watchSubscriptions() {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty || _firestore == null) return null;

    try {
      return _firestore!
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => SubscriptionModel.fromMap(doc.data()))
                .toList();
            list.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
            return list;
          });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('subscriptions')
            .get();

        final List<SubscriptionModel> subscriptions = [];
        for (var doc in snapshot.docs) {
          subscriptions.add(SubscriptionModel.fromMap(doc.data()));
        }
        subscriptions.sort(
          (a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate),
        );
        return subscriptions;
      } catch (_) {}
    }

    final list = List<SubscriptionModel>.from(_memoryStore);
    list.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return list;
  }

  @override
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    _memoryStore.removeWhere((s) => s.id == subscription.id);
    _memoryStore.add(subscription);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('subscriptions')
            .doc(subscription.id)
            .set(subscription.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    _memoryStore.removeWhere((s) => s.id == id);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('subscriptions')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }
}
