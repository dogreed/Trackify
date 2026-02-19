import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final CollectionReference _transactionsRef =
      FirebaseFirestore.instance.collection('transactions');

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).set(transaction.toMap());
  }

  // Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  // Stream all transactions for the current user
  Stream<List<TransactionModel>> getTransactions() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _transactionsRef
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
