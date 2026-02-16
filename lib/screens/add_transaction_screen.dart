import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // for generating unique IDs
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'income'; // default type
  double? _amount;
  String? _category;
  String? _note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1️⃣ Type Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == 'income',
                    onSelected: (selected) {
                      setState(() => _type = 'income');
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == 'expense',
                    onSelected: (selected) {
                      setState(() => _type = 'expense');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2️⃣ Amount Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  return null;
                },
                onSaved: (val) => _amount = double.tryParse(val!),
              ),

              // 3️⃣ Category Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter category';
                  return null;
                },
                onSaved: (val) => _category = val,
              ),

              // 4️⃣ Note Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                onSaved: (val) => _note = val,
              ),

              const SizedBox(height: 20),

              // 5️⃣ Save Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final transaction = TransactionModel(
                      id: const Uuid().v4(), // generate unique ID
                      uid: FirebaseAuth.instance.currentUser!.uid,  //Undefined name 'FirebaseAuth'.Try correcting the name to one that is defined, or defining the name.

                      type: _type,
                      amount: _amount!,
                      category: _category!,
                      note: _note ?? '',
                      date: DateTime.now(),
                    );

                    // Save transaction using provider
                    await ref.read(transactionServiceProvider).addTransaction(transaction);

                    Navigator.pop(context); // go back after adding
                  }
                },
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
