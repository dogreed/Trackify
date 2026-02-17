import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import 'add_transaction_screen.dart';

const String currencySymbol = '\$'; // Change currency here

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

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
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.blue[600],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Income & Expense Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: const Color.fromARGB(255, 8, 149, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Income',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: const Color.fromARGB(255, 254, 83, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Expense',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(
                                '$currencySymbol${totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
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
                            return Dismissible(
                              key: Key(t.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) async {
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
                              child: Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
                                      t.type == 'income'
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text('${t.category}'),
                                  subtitle: Text(
                                      '${t.note.isNotEmpty ? t.note + ' - ' : ''}${t.date.toLocal()}'),
                                  trailing: Text(
                                    '$currencySymbol${t.amount.toStringAsFixed(2)}',
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
