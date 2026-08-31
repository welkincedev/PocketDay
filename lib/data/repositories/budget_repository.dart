// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: budget_repository.dart
//
// Purpose:
// Abstract contract and local Hive repository implementation for overall and category budget limits.
//
// Responsibilities:
// - Read all stored budget records from Hive `budgetBox`.
// - Save or update budget models by budget `id`.
// - Delete budgets from `budgetBox`.
//
// Data Flow:
// BudgetNotifier → BudgetRepository → HiveService.budgetBox
//
// Important Rules:
// - `saveBudget` uses `budget.id` as key in Hive box to prevent duplicates upon editing.
//
// Main Operations:
// - getBudgets(): Read all budget entries
// - saveBudget(budget): Upsert budget model by ID
// - deleteBudget(id): Remove budget by ID
// ============================================================

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
        final snapshot = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .get();

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
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(budget.id)
            .set(budget.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    _memoryStore.removeWhere((b) => b.id == id);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }
}
