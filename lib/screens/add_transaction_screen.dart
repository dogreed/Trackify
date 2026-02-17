import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction; // Nullable for edit

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'income';
  double? _amount;
  String? _category;
  String? _note;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Other'
  ];

  bool _isOtherCategory = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _amount = widget.transaction!.amount;
      _category = widget.transaction!.category;
      _note = widget.transaction!.note;
      _isOtherCategory = !_categories.contains(_category);
      if (_isOtherCategory) _categories.add(_category!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Type Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == 'income',
                    selectedColor: Colors.greenAccent,
                    onSelected: (selected) => setState(() => _type = 'income'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == 'expense',
                    selectedColor: Colors.redAccent,
                    onSelected: (selected) => setState(() => _type = 'expense'),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Amount
              TextFormField(
                initialValue: _amount?.toString(),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.balance_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
                onSaved: (val) => _amount = double.tryParse(val!),
              ),
              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _categories.contains(_category) ? _category : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _category = val;
                    _isOtherCategory = val == 'Other';
                  });
                },
                validator: (val) {
                  if (_category == null || _category!.isEmpty)
                    return 'Select category';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Custom Other Category
              if (_isOtherCategory)
                TextFormField(
                  initialValue: _isOtherCategory ? _category : '',
                  decoration: InputDecoration(
                    labelText: 'Enter custom category',
                    prefixIcon: const Icon(Icons.edit),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter category';
                    return null;
                  },
                  onSaved: (val) => _category = val,
                ),
              if (_isOtherCategory) const SizedBox(height: 20),

              // Note
              TextFormField(
                initialValue: _note,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (val) => _note = val,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(widget.transaction != null ? 'Update Transaction' : 'Save Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final id = widget.transaction?.id ?? const Uuid().v4();

                      final transaction = TransactionModel(
                        id: id,
                        uid: FirebaseAuth.instance.currentUser!.uid,
                        type: _type,
                        amount: _amount!,
                        category: _category!,
                        note: _note ?? '',
                        date: DateTime.now(),
                      );

                      await ref
                          .read(transactionServiceProvider)
                          .addTransaction(transaction);

                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
