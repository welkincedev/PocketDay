// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: savings_goal_repository.dart
//
// Purpose:
// Abstract contract and local Hive implementation for savings target entities.
//
// Responsibilities:
// - Read all saved goals from Hive `goalsBox`.
// - Save or update `SavingsGoalModel` by ID.
// - Delete savings goals by ID.
//
// Data Flow:
// SavingsGoalsNotifier → SavingsGoalRepository → HiveService.goalsBox
//
// Important Rules:
// - Stores savings goal maps using `goal.id` primary keys.
//
// Main Operations:
// - getGoals(): Fetch all savings goals from Hive
// - saveGoal(goal): Upsert goal by ID
// - deleteGoal(id): Delete goal from Hive
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_goal_model.dart';

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepositoryImpl();
});

abstract class SavingsGoalRepository {
  Future<List<SavingsGoalModel>> getGoals();
  Future<void> saveGoal(SavingsGoalModel goal);
  Future<void> deleteGoal(String id);
}

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final List<SavingsGoalModel> _memoryStore = [];

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
  Future<List<SavingsGoalModel>> getGoals() async {
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('savings_goals')
            .get();

        final List<SavingsGoalModel> goals = [];
        for (var doc in snapshot.docs) {
          goals.add(SavingsGoalModel.fromMap(doc.data()));
        }
        return goals;
      } catch (_) {}
    }

    return List<SavingsGoalModel>.from(_memoryStore);
  }

  @override
  Future<void> saveGoal(SavingsGoalModel goal) async {
    _memoryStore.removeWhere((g) => g.id == goal.id);
    _memoryStore.add(goal);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('savings_goals')
            .doc(goal.id)
            .set(goal.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    _memoryStore.removeWhere((g) => g.id == id);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('savings_goals')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }
}
