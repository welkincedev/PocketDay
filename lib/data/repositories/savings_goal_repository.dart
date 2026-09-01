// ============================================================
// PocketDay — SavingsGoalRepositoryImpl
// ============================================================
//
// Purpose:
// Repository managing dedicated savings goal persistence, cache-first reads, and optimistic offline writes.
//
// Responsibilities:
// - Read explicit SavingsGoalModel documents from local Firestore cache first for instant UI rendering.
// - Perform optimistic local updates and dispatch Firestore document writes in the background.
// - Maintain in-memory store for unit test environments.
//
// Data Flow:
// AddSavingsGoalBottomSheet / AddSavingsBottomSheet → SavingsGoalsProvider → SavingsGoalRepositoryImpl → Firestore Cache / Cloud Storage
//
// Firestore Structure:
// Path: users/{uid}/savings_goals/{goalId}
//
// Important Rules:
// - UID Isolation: Requires active user authentication (`FirebaseAuth.instance.currentUser?.uid`).
// - Cache-First Read: getGoals() reads local cache first for instant rendering.
// - Optimistic Writes: saveGoal() and deleteGoal() update local state and dispatch background Firestore writes (`unawaited`).
//
// Main Operations:
// - getGoals() — Returns cached savings goals immediately, with fallback for fresh installs.
// - saveGoal() — Optimistically updates savings goal and dispatches background Firestore write.
// - deleteGoal() — Optimistically removes savings goal and dispatches background Firestore delete.
//
// Dependencies / Collaborators:
// - FirebaseFirestore — Document storage engine for savings goal records.
// - FirebaseAuth — Provides active user UID context.
// - SavingsGoalModel — Entity model representing explicit savings targets.
//
// ============================================================

import 'dart:async';
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
        QuerySnapshot<Map<String, dynamic>> snapshot;
        try {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('savings_goals')
              .get(const GetOptions(source: Source.cache));
          
          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore!
                .collection('users')
                .doc(uid)
                .collection('savings_goals')
                .get()
                .timeout(const Duration(seconds: 3));
          }
        } catch (_) {
          snapshot = await _firestore!
              .collection('users')
              .doc(uid)
              .collection('savings_goals')
              .get()
              .timeout(const Duration(seconds: 3));
        }

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
      unawaited(_firestore!
          .collection('users')
          .doc(uid)
          .collection('savings_goals')
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
          .collection('savings_goals')
          .doc(id)
          .delete()
          .catchError((_) {}));
    }
  }
}
