import '../models/transaction_model.dart';
import '../../core/services/hive_service.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(TransactionModel transaction);
}

class TransactionRepositoryImpl implements TransactionRepository {
  final List<TransactionModel> _mockTransactions = [
    TransactionModel(
      id: 'txn_1',
      title: 'Monthly Salary',
      amount: 65000.00,
      type: TransactionType.income,
      categoryId: 'salary',
      categoryName: 'Salary',
      date: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Direct HDFC Deposit',
    ),
    TransactionModel(
      id: 'txn_2',
      title: 'Blinkit Groceries',
      amount: 1450.00,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food & Dining',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      notes: 'Weekly groceries',
    ),
    TransactionModel(
      id: 'txn_3',
      title: 'Netflix Subscription',
      amount: 649.00,
      type: TransactionType.expense,
      categoryId: 'entertainment',
      categoryName: 'Entertainment',
      date: DateTime.now().subtract(const Duration(days: 1)),
      notes: 'Monthly Premium plan',
    ),
    TransactionModel(
      id: 'txn_4',
      title: 'Freelance UI Project',
      amount: 18500.00,
      type: TransactionType.income,
      categoryId: 'freelance',
      categoryName: 'Freelance',
      date: DateTime.now().subtract(const Duration(days: 3)),
      notes: 'Client Deposit',
    ),
    TransactionModel(
      id: 'txn_5',
      title: 'Starbucks Coffee',
      amount: 420.00,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food & Dining',
      date: DateTime.now().subtract(const Duration(hours: 1)),
      notes: 'Iced Latte',
    ),
    TransactionModel(
      id: 'txn_6',
      title: 'Uber Auto Ride',
      amount: 210.00,
      type: TransactionType.expense,
      categoryId: 'transport',
      categoryName: 'Transportation',
      date: DateTime.now().subtract(const Duration(days: 4)),
      notes: 'Metro station commute',
    ),
  ];

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final box = HiveService.transactionsBox;
    if (box.isNotEmpty) {
      final List<TransactionModel> txns = [];
      for (var item in box.values) {
        if (item is Map) {
          txns.add(TransactionModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      return txns..sort((a, b) => b.date.compareTo(a.date));
    }

    // Seed Hive with mock data if empty
    for (var txn in _mockTransactions) {
      await box.put(txn.id, txn.toMap());
    }
    return List.from(_mockTransactions)..sort((a, b) => b.date.compareTo(a.date));
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
