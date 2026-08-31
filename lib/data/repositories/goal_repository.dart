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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../models/goal_model.dart';

/// Riverpod provider that exposes the [GoalRepository] implementation.
///
/// The UI and [GoalsProvider] should read goals through this provider rather
/// than accessing Hive directly, keeping persistence logic in one place.
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl();
});

abstract class GoalRepository {
  Future<List<GoalModel>> getGoals();
  Future<void> saveGoal(GoalModel goal);
  Future<void> deleteGoal(String id);
}

class GoalRepositoryImpl implements GoalRepository {
  @override
  Future<List<GoalModel>> getGoals() async {
    final box = HiveService.goalsBox;
    if (box.isNotEmpty) {
      final List<GoalModel> goals = [];
      for (var item in box.values) {
        if (item is Map) {
          goals.add(GoalModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      return goals;
    }
    return [];
  }

  @override
  Future<void> saveGoal(GoalModel goal) async {
    final box = HiveService.goalsBox;
    await box.put(goal.id, goal.toMap());
  }

  @override
  Future<void> deleteGoal(String id) async {
    final box = HiveService.goalsBox;
    await box.delete(id);
  }
}
