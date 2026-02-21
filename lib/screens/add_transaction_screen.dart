import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'dashboard_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String _type = 'income';
  double? _amount;
  String? _category;
  String? _note;
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.fastfood},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Bills', 'icon': Icons.lightbulb},
    {'name': 'Other', 'icon': Icons.category},
  ];

  bool _isOtherCategory = false;

  late AnimationController _animationController;
  late Animation<Color?> _typeColorAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _amount = widget.transaction!.amount;
      _category = widget.transaction!.category;
      _note = widget.transaction!.note;
      _selectedDate = widget.transaction!.date;

      _isOtherCategory =
          !_categories.map((c) => c['name']).contains(_category);

      if (_isOtherCategory) {
        _categories.add({'name': _category!, 'icon': Icons.edit});
      }
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _typeColorAnimation =
        ColorTween(begin: Colors.green, end: Colors.red)
            .animate(_animationController);

    if (_type == 'expense') {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchType(String type) {
    HapticFeedback.lightImpact();
    setState(() {
      _type = type;
      if (_type == 'income') {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final id = widget.transaction?.id ?? const Uuid().v4();

    final transaction = TransactionModel(
      id: id,
      uid: FirebaseAuth.instance.currentUser!.uid,
      type: _type,
      amount: _amount!,
      category: _category!,
      note: _note ?? '',
      date: _selectedDate,
    );

    if (widget.transaction != null) {
      await ref.read(transactionServiceProvider)
          .updateTransaction(transaction);
    } else {
      await ref.read(transactionServiceProvider)
          .addTransaction(transaction);
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.transaction != null
              ? 'Edit Transaction'
              : 'Add Transaction',
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _typeColorAnimation,
        builder: (context, _) {
          return Column(
            children: [

              // Top animated color bar
              Container(
                height: 6,
                width: double.infinity,
                color: _type == 'income'
                    ? Colors.green
                    : Colors.red,
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _type == 'income'
                            ? Colors.green
                            : Colors.red,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          // Type selector
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('Income'),
                                selected: _type == 'income',
                                onSelected: (_) =>
                                    _switchType('income'),
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('Expense'),
                                selected: _type == 'expense',
                                onSelected: (_) =>
                                    _switchType('expense'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Amount
                          TextFormField(
                            initialValue: _amount?.toString(),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: 'NRS ',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType:
                                TextInputType.number,
                            validator: (val) {
                              if (val == null ||
                                  val.isEmpty) {
                                return 'Enter amount';
                              }
                              if (double.tryParse(val) ==
                                  null) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                            onSaved: (val) =>
                                _amount =
                                    double.tryParse(val!),
                          ),

                          const SizedBox(height: 20),

                          // Category
                          DropdownButtonFormField<String>(
                            value: _categories.any(
                                    (c) =>
                                        c['name'] ==
                                        _category)
                                ? _category
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(
                                value: c['name']
                                    as String,
                                child: Text(
                                    c['name']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _category = val;
                                _isOtherCategory =
                                    val ==
                                        'Other';
                              });
                            },
                            validator: (_) =>
                                _category == null
                                    ? 'Select category'
                                    : null,
                          ),

                          if (_isOtherCategory) ...[
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Custom category',
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null ||
                                          val.isEmpty
                                      ? 'Enter category'
                                      : null,
                              onSaved: (val) =>
                                  _category =
                                      val,
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Note
                          TextFormField(
                            initialValue: _note,
                            decoration: InputDecoration(
                              labelText:
                                  'Note (optional)',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                            ),
                            onSaved: (val) =>
                                _note = val,
                          ),

                          const SizedBox(height: 20),

                          // Date
                          Row(
                            children: [
                              const Icon(
                                  Icons.calendar_today),
                              const SizedBox(
                                  width: 10),
                              Text(
                                '${_selectedDate.toLocal().toString().split(' ')[0]}',
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed:
                                    _pickDate,
                                child: const Text(
                                    'Select Date'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Save
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _saveTransaction,
                              child: Text(
                                widget.transaction !=
                                        null
                                    ? 'Update'
                                    : 'Save',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}