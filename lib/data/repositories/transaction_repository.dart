// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: transaction_repository.dart
//
// Purpose:
// Abstract contract and Hive storage implementation for user financial transactions.
//
// Responsibilities:
// - Read all transactions from Hive `transactionsBox` sorted descending by date.
// - Add, update, and delete transactions by unique string ID.
//
// Data Flow:
// TransactionsNotifier → TransactionRepository → HiveService.transactionsBox
//
// Important Rules:
// - Automatic demo data seeding is disabled for production presentation cleanliness.
// - Transactions are sorted descending by `date` (newest first).
//
// Main Operations:
// - getTransactions(): Read sorted user transactions from Hive
// - addTransaction(txn): Persist new transaction entity
// - updateTransaction(txn): Update existing transaction by ID
// - deleteTransaction(id): Delete transaction entry from Hive
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../../core/services/hive_service.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(TransactionModel transaction);
}

class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<TransactionModel>> getTransactions() async {
    final box = HiveService.transactionsBox;
    final List<TransactionModel> txns = [];
    for (var item in box.values) {
      if (item is Map) {
        txns.add(TransactionModel.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    return txns..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await HiveService.transactionsBox.put(transaction.id, transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await HiveService.transactionsBox.delete(id);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await HiveService.transactionsBox.put(transaction.id, transaction.toMap());
  }
}
