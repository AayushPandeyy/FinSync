import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';

class GoalsFirestoreService {
  final firestore = FirebaseFirestore.instance;
  Stream<List<Map<String, dynamic>>> getGoalsOfUser(String uid) async* {
    final cacheKey = 'goals_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached;
    }

    yield* firestore
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .snapshots()
        .asyncMap((snapshot) async {
      final goalsData =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, goalsData);
      return goalsData;
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
