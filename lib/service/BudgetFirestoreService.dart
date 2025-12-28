import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetFirestoreService{
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void addBudget(String uid, double amount, DateTime startDate, DateTime endDate) async {
    await firestore
        .collection('Budgets')
        .doc(uid)
        .set({
      "amount": amount,
      "startDate": Timestamp.fromDate(startDate),
      "endDate": Timestamp.fromDate(endDate),
    });
  }
}