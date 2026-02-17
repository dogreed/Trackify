import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

// 1️⃣ Create a Provider for TransactionService
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

// 2️⃣ Create a StreamProvider to listen to all transactions
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return service.getTransactions(); // gets stream of user transactions
});


final transactionSummaryProvider = Provider((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  return transactionsAsync.when(
    data: (transactions) {
      double totalIncome = 0;
      double totalExpense = 0;

      for (var t in transactions) {
        if (t.type == 'income') {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    },
    loading: () => {
      'income': 0.0,
      'expense': 0.0,
      'balance': 0.0,
    },
    error: (_, __) => {
      'income': 0.0,
      'expense': 0.0,
      'balance': 0.0,
    },
  );
});
