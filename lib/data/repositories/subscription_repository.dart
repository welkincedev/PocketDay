// ============================================================
// PocketDay — SubscriptionRepositoryImpl
// ============================================================
//
// Purpose:
// Repository managing recurring subscription persistence, cache-first reads, and optimistic offline writes.
//
// Responsibilities:
// - Read SubscriptionModel documents from local Firestore cache first for instant UI rendering.
// - Perform optimistic local updates and dispatch Firestore document writes in the background.
// - Provide real-time Firestore snapshots stream via watchSubscriptions().
// - Maintain in-memory store for unit test environments.
//
// Data Flow:
// AddSubscriptionSheet → SubscriptionProvider → SubscriptionRepositoryImpl → Firestore Cache / Cloud Storage
//
// Firestore Structure:
// Path: users/{uid}/subscriptions/{subscriptionId}
//
// Important Rules:
// - UID Isolation: Requires active user authentication (`FirebaseAuth.instance.currentUser?.uid`).
// - Cache-First Read: getSubscriptions() reads local cache first for instant rendering.
// - Optimistic Writes: saveSubscription() and deleteSubscription() update local state and dispatch background Firestore writes (`unawaited`).
//
// Main Operations:
// - getSubscriptions() — Returns cached subscriptions immediately, with fallback for fresh installs.
// - saveSubscription() — Optimistically updates subscription and dispatches background Firestore write.
// - deleteSubscription() — Optimistically removes subscription and dispatches background Firestore delete.
// - watchSubscriptions() — Returns real-time Stream<List<SubscriptionModel>> of user subscriptions.
//
// Dependencies / Collaborators:
// - FirebaseFirestore — Storage engine for subscription records.
// - FirebaseAuth — Provides active user UID context.
// - SubscriptionModel — Entity model representing recurring subscriptions.
//
// ============================================================

import 'dart:async';
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
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('subscriptions')
              .get(const GetOptions(source: Source.cache));
          
          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore!
                .collection('users')
                .doc(uid)
                .collection('subscriptions')
                .get()
                .timeout(const Duration(seconds: 3));
          }
        } catch (_) {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('subscriptions')
              .get()
              .timeout(const Duration(seconds: 3));
        }

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
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .doc(subscription.id)
          .set(subscription.toMap(), SetOptions(merge: true))
          .catchError((_) {}));
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    _memoryStore.removeWhere((s) => s.id == id);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .doc(id)
          .delete()
          .catchError((_) {}));
    }
  }
}
