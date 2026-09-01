// ============================================================
// PocketDay — BudgetRepositoryImpl
// ============================================================
//
// Purpose:
// Repository managing monthly overall and category-specific budget persistence,
// cache-first reads, and optimistic offline writes.
//
// Responsibilities:
// - Read budget targets from local Firestore cache first for instant UI startup.
// - Perform optimistic local updates and dispatch Firestore document writes in the background.
// - Provide real-time Firestore snapshots stream via watchBudgets().
// - Maintain in-memory store for unit test environments.
//
// Data Flow:
// AddBudgetBottomSheet → BudgetProvider → BudgetRepositoryImpl → Firestore Cache / Cloud Storage
//
// Firestore Structure:
// Path: users/{uid}/budgets/{budgetId}
//
// Important Rules:
// - UID Isolation: Requires active user authentication (`FirebaseAuth.instance.currentUser?.uid`).
// - Overall budget limit documents have categoryId == null; category limits have non-null categoryId.
// - Cache-First Read: getBudgets() reads local cache first for instant rendering.
// - Optimistic Writes: saveBudget() and deleteBudget() update local state and dispatch background Firestore writes (`unawaited`).
//
// Main Operations:
// - getBudgets() — Returns cached budgets immediately, with fallback for fresh installs.
// - saveBudget() — Optimistically updates budget and dispatches background Firestore write.
// - deleteBudget() — Optimistically removes budget and dispatches background Firestore delete.
// - watchBudgets() — Returns real-time Stream<List<BudgetModel>> of user budgets.
//
// Dependencies / Collaborators:
// - FirebaseFirestore — Storage engine for budget records.
// - FirebaseAuth — Provides active user UID context.
// - BudgetModel — Entity model representing monthly budget targets.
//
// ============================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl();
});

abstract class BudgetRepository {
  Future<List<BudgetModel>> getBudgets();
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);
  Stream<List<BudgetModel>>? watchBudgets();
}

class BudgetRepositoryImpl implements BudgetRepository {
  final List<BudgetModel> _memoryStore = [];

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
  Stream<List<BudgetModel>>? watchBudgets() {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty || _firestore == null) return null;

    try {
      return _firestore!
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BudgetModel.fromMap(doc.data()))
                .toList();
          });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('budgets')
              .get(const GetOptions(source: Source.cache));
          
          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore!
                .collection('users')
                .doc(uid)
                .collection('budgets')
                .get()
                .timeout(const Duration(seconds: 3));
          }
        } catch (_) {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('budgets')
              .get()
              .timeout(const Duration(seconds: 3));
        }

        final List<BudgetModel> budgets = [];
        for (var doc in snapshot.docs) {
          budgets.add(BudgetModel.fromMap(doc.data()));
        }
        return budgets;
      } catch (_) {}
    }

    return List<BudgetModel>.from(_memoryStore);
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    _memoryStore.removeWhere((b) => b.id == budget.id);
    _memoryStore.add(budget);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(budget.id)
          .set(budget.toMap(), SetOptions(merge: true))
          .catchError((_) {}));
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    _memoryStore.removeWhere((b) => b.id == id);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(id)
          .delete()
          .catchError((_) {}));
    }
  }
}
