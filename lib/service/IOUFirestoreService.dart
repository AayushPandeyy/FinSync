import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';

class Ioufirestoreservice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TransactionFirestoreService transactionFirestoreService = TransactionFirestoreService();

  
}
