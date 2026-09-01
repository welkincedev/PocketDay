// ============================================================
// PocketDay — TransactionRepositoryImpl
// ============================================================
//
// Purpose:
// Primary data repository handling transaction persistence, cache-first reads,
// optimistic offline writes, and background Firestore synchronization.
//
// Responsibilities:
// - Read transactions from local Firestore cache first for zero startup delay.
// - Perform optimistic local writes and fire Firestore document updates in the background.
// - Provide real-time Firestore snapshots stream via watchTransactions().
// - Maintain in-memory store for unit test environments.
//
// Data Flow:
// UI Form / Sheet → TransactionsProvider → TransactionRepositoryImpl → Firestore Cache / Cloud Storage
//
// Firestore Structure:
// Path: users/{uid}/transactions/{transactionId}
//
// Important Rules:
// - UID Isolation: Requires active user authentication (`FirebaseAuth.instance.currentUser?.uid`).
// - Cache-First Read: getTransactions() reads local cache first so UI renders in < 5ms.
// - Optimistic Writes: add/update/delete update local state and fire Firestore writes in background (`unawaited`), allowing UI sheet dismissal without waiting for cloud ACK.
// - Single Source of Truth: Firestore native SDK queues offline writes and syncs automatically upon reconnection.
//
// Main Operations:
// - getTransactions() — Returns cached transactions immediately, with fallback for fresh installs.
// - addTransaction() — Optimistically adds transaction and dispatches background Firestore write.
// - updateTransaction() — Optimistically updates transaction and dispatches background Firestore write.
// - deleteTransaction() — Optimistically removes transaction and dispatches background Firestore delete.
// - watchTransactions() — Returns real-time Stream<List<TransactionModel>> of user transactions.
//
// Dependencies / Collaborators:
// - FirebaseFirestore — Storage engine with native offline persistence.
// - FirebaseAuth — Provides active user UID context.
// - TransactionModel — Financial transaction entity.
//
// ============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(TransactionModel transaction);
  Stream<List<TransactionModel>>? watchTransactions();
}

class TransactionRepositoryImpl implements TransactionRepository {
  final List<TransactionModel> _memoryStore = [];

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
  Stream<List<TransactionModel>>? watchTransactions() {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty || _firestore == null) return null;

    try {
      return _firestore!
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) {
              return TransactionModel.fromMap(doc.data());
            }).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        // Cache-first read: Attempt reading from Firestore local cache for instant < 5ms rendering
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .get(const GetOptions(source: Source.cache));
          
          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore!
                .collection('users')
                .doc(uid)
                .collection('transactions')
                .get()
                .timeout(const Duration(seconds: 3));
          }
        } catch (_) {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .get()
              .timeout(const Duration(seconds: 3));
        }

        final List<TransactionModel> txns = [];
        for (var doc in snapshot.docs) {
          txns.add(TransactionModel.fromMap(doc.data()));
        }
        txns.sort((a, b) => b.date.compareTo(a.date));
        return txns;
      } catch (_) {}
    }

    final list = List<TransactionModel>.from(_memoryStore);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await updateTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _memoryStore.removeWhere((t) => t.id == id);
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      // Dispatch write to Firestore in background (unawaited) so UI pops sheet immediately
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(id)
          .delete()
          .catchError((_) {}));
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    _memoryStore.removeWhere((t) => t.id == transaction.id);
    _memoryStore.add(transaction);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      // Dispatch write to Firestore in background (unawaited) so UI pops sheet immediately
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap(), SetOptions(merge: true))
          .catchError((_) {}));
    }
  }
}
