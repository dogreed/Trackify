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
