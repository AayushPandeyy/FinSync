import 'package:finance_tracker/enums/friends/FriendStatus.dart';

class Friendship {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendStatus status;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "requesterId": requesterId,
      "receiverId": receiverId,
      "status": status.name,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory Friendship.fromMap(String id, Map<String, dynamic> map) {
    return Friendship(
      id: id,
      requesterId: map["requesterId"],
      receiverId: map["receiverId"],
      status: FriendStatus.values.byName(map["status"]),
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }
}