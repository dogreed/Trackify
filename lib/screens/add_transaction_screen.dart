import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart'; // for theme
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
        vsync: this, duration: const Duration(milliseconds: 250));
    _typeColorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(_animationController);

    if (_type == 'expense') _animationController.forward();
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

  Future<void> _pickDate(BuildContext context) async {
    final themeMode = ref.watch(themeProvider);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: themeMode == ThemeMode.dark
                ? const ColorScheme.dark(
                    primary: Colors.blue,
                    surface: Colors.grey,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.blue,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
            dialogBackgroundColor:
                themeMode == ThemeMode.dark ? Colors.grey[900] : Colors.white,
          ),
          child: child!,
        );
      },
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
      await ref.read(transactionServiceProvider).updateTransaction(transaction);
    } else {
      await ref.read(transactionServiceProvider).addTransaction(transaction);
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
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final surfaceColor = isDark ? Colors.grey[850]! : Colors.white;
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white70 : Colors.black45;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(widget.transaction != null
            ? 'Edit Transaction'
            : 'Add Transaction'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _typeColorAnimation,
          builder: (context, _) {
            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _type == 'income' ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Type selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text('Income', style: TextStyle(color: textColor)),
                            selected: _type == 'income',
                            selectedColor: Colors.greenAccent.withOpacity(0.3),
                            onSelected: (_) => _switchType('income'),
                            backgroundColor: cardColor,
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Text('Expense', style: TextStyle(color: textColor)),
                            selected: _type == 'expense',
                            selectedColor: Colors.redAccent.withOpacity(0.3),
                            onSelected: (_) => _switchType('expense'),
                            backgroundColor: cardColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Amount field
                      TextFormField(
                        initialValue: _amount?.toString(),
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(color: hintColor),
                          prefixIcon:
                              Icon(Icons.currency_exchange, color: hintColor),
                          prefixText: 'NRS ',
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
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

                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _categories.any((c) => c['name'] == _category)
                            ? _category
                            : null,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(Icons.category, color: hintColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(
                            value: c['name'] as String,
                            child: Row(
                              children: [
                                Icon(c['icon'], size: 20, color: textColor),
                                const SizedBox(width: 8),
                                Text(c['name'], style: TextStyle(color: textColor)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _category = val;
                            _isOtherCategory = val == 'Other';
                          });
                        },
                        validator: (val) =>
                            (_category == null || _category!.isEmpty)
                                ? 'Select category'
                                : null,
                      ),
                      const SizedBox(height: 20),

                      // Custom other category
                      if (_isOtherCategory)
                        TextFormField(
                          initialValue: _isOtherCategory ? _category : '',
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Enter custom category',
                            labelStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.edit, color: hintColor),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                          validator: (val) =>
                              (val == null || val.isEmpty) ? 'Enter category' : null,
                          onSaved: (val) => _category = val,
                        ),
                      if (_isOtherCategory) const SizedBox(height: 20),

                      // Note
                      TextFormField(
                        initialValue: _note,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          labelStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(Icons.note, color: hintColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        onSaved: (val) => _note = val,
                      ),
                      const SizedBox(height: 20),

                      // Date picker
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: hintColor),
                          const SizedBox(width: 10),
                          Text(
                            'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(color: textColor),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent),
                            onPressed: () => _pickDate(context),
                            child: const Text('Select Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(widget.transaction != null
                              ? 'Update Transaction'
                              : 'Save Transaction'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent[700],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _saveTransaction,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}