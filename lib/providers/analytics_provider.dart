import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/transaction_model.dart';
import 'transaction_provider.dart';
import 'package:intl/intl.dart';

// Filter state
class TransactionFilter {
  DateTime? startDate;
  DateTime? endDate;
  String? type; // 'income' or 'expense'
  String? category;

  TransactionFilter({this.startDate, this.endDate, this.type, this.category});
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter());

// Filtered transactions
final filteredTransactionsProvider =
    Provider<List<TransactionModel>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final filter = ref.watch(transactionFilterProvider);

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      return transactions.where((t) {
        if (filter.startDate != null &&
            t.date.isBefore(filter.startDate!)) {
          return false;
        }
        if (filter.endDate != null &&
            t.date.isAfter(filter.endDate!)) {
          return false;
        }
        if (filter.type != null && t.type != filter.type) return false;
        if (filter.category != null && t.category != filter.category) {
          return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// Monthly totals for BarChart
final monthlyTotalsProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  Map<String, double> monthlyTotals = {};

  for (var t in transactions) {
    final key = DateFormat('yyyy-MM').format(t.date);
    monthlyTotals[key] = (monthlyTotals[key] ?? 0) + t.amount;
  }

  return monthlyTotals;
});

// Category totals for PieChart
final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  Map<String, double> categoryTotals = {};

  for (var t in transactions) {
    categoryTotals[t.category] =
        (categoryTotals[t.category] ?? 0) + t.amount;
  }

  return categoryTotals;
});
