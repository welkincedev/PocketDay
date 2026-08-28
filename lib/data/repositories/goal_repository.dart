import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../models/goal_model.dart';

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
