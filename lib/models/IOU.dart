import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';

@immutable
class IOU {
  final String id;
  final String personName;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime? dueDate;
  final IOUType iouType;
  final IOUStatus status;
  final String category;
  final double settledAmount;

  /// Non-null when this IOU is a mirror of a split bill. Split-linked IOUs are
  /// read-only on the IOU page — the bill document owns them.
  final String? splitBillId;

  /// UID the split bill document lives under (the payer). Needed to build the
  /// bill path from either side of the mirror.
  final String? splitBillOwnerId;

  /// The other party in this IOU. For a payee's OWE row this is the payer; for
  /// the payer's OWED row this is the payee.
  final String? counterpartyUid;

  /// Amount sitting in a PENDING settlement request awaiting the payer's
  /// approval. Not yet deducted from [settledAmount].
  final double pendingSettleAmount;

  const IOU({
    required this.id,
    required this.personName,
    required this.amount,
    required this.description,
    required this.date,
    this.dueDate,
    required this.iouType,
    this.status = IOUStatus.PENDING,
    required this.category,
    this.settledAmount = 0.0,
    this.splitBillId,
    this.splitBillOwnerId,
    this.counterpartyUid,
    this.pendingSettleAmount = 0.0,
  });

  // -----------------------------
  // Firestore serialization
  // -----------------------------

  factory IOU.fromMap(Map<String, dynamic> map, {String? fallbackId}) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    IOUType parseType(dynamic value) {
      final normalized = (value ?? '').toString().trim().toUpperCase();
      if (normalized == 'OWED' || normalized == 'OWES_ME') {
        return IOUType.OWED;
      }
      return IOUType.OWE;
    }

    IOUStatus parseStatus(dynamic value) {
      final normalized = (value ?? '').toString().trim().toUpperCase();
      if (normalized == 'SETTLED') return IOUStatus.SETTLED;
      return IOUStatus.PENDING;
    }

    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    String? parseOptionalString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return IOU(
      id: (map['id'] ?? fallbackId ?? '').toString(),
      personName: (map['personName'] ?? map['name'] ?? 'Unknown').toString(),
      amount: parseAmount(map['amount']),
      description: (map['description'] ?? '').toString(),
      date: parseDate(map['date']),
      dueDate: parseOptionalDate(map['dueDate']),
      iouType: parseType(map['iouType']),
      status: parseStatus(map['status']),
      category: (map['category'] ?? 'Other').toString(),
      settledAmount: parseAmount(map['settledAmount']),
      splitBillId: parseOptionalString(map['splitBillId']),
      splitBillOwnerId: parseOptionalString(map['splitBillOwnerId']),
      counterpartyUid: parseOptionalString(map['counterpartyUid']),
      pendingSettleAmount: parseAmount(map['pendingSettleAmount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'iouType': iouType.name,
      'status': status.name,
      'category': category,
      'settledAmount': settledAmount,
      'splitBillId': splitBillId,
      'splitBillOwnerId': splitBillOwnerId,
      'counterpartyUid': counterpartyUid,
      'pendingSettleAmount': pendingSettleAmount,
    };
  }

  // -----------------------------
  // Utilities
  // -----------------------------

  IOU copyWith({
    String? id,
    String? personName,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    IOUType? iouType,
    IOUStatus? status,
    String? category,
    double? settledAmount,
    String? splitBillId,
    String? splitBillOwnerId,
    String? counterpartyUid,
    double? pendingSettleAmount,
  }) {
    return IOU(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      iouType: iouType ?? this.iouType,
      status: status ?? this.status,
      category: category ?? this.category,
      settledAmount: settledAmount ?? this.settledAmount,
      splitBillId: splitBillId ?? this.splitBillId,
      splitBillOwnerId: splitBillOwnerId ?? this.splitBillOwnerId,
      counterpartyUid: counterpartyUid ?? this.counterpartyUid,
      pendingSettleAmount: pendingSettleAmount ?? this.pendingSettleAmount,
    );
  }

  // -----------------------------
  // Derived
  // -----------------------------

  /// True when this IOU is managed by a split bill rather than entered by hand.
  bool get isSplitLinked =>
      splitBillId != null && splitBillId!.isNotEmpty;

  /// What is still outstanding, ignoring anything awaiting approval.
  double get remainingAmount {
    final remaining = amount - settledAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  /// What can still be requested — the remainder minus anything already
  /// sitting in a pending request.
  double get settleableAmount {
    final settleable = remainingAmount - pendingSettleAmount;
    return settleable < 0 ? 0.0 : settleable;
  }

  /// True while a settlement request on this IOU is waiting on the payer.
  bool get hasPendingApproval => pendingSettleAmount > 0;

  @override
  String toString() {
    return 'IOU(id: $id, personName: $personName, amount: $amount, status: $status, settledAmount: $settledAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IOU && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
