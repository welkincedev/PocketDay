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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
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
  @override
  Future<List<SavingsGoalModel>> getGoals() async {
    final box = HiveService.goalsBox;
    if (box.isNotEmpty) {
      final List<SavingsGoalModel> goals = [];
      for (var item in box.values) {
        if (item is Map) {
          goals.add(SavingsGoalModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      return goals;
    }
    return [];
  }

  @override
  Future<void> saveGoal(SavingsGoalModel goal) async {
    final box = HiveService.goalsBox;
    await box.put(goal.id, goal.toMap());
  }

  @override
  Future<void> deleteGoal(String id) async {
    final box = HiveService.goalsBox;
    await box.delete(id);
  }
}
