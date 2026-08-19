import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/family/FamilyRole.dart';

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

DateTime _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

/// A shared household workspace. Lives at `Families/{id}`.
class Family {
  final String id;
  final String name;

  /// Short human-typable invite code (e.g. `7KF2QA`).
  final String code;

  final String createdBy;
  final DateTime createdAt;

  /// UIDs of everyone who may read/write the family's data. Kept as an array so
  /// "which families am I in" is a single `array-contains` query.
  final List<String> memberIds;

  /// Subset of [memberIds] allowed to manage members.
  final List<String> adminIds;

  /// Running totals of every member's family transactions combined.
  final double income;
  final double expense;
  final double totalBalance;

  Family({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
    required this.adminIds,
    this.income = 0,
    this.expense = 0,
    this.totalBalance = 0,
  });

  bool isAdmin(String uid) => adminIds.contains(uid);

  factory Family.fromMap(String id, Map<String, dynamic> map) {
    return Family(
      id: id,
      name: (map['name'] ?? 'My Family').toString(),
      code: (map['code'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt: _asDate(map['createdAt']),
      memberIds: List<String>.from(map['memberIds'] ?? const []),
      adminIds: List<String>.from(map['adminIds'] ?? const []),
      income: _asDouble(map['income']),
      expense: _asDouble(map['expense']),
      totalBalance: _asDouble(map['totalBalance']),
    );
  }
}

/// A person inside a family. Lives at `Families/{familyId}/members/{uid}`.
class FamilyMember {
  final String uid;
  final String username;
  final String email;
  final FamilyRole role;

  /// Free-text relationship label, e.g. "Father", "Elder Son".
  final String designation;

  final DateTime joinedAt;

  /// This member's own contribution to the family pot.
  final double income;
  final double expense;

  FamilyMember({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    required this.designation,
    required this.joinedAt,
    this.income = 0,
    this.expense = 0,
  });

  bool get isAdmin => role == FamilyRole.admin;

  factory FamilyMember.fromMap(String uid, Map<String, dynamic> map) {
    return FamilyMember(
      uid: (map['uid'] ?? uid).toString(),
      username: (map['username'] ?? 'Member').toString(),
      email: (map['email'] ?? '').toString(),
      role: FamilyRoleX.fromValue(map['role']?.toString()),
      designation: (map['designation'] ?? 'Member').toString(),
      joinedAt: _asDate(map['joinedAt']),
      income: _asDouble(map['income']),
      expense: _asDouble(map['expense']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'role': role.value,
      'designation': designation,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'income': income,
      'expense': expense,
    };
  }
}

/// A pending "let me in" request. Lives at
/// `Families/{familyId}/joinRequests/{uid}` — one open request per person.
class FamilyJoinRequest {
  final String uid;
  final String username;
  final String email;
  final String designation;
  final JoinRequestStatus status;
  final DateTime requestedAt;

  /// Denormalised onto the request so a cross-family lookup (e.g. "which of my
  /// requests is still open?") does not need the parent document.
  final String familyId;
  final String familyName;

  FamilyJoinRequest({
    required this.uid,
    required this.username,
    required this.email,
    required this.designation,
    required this.status,
    required this.requestedAt,
    this.familyId = '',
    this.familyName = '',
  });

  factory FamilyJoinRequest.fromMap(String uid, Map<String, dynamic> map) {
    return FamilyJoinRequest(
      uid: (map['uid'] ?? uid).toString(),
      username: (map['username'] ?? 'User').toString(),
      email: (map['email'] ?? '').toString(),
      designation: (map['designation'] ?? 'Member').toString(),
      status: JoinRequestStatusX.fromValue(map['status']?.toString()),
      requestedAt: _asDate(map['requestedAt']),
      familyId: (map['familyId'] ?? '').toString(),
      familyName: (map['familyName'] ?? '').toString(),
    );
  }
}

/// A family income/expense entry. Lives at
/// `Families/{familyId}/transactions/{id}`.
///
/// Mirrors [TransactionModel] but carries who booked it so the dashboard can
/// break the shared pot down per member.
class FamilyTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String description;
  final String category;

  /// `INCOME` or `EXPENSE`.
  final String type;

  final String createdBy;
  final String createdByName;
  final String createdByDesignation;

  FamilyTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.description,
    required this.category,
    required this.type,
    required this.createdBy,
    required this.createdByName,
    required this.createdByDesignation,
  });

  bool get isExpense => type == 'EXPENSE';

  factory FamilyTransaction.fromMap(String id, Map<String, dynamic> map) {
    return FamilyTransaction(
      id: (map['id'] ?? id).toString(),
      title: (map['title'] ?? 'Transaction').toString(),
      amount: _asDouble(map['amount']),
      date: _asDate(map['date']),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? 'Others').toString(),
      type: map['type'] == 'EXPENSE' ? 'EXPENSE' : 'INCOME',
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? 'Member').toString(),
      createdByDesignation: (map['createdByDesignation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'category': category,
      'type': type,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByDesignation': createdByDesignation,
    };
  }
}

/// A recurring family bill. Lives at `Families/{familyId}/subscriptions/{id}`.
class FamilySubscription {
  final String id;
  final String name;
  final double amount;

  /// `Monthly`, `Yearly` or `Weekly`.
  final String billingCycle;

  final DateTime nextBillingDate;
  final String category;
  final bool isActive;

  /// Which member picks up the bill.
  final String paidByUid;
  final String paidByName;

  final String createdBy;

  FamilySubscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
    required this.isActive,
    required this.paidByUid,
    required this.paidByName,
    required this.createdBy,
  });

  /// Cost normalised to a month, used for the dashboard summary.
  double get monthlyEquivalent {
    switch (billingCycle) {
      case 'Yearly':
        return amount / 12;
      case 'Weekly':
        return (amount * 52) / 12;
      default:
        return amount;
    }
  }

  factory FamilySubscription.fromMap(String id, Map<String, dynamic> map) {
    return FamilySubscription(
      id: (map['id'] ?? id).toString(),
      name: (map['name'] ?? '').toString(),
      amount: _asDouble(map['amount']),
      billingCycle: (map['billingCycle'] ?? 'Monthly').toString(),
      nextBillingDate: _asDate(map['nextBillingDate']),
      category: (map['category'] ?? 'Subscriptions').toString(),
      isActive: map['isActive'] != false,
      paidByUid: (map['paidByUid'] ?? '').toString(),
      paidByName: (map['paidByName'] ?? 'Family').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle,
      'nextBillingDate': Timestamp.fromDate(nextBillingDate),
      'category': category,
      'isActive': isActive,
      'paidByUid': paidByUid,
      'paidByName': paidByName,
      'createdBy': createdBy,
    };
  }
}
