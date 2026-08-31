// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: goal_repository.dart
//
// Purpose:
// Abstract contract and local Hive repository implementation for financial goals.
//
// Responsibilities:
// - Read all stored goal records from Hive `goalsBox`.
// - Save or update goal models using `goal.id` as primary key.
// - Delete goals from `goalsBox`.
//
// Data Flow:
// GoalsNotifier → GoalRepository → HiveService.goalsBox
//
// Important Rules:
// - All updates and saves use `goal.id` key to prevent duplicate entries upon editing.
//
// Main Operations:
// - getGoals(): Read all stored goal entities
// - saveGoal(goal): Upsert goal by ID
// - deleteGoal(id): Delete goal entry by ID
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl();
});

abstract class GoalRepository {
  Future<List<GoalModel>> getGoals();
  Future<void> saveGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
  Stream<List<GoalModel>>? watchGoals();
}

class GoalRepositoryImpl implements GoalRepository {
  final List<GoalModel> _memoryStore = [];

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
  Stream<List<GoalModel>>? watchGoals() {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty || _firestore == null) return null;

    try {
      return _firestore!
          .collection('users')
          .doc(uid)
          .collection('goals')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => GoalModel.fromMap(doc.data()))
                .toList();
          });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<GoalModel>> getGoals() async {
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('goals')
            .get();

        final List<GoalModel> goals = [];
        for (var doc in snapshot.docs) {
          goals.add(GoalModel.fromMap(doc.data()));
        }
        return goals;
      } catch (_) {}
    }

    return List<GoalModel>.from(_memoryStore);
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    _memoryStore.removeWhere((g) => g.id == goal.id);
    _memoryStore.add(goal);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('goals')
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
            .collection('goals')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }
}
