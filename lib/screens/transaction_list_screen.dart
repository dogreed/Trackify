import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionsList extends ConsumerWidget {
  final List<TransactionModel> transactions;

  const TransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions yet'));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];

        return Dismissible(
          key: Key(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await ref.read(transactionServiceProvider).deleteTransaction(t.id);
          },
          child: ListTile(
            title: Text('${t.category} - \$${t.amount.toStringAsFixed(2)}'),
            subtitle: Text('${t.note} - ${t.date.toLocal()}'),
          ),
        );
      },
    );
  }
}
