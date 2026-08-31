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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../models/budget_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl();
});

abstract class BudgetRepository {
  Future<List<BudgetModel>> getBudgets();
  Future<void> saveBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);
}

class BudgetRepositoryImpl implements BudgetRepository {
  @override
  Future<List<BudgetModel>> getBudgets() async {
    final box = HiveService.budgetBox;
    if (box.isNotEmpty) {
      final List<BudgetModel> budgets = [];
      for (var item in box.values) {
        if (item is Map) {
          budgets.add(BudgetModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      return budgets;
    }
    return [];
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    final box = HiveService.budgetBox;
    await box.put(budget.id, budget.toMap());
  }

  @override
  Future<void> deleteBudget(String id) async {
    final box = HiveService.budgetBox;
    await box.delete(id);
  }
}
