// ============================================================
// PocketDay — GoalRepositoryImpl
// ============================================================
//
// Purpose:
// Repository managing target financial goal persistence, cache-first reads, and optimistic offline writes.
//
// Responsibilities:
// - Read target GoalModel documents from local Firestore cache first for instant UI rendering.
// - Perform optimistic local updates and dispatch Firestore document writes in the background.
// - Provide real-time Firestore snapshots stream via watchGoals().
// - Maintain in-memory store for unit test environments.
//
// Data Flow:
// CreateGoalSheet / EditGoalSheet → GoalsProvider → GoalRepositoryImpl → Firestore Cache / Cloud Storage
//
// Firestore Structure:
// Path: users/{uid}/goals/{goalId}
//
// Important Rules:
// - UID Isolation: Requires active user authentication (`FirebaseAuth.instance.currentUser?.uid`).
// - Cache-First Read: getGoals() reads local cache first for instant rendering.
// - Optimistic Writes: saveGoal() and deleteGoal() update local state and dispatch background Firestore writes (`unawaited`).
//
// Main Operations:
// - getGoals() — Returns cached goals immediately, with fallback for fresh installs.
// - saveGoal() — Optimistically updates goal and dispatches background Firestore write.
// - deleteGoal() — Optimistically removes goal and dispatches background Firestore delete.
// - watchGoals() — Returns real-time Stream<List<GoalModel>> of user target goals.
//
// Dependencies / Collaborators:
// - FirebaseFirestore — Document storage engine for goal targets.
// - FirebaseAuth — Provides active user UID context.
// - GoalModel — Entity model representing target financial goals.
//
// ============================================================

import 'dart:async';
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
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('goals')
              .get(const GetOptions(source: Source.cache));
          
          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore!
                .collection('users')
                .doc(uid)
                .collection('goals')
                .get()
                .timeout(const Duration(seconds: 3));
          }
        } catch (_) {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('goals')
              .get()
              .timeout(const Duration(seconds: 3));
        }

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
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc(goal.id)
          .set(goal.toMap(), SetOptions(merge: true))
          .catchError((_) {}));
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    _memoryStore.removeWhere((g) => g.id == id);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('goals')
          .doc(id)
          .delete()
          .catchError((_) {}));
    }
  }
}
