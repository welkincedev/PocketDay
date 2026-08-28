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
