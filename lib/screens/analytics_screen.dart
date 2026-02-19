import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackify/providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  // Predefined colors for standard categories
  static const Map<String, Color> predefinedColors = {
    'Food': Colors.red,
    'Transport': Colors.blue,
    'Shopping': Colors.orange,
    'Bills': Colors.purple,
  };

  Color getCategoryColor(String category) {
    if (predefinedColors.containsKey(category)) {
      return predefinedColors[category]!;
    } else {
      // Random color for custom "Other" categories
      final random = Random(category.hashCode);
      return Color.fromARGB(
        255,
        100 + random.nextInt(156),
        100 + random.nextInt(156),
        100 + random.nextInt(156),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);

    // Group transactions by month for table
    Map<String, Map<String, double>> monthlyData = {};
    for (var t in filteredTransactions) {
      final monthKey = DateFormat('yyyy-MM').format(t.date);
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'income': 0, 'expense': 0};
      }
      monthlyData[monthKey]![t.type] =
          monthlyData[monthKey]![t.type]! + t.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) =>
              Text('Analytics - ${user?.displayName ?? user?.email ?? 'User'}'),
          loading: () => const Text('Analytics'),
          error: (_, __) => const Text('Analytics'),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Breakdown Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Category Breakdown',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: categoryTotals.isEmpty
                          ? const Center(child: Text('No transactions'))
                          : _CategoryPieChart(categoryTotals: categoryTotals),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: (() {
                        final entries = categoryTotals.entries
                            .where((e) => e.value > 0)
                            .toList();
                        entries.sort((a, b) => b.value.compareTo(a.value));
                        final total = entries.fold<double>(
                            0, (sum, e) => sum + e.value);
                        return entries
                            .map((e) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: getCategoryColor(e.key),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${e.key}: ${e.value.toStringAsFixed(2)} NRS  (${(e.value / total * 100).toStringAsFixed(1)}%)',
                                    ),
                                  ],
                                ))
                            .toList();
                      })(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Monthly Totals Table
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Monthly Totals',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    monthlyData.isEmpty
                        ? const Center(child: Text('No transactions'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Month')),
                                DataColumn(label: Text('Income')),
                                DataColumn(label: Text('Expense')),
                                DataColumn(label: Text('Balance')),
                              ],
                              rows: monthlyData.entries.map((entry) {
                                final month = entry.key;
                                final income = entry.value['income'] ?? 0.0;
                                final expense = entry.value['expense'] ?? 0.0;
                                final balance = income - expense;

                                return DataRow(cells: [
                                  DataCell(Text(month)),
                                  DataCell(Text(
                                    '${income.toStringAsFixed(2)} रु',
                                    style: const TextStyle(color: Colors.green),
                                  )),
                                  DataCell(Text(
                                    '${expense.toStringAsFixed(2)} रु',
                                    style: const TextStyle(color: Colors.red),
                                  )),
                                  DataCell(Text(
                                    '${balance.toStringAsFixed(2)} \$',
                                    style: TextStyle(
                                      color: balance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filters Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filters',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: filter.startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              ref
                                  .read(transactionFilterProvider.notifier)
                                  .update((state) => TransactionFilter(
                                        startDate: picked,
                                        endDate: state.endDate,
                                        type: state.type,
                                        category: state.category,
                                      ));
                            }
                          },
                          child: const Text('Start Date'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: filter.endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              ref
                                  .read(transactionFilterProvider.notifier)
                                  .update((state) => TransactionFilter(
                                        startDate: state.startDate,
                                        endDate: picked,
                                        type: state.type,
                                        category: state.category,
                                      ));
                            }
                          },
                          child: const Text('End Date'),
                        ),
                        DropdownButton<String>(
                          value: filter.type,
                          hint: const Text('Type'),
                          items: const [
                            DropdownMenuItem(
                                value: 'income', child: Text('Income')),
                            DropdownMenuItem(
                                value: 'expense', child: Text('Expense')),
                          ],
                          onChanged: (val) {
                            ref
                                .read(transactionFilterProvider.notifier)
                                .update((state) => TransactionFilter(
                                      startDate: state.startDate,
                                      endDate: state.endDate,
                                      type: val,
                                      category: state.category,
                                    ));
                          },
                        ),
                        DropdownButton<String>(
                          value: filter.category,
                          hint: const Text('Category'),
                          items: categoryTotals.keys
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            ref
                                .read(transactionFilterProvider.notifier)
                                .update((state) => TransactionFilter(
                                      startDate: state.startDate,
                                      endDate: state.endDate,
                                      type: state.type,
                                      category: val,
                                    ));
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(transactionFilterProvider.notifier).state =
                                TransactionFilter();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Interactive Pie Chart Widget ---
class _CategoryPieChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  const _CategoryPieChart({required this.categoryTotals});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.categoryTotals.values.fold(0.0, (a, b) => a + b);

    final entries = widget.categoryTotals.entries
        .where((e) => e.value > 0)
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return PieChart(
      PieChartData(
        sections: entries
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final e = entry.value;
              return PieChartSectionData(
                value: e.value,
                color: AnalyticsScreen().getCategoryColor(e.key),
                radius: touchedIndex == index ? 70 : 60,
                title: '${(e.value / total * 100).toStringAsFixed(1)}%',
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            })
            .toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        centerSpaceColor: Colors.white,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.touchedSection == null) {
                touchedIndex = null;
                return;
              }
              touchedIndex = response.touchedSection!.touchedSectionIndex;
            });
          },
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
    );
  }
}
