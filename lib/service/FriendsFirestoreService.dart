import 'package:cloud_firestore/cloud_firestore.dart';

class Friendsfirestoreservice {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// STREAM with optional query filters
  Stream<List<Map<String, dynamic>>> getUsers({
    String? email,
    String? name,
  }) {
    Query query = _firestore.collection("Users");

    /// Filter by email (exact match)
    if (email != null && email.isNotEmpty) {
      query = query.where("email", isEqualTo: email);
    }

    /// Filter by name (exact match)
    if (name != null && name.isNotEmpty) {
      query = query.where("username", isEqualTo: name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          "uid": doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  CollectionReference get _ref => _firestore.collection("Friendships");

  /// SEND FRIEND REQUEST
  Future<void> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    await _ref.add({
      "requesterId": requesterId,
      "receiverId": receiverId,
      "status": "pending",
      "createdAt": DateTime.now().toIso8601String(),
    });
  }

  /// ACCEPT REQUEST
  Future<void> acceptRequest(String friendshipId) async {
    await _ref.doc(friendshipId).update({
      "status": "accepted",
    });
  }

  /// REJECT REQUEST
  Future<void> rejectRequest(String friendshipId) async {
    await _ref.doc(friendshipId).update({
      "status": "rejected",
    });
  }

  /// GET FRIENDS (accepted only)
  Stream<List<Map<String, dynamic>>> getFriends(String userId) {
    return _ref
        .where("status", isEqualTo: "accepted")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .where((friendship) {
        final requesterId = friendship["requesterId"]?.toString();
        final receiverId = friendship["receiverId"]?.toString();
        return requesterId == userId || receiverId == userId;
      }).toList();
    });
  }

  /// GET INCOMING REQUESTS
  Stream<List<Map<String, dynamic>>> getIncomingRequests(String userId) {
    return _ref
        .where("receiverId", isEqualTo: userId)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map((a) => a.docs
            .map((d) => {"id": d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  /// GET OUTGOING REQUESTS (pending only)
  Stream<List<Map<String, dynamic>>> getOutgoingRequests(String userId) {
    return _ref
        .where("requesterId", isEqualTo: userId)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  "id": doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList());
  }

  /// REMOVE FRIEND
  Future<void> removeFriend(String friendshipId) async {
    await _ref.doc(friendshipId).delete();
  }
}
