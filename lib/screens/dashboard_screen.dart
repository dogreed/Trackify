import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';

const String currencySymbol = 'NRS ';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Other': Icons.category,
  };

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final currentTheme = ref.read(themeProvider);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Theme",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              RadioListTile(
                title: const Text("Light"),
                value: ThemeMode.light,
                groupValue: currentTheme,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setTheme(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text("Dark"),
                value: ThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setTheme(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text("System"),
                value: ThemeMode.system,
                groupValue: currentTheme,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setTheme(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);
    final userAsync = ref.watch(authStateProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(user?.displayName ?? user?.email ?? 'Dashboard'),
          loading: () => const Text('Dashboard'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(1000, 80, 10, 0),
                items: const [
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(Icons.brightness_6),
                        SizedBox(width: 8),
                        Text('Theme'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'logout') {
                  ref.read(authServiceProvider).signOut();
                }
                if (value == 'theme') {
                  _showThemeSelector(context, ref);
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                // BALANCE CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Balance'),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(balance),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ANALYTICS BUTTON
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'View Analytics',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // INCOME & EXPENSE
                Row(
                  children: [
                    Expanded(
                      child: _financeCard(
                        context,
                        'Income',
                        totalIncome,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _financeCard(
                        context,
                        'Expense',
                        totalExpense,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Transaction'),
                                    content: const Text(
                                      'Are you sure you want to delete this transaction?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) async {
                                HapticFeedback.lightImpact();
                                await ref
                                    .read(transactionServiceProvider)
                                    .deleteTransaction(t.id);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: t.type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                    width: 1.5,
                                  ),
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
                                    child: Icon(icon, color: Colors.white),
                                  ),
                                  title: Text(t.category),
                                  subtitle: Text(
                                    '${t.note.isNotEmpty ? '${t.note} - ' : ''}${DateFormat('dd MMM yyyy').format(t.date)}',
                                  ),
                                  trailing: Text(
                                    currencyFormat.format(t.amount),
                                    style: TextStyle(
                                      color: t.type == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  Widget _financeCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(
            NumberFormat.currency(symbol: currencySymbol).format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
