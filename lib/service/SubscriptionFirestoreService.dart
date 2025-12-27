import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/Subscription.dart';

class SubscriptionFirestoreService{
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //adding subscription to firestore
  Future<void> addSubscription(String uid, Subscription subscription) async {
    await firestore
        .collection('Subscriptions')
        .doc(uid)
        .collection("subscription").doc(subscription.id)
        .set({
      "name": subscription.name,
      "amount": subscription.amount,
      "billingCycle": subscription.billingCycle,
      "nextBillingDate": subscription.nextBillingDate,
      "category": subscription.category
    });
  }

  //fetching subscriptions from firestore
  Stream<List<Subscription>> getSubscriptions(String uid) {
    return firestore
        .collection('Subscriptions')
        .doc(uid)
        .collection('subscription')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Subscription(
                id: doc.id,
                name: data['name'],
                amount: (data['amount'] as num).toDouble(),
                billingCycle: data['billingCycle'],
                nextBillingDate: (data['nextBillingDate'] as Timestamp).toDate(),
                category: data['category'],
              );
            }).toList());
  }
}