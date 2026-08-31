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

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransaction(TransactionModel transaction);
  Stream<List<TransactionModel>>? watchTransactions();
}

class TransactionRepositoryImpl implements TransactionRepository {
  final List<TransactionModel> _memoryStore = [];

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
  Stream<List<TransactionModel>>? watchTransactions() {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty || _firestore == null) return null;

    try {
      return _firestore!
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) {
              return TransactionModel.fromMap(doc.data());
            }).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final uid = _currentUid;

    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .get();

        final List<TransactionModel> txns = [];
        for (var doc in snapshot.docs) {
          txns.add(TransactionModel.fromMap(doc.data()));
        }
        txns.sort((a, b) => b.date.compareTo(a.date));
        return txns;
      } catch (e) {
        debugPrint('TransactionRepository.getTransactions error: $e');
      }
    }

    final list = List<TransactionModel>.from(_memoryStore);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await updateTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _memoryStore.removeWhere((t) => t.id == id);
    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('TransactionRepository.deleteTransaction error: $e');
      }
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    _memoryStore.removeWhere((t) => t.id == transaction.id);
    _memoryStore.add(transaction);

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _firestore != null) {
      try {
        debugPrint('🔥 [FIRESTORE TXN WRITE START] UID: $uid | TxnID: ${transaction.id}');
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toMap(), SetOptions(merge: true));
        debugPrint('✅ [FIRESTORE TXN WRITE SUCCESS] TxnID: ${transaction.id}');
      } catch (e) {
        debugPrint('❌ [FIRESTORE TXN WRITE FAILED] TxnID ${transaction.id} | Error: $e');
      }
    }
  }
}
