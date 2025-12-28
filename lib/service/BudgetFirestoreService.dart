import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/BudgetType.dart';
import 'package:finance_tracker/models/Category.dart';
import 'package:uuid/v6.dart';

class BudgetFirestoreService{
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, DateTime> _getStartAndEndDate(BudgetType type) {
  final now = DateTime.now();

  late DateTime startDate;
  late DateTime endDate;

  switch (type) {
    case BudgetType.MONTHLY:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));
      break;

    case BudgetType.WEEKLY:
      startDate = now.subtract(Duration(days: now.weekday - 1)); // Monday
      endDate = startDate.add(const Duration(days: 6)); // Sunday
      break;

    case BudgetType.DAILY:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate;
      break;
  }

  return {
    'startDate': startDate,
    'endDate': endDate,
  };
}


Future<void> addMonthlyWeeklyOrDailyBudget(
  String uid,
  double amount,
  BudgetType type,
) async {
  final dates = _getStartAndEndDate(type);
  final budgetId = const UuidV6().generate();

  await firestore
      .collection('Budgets')
      .doc(uid)
      .collection('budgets')
      .doc(budgetId)
      .set({
        'budgetId': budgetId,
        'type': type.name,
        'amount': amount,
        'startDate': Timestamp.fromDate(dates['startDate']!),
        'endDate': Timestamp.fromDate(dates['endDate']!),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}


  // void addCategoryBudget(String uid, Category category, double amount) async {
  //   await firestore
  //       .collection('Budgets')
  //       .doc(uid)
  //       .collection('CategoryBudgets')
  //       .doc(category.name)
  //       .set({
  //     "category": category.name,
  //     "amount": amount,
  //   });
  // }

  Future<void> editBudget(
    String uid,
  String budgetId,
  double amount,
  BudgetType type,
) async {
  final dates = _getStartAndEndDate(type);

  await firestore.collection('Budgets').doc(uid).collection('budgets').doc(budgetId).update({
    'type': type.name,
    'amount': amount,
    'startDate': Timestamp.fromDate(dates['startDate']!),
    'endDate': Timestamp.fromDate(dates['endDate']!),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


  // Stream<List<Map<String, dynamic>>> getCategoryBudgets(String uid) {
  //   return firestore
  //       .collection('Budgets')
  //       .doc(uid)
  //       .collection('CategoryBudgets')
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  // }

Stream<List<Map<String, dynamic>>> getBudget(String uid) {
  return firestore
      .collection('Budgets')
      .doc(uid)
      .collection('budgets')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data())
            .toList();
      });
}



}