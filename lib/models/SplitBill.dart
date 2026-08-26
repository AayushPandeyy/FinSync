import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/models/SettlementRequest.dart';

/// Rounding tolerance used whenever two money figures are compared.
/// Amounts are stored as doubles and rounded to 2dp on every write, so a
/// balance within one paisa of its target counts as cleared.
const double kMoneyEpsilon = 0.01;

@immutable
class SplitBill {
  final String id;
  final String title;
  final double totalAmount;
  final String description;
  final DateTime date;
  final String paidBy; // UID of person who paid
  final Map<String, double> splitAmounts; // Map of UID to amount owed
  final String category;
  final List<String> participants; // List of UIDs involved

  /// UID -> amount the payer has approved as settled. Defaults to 0 for
  /// everyone, including bills written before settlement existed.
  final Map<String, double> settledAmounts;

  /// UID -> username, captured at creation so cards and tiles can name people
  /// without a lookup per participant.
  final Map<String, String> participantNames;

  /// ACTIVE until every payee's share is covered, then SETTLED.
  final String status;

  /// UID -> the one open settlement request that payee is waiting on.
  /// Denormalised from the `settlements` subcollection so that a card can show
  /// "awaiting approval" straight off the bill stream, and so the request
  /// transaction can enforce one open request per payee — Firestore
  /// transactions cannot run a subcollection query.
  final Map<String, PendingSettlement> pendingSettlements;

  const SplitBill({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.description,
    required this.date,
    required this.paidBy,
    required this.splitAmounts,
    required this.category,
    required this.participants,
    this.settledAmounts = const {},
    this.participantNames = const {},
    this.status = 'ACTIVE',
    this.pendingSettlements = const {},
  });

  // Firestore serialization
  factory SplitBill.fromMap(Map<String, dynamic> map, {String? fallbackId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    Map<String, double> parseSplitAmounts(dynamic value) {
      if (value is Map) {
        return value
            .map((key, val) => MapEntry(key.toString(), parseAmount(val)));
      }
      return {};
    }

    Map<String, String> parseNames(dynamic value) {
      if (value is Map) {
        return value.map(
            (key, val) => MapEntry(key.toString(), (val ?? '').toString()));
      }
      return {};
    }

    Map<String, PendingSettlement> parsePending(dynamic value) {
      if (value is Map) {
        final result = <String, PendingSettlement>{};
        value.forEach((key, val) {
          if (val is Map) {
            result[key.toString()] =
                PendingSettlement.fromMap(Map<String, dynamic>.from(val));
          }
        });
        return result;
      }
      return {};
    }

    List<String> parseParticipants(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    return SplitBill(
      id: (map['id'] ?? fallbackId ?? '').toString(),
      title: (map['title'] ?? 'Untitled').toString(),
      totalAmount: parseAmount(map['totalAmount']),
      description: (map['description'] ?? '').toString(),
      date: parseDate(map['date']),
      paidBy: (map['paidBy'] ?? '').toString(),
      splitAmounts: parseSplitAmounts(map['splitAmounts']),
      category: (map['category'] ?? 'Other').toString(),
      participants: parseParticipants(map['participants']),
      settledAmounts: parseSplitAmounts(map['settledAmounts']),
      participantNames: parseNames(map['participantNames']),
      status: (map['status'] ?? 'ACTIVE').toString().toUpperCase(),
      pendingSettlements: parsePending(map['pendingSettlements']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy,
      'splitAmounts': splitAmounts,
      'category': category,
      'participants': participants,
      'settledAmounts': settledAmounts,
      'participantNames': participantNames,
      'status': status,
      'pendingSettlements':
          pendingSettlements.map((uid, p) => MapEntry(uid, p.toMap())),
    };
  }

  // -----------------------------
  // Derived figures
  // -----------------------------

  /// Everyone in the bill except the payer. These are the people who owe.
  List<String> get payees =>
      participants.where((uid) => uid != paidBy).toList(growable: false);

  /// What [uid] was assigned in the split.
  double shareOf(String uid) => splitAmounts[uid] ?? 0.0;

  /// What [uid] has had approved so far.
  double settledOf(String uid) => settledAmounts[uid] ?? 0.0;

  /// What [uid] still owes the payer. Never negative.
  double remainingFor(String uid) {
    final remaining = shareOf(uid) - settledOf(uid);
    return remaining < kMoneyEpsilon ? 0.0 : remaining;
  }

  /// True once [uid]'s share is fully covered.
  bool isSettledFor(String uid) => remainingFor(uid) <= 0.0;

  /// Amount [uid] has asked to settle that the payer has not resolved yet.
  double pendingFor(String uid) => pendingSettlements[uid]?.amount ?? 0.0;

  /// The open request for [uid], if any.
  PendingSettlement? pendingRequestFor(String uid) => pendingSettlements[uid];

  /// True while [uid] is waiting on the payer to approve or reject.
  bool hasPendingFor(String uid) => pendingFor(uid) > 0;

  /// What [uid] may still put into a new settlement request — their remainder
  /// less anything already awaiting approval.
  double settleableFor(String uid) {
    final settleable = remainingFor(uid) - pendingFor(uid);
    return settleable < kMoneyEpsilon ? 0.0 : settleable;
  }

  /// True while any payee is waiting on this bill's payer.
  bool get hasPendingRequests => pendingSettlements.isNotEmpty;

  /// How many payees are waiting on the payer right now.
  int get pendingRequestCount => pendingSettlements.length;

  /// Total sitting in unresolved requests across every payee.
  double get totalPending =>
      pendingSettlements.values.fold(0.0, (sum, p) => sum + p.amount);

  /// Sum of every payee's share — what the payer is out of pocket.
  double get totalOwedToPayer =>
      payees.fold(0.0, (sum, uid) => sum + shareOf(uid));

  /// Sum of everything approved across all payees.
  double get totalSettled =>
      payees.fold(0.0, (sum, uid) => sum + settledOf(uid));

  /// What the payer is still waiting on across all payees.
  double get totalRemaining =>
      payees.fold(0.0, (sum, uid) => sum + remainingFor(uid));

  /// True when nobody owes the payer anything any more.
  bool get isFullySettled => payees.every(isSettledFor);

  /// 0..1 progress toward the whole bill being square.
  double get settlementProgress {
    final owed = totalOwedToPayer;
    if (owed <= 0) return 1.0;
    return (totalSettled / owed).clamp(0.0, 1.0);
  }

  /// 0..1 progress for one payee.
  double progressFor(String uid) {
    final share = shareOf(uid);
    if (share <= 0) return 1.0;
    return (settledOf(uid) / share).clamp(0.0, 1.0);
  }

  /// Display name for [uid], falling back gracefully for old bills that were
  /// written before names were denormalised.
  String nameOf(String uid, {String fallback = 'Unknown'}) {
    final name = participantNames[uid];
    if (name != null && name.trim().isNotEmpty) return name;
    return fallback;
  }

  SplitBill copyWith({
    String? id,
    String? title,
    double? totalAmount,
    String? description,
    DateTime? date,
    String? paidBy,
    Map<String, double>? splitAmounts,
    String? category,
    List<String>? participants,
    Map<String, double>? settledAmounts,
    Map<String, String>? participantNames,
    String? status,
    Map<String, PendingSettlement>? pendingSettlements,
  }) {
    return SplitBill(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      splitAmounts: splitAmounts ?? this.splitAmounts,
      category: category ?? this.category,
      participants: participants ?? this.participants,
      settledAmounts: settledAmounts ?? this.settledAmounts,
      participantNames: participantNames ?? this.participantNames,
      status: status ?? this.status,
      pendingSettlements: pendingSettlements ?? this.pendingSettlements,
    );
  }
}
