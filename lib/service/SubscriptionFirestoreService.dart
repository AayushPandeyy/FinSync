import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/Subscription.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';

class SubscriptionFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //adding subscription to firestore
  Future<void> addSubscription(String uid, Subscription subscription) async {
    await firestore
        .collection('Subscriptions')
        .doc(uid)
        .collection("subscription")
        .doc(subscription.id)
        .set({
      "name": subscription.name,
      "amount": subscription.amount,
      "billingCycle": subscription.billingCycle,
      "nextBillingDate": subscription.nextBillingDate,
      "category": subscription.category,
      "isActive": subscription.isActive,
    });
  }

  //fetching subscriptions from firestore
  Stream<List<Subscription>> getSubscriptions(String uid) async* {
    final cacheKey = 'subscriptions_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached
          .map((data) => Subscription(
                id: data['id'],
                name: data['name'],
                amount: (data['amount'] as num).toDouble(),
                billingCycle: data['billingCycle'],
                nextBillingDate:
                    (data['nextBillingDate'] as Timestamp).toDate(),
                category: data['category'],
                isActive: data['isActive'] ?? true,
              ))
          .toList(growable: false);
    }

    yield* firestore
        .collection('Subscriptions')
        .doc(uid)
        .collection('subscription')
        .snapshots()
        .asyncMap((snapshot) async {
      final docs = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList(growable: false);

      await OfflineCacheService.saveList(cacheKey, docs);

      return docs
          .map((data) => Subscription(
                id: data['id'],
                name: data['name'],
                amount: (data['amount'] as num).toDouble(),
                billingCycle: data['billingCycle'],
                nextBillingDate:
                    (data['nextBillingDate'] as Timestamp).toDate(),
                category: data['category'],
                isActive: data['isActive'] ?? true,
              ))
          .toList(growable: false);
    });
  }

  void updateSubscription(String uid, Subscription subscription) async {
    await firestore
        .collection('Subscriptions')
        .doc(uid)
        .collection("subscription")
        .doc(subscription.id)
        .update({
      "name": subscription.name,
      "amount": subscription.amount,
      "billingCycle": subscription.billingCycle,
      "nextBillingDate": subscription.nextBillingDate,
      "category": subscription.category,
      "isActive": subscription.isActive,
    });
  }

  void deleteSubscription(String uid, String subscriptionId) async {
    await firestore
        .collection('Subscriptions')
        .doc(uid)
        .collection("subscription")
        .doc(subscriptionId)
        .delete();
  }
}
