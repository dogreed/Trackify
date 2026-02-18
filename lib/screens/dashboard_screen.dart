import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import 'add_transaction_screen.dart';

const String currencySymbol = 'NRS '; // Change currency here

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Category icons map
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Other': Icons.category,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: transactionsAsync.when(
          data: (transactions) {
            double totalIncome = transactions
                .where((t) => t.type == 'income')
                .fold(0, (sum, t) => sum + t.amount);
            double totalExpense = transactions
                .where((t) => t.type == 'expense')
                .fold(0, (sum, t) => sum + t.amount);
            double balance = totalIncome - totalExpense;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Balance Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue[700]!, width: 2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(balance),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Income & Expense Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Income',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormat.format(totalIncome),
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Expense',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormat.format(totalExpense),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Transactions
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(child: Text('No transactions yet'))
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final t = transactions[index];
                            final icon =
                                categoryIcons[t.category] ?? Icons.category;

                            return Dismissible(
                              key: Key(t.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) async {
                                HapticFeedback.lightImpact();
                                await ref
                                    .read(transactionServiceProvider)
                                    .deleteTransaction(t.id);
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: t.type == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                          transaction: t,
                                        ),
                                      ),
                                    );
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: t.type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(t.category),
                                  subtitle: Text(
                                      '${t.note.isNotEmpty ? t.note + ' - ' : ''}${DateFormat('dd MMM yyyy').format(t.date)}'),
                                  trailing: Text(
                                    currencyFormat.format(t.amount),
                                    style: TextStyle(
                                        color: t.type == 'income'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
