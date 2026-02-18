import 'package:cloud_firestore/cloud_firestore.dart'; // <-- add this

class TransactionModel {
  final String id;
  final String uid;
  final String type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date,
    };
  }

 factory TransactionModel.fromMap(Map<String, dynamic> map) {
  return TransactionModel(
    id: map['id'],
    uid: map['uid'],
    type: map['type'],
    amount: (map['amount'] as num).toDouble(),
    category: map['category'],
    note: map['note'],
    date: (map['date'] as Timestamp).toDate(), 
  );
}
}
