import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/FinancialGoal.dart';

class GoalsFirestoreService{
  final firestore = FirebaseFirestore.instance;
  Stream<List<Map<String, dynamic>>> getGoalsOfUser(String uid) {
    return firestore
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final goalsData = doc.data();
        return goalsData;
      }).toList();
    });
  }

  Future<void> addGoals(String uid, FinancialGoal goal) async {
    await firestore
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .doc(goal.id)
        .set({
      "id": goal.id,
      "title": goal.title,
      "deadline": goal.deadline,
      "description": goal.description,
      "amount": goal.targetAmount
    });
  }

  Future<void> updateGoal(String uid, FinancialGoal goal) async {
    await firestore
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .doc(goal.id)
        .update({
      "id": goal.id,
      "title": goal.title,
      "deadline": goal.deadline,
      "description": goal.description,
      "amount": goal.targetAmount
    });
  }

  Future<void> deleteGoal(String uid, FinancialGoal goal) async {
    await firestore
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .doc(goal.id)
        .delete();
  }
}