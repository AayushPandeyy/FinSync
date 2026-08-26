import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/enums/splitBill/SettlementStatus.dart';

@immutable
class SettlementRequest {
  final String id;
  final String billId;
  final String billOwnerId; // UID of the payer — the bill doc lives under this
  final String fromUid; // Payee asking to settle
  final String toUid; // Payer who must approve
  final double amount;
  final String note;
  final DateTime requestedAt;
  final SettlementStatus status;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const SettlementRequest({
    required this.id,
    required this.billId,
    required this.billOwnerId,
    required this.fromUid,
    required this.toUid,
    required this.amount,
    this.note = '',
    required this.requestedAt,
    this.status = SettlementStatus.PENDING,
    this.resolvedAt,
    this.resolvedBy,
  });

  // -----------------------------
  // Firestore serialization
  // -----------------------------

  factory SettlementRequest.fromMap(Map<String, dynamic> map,
      {String? fallbackId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    SettlementStatus parseStatus(dynamic value) {
      final normalized = (value ?? '').toString().trim().toUpperCase();
      if (normalized == 'APPROVED') return SettlementStatus.APPROVED;
      if (normalized == 'REJECTED') return SettlementStatus.REJECTED;
      return SettlementStatus.PENDING;
    }

    return SettlementRequest(
      id: (map['id'] ?? fallbackId ?? '').toString(),
      billId: (map['billId'] ?? '').toString(),
      billOwnerId: (map['billOwnerId'] ?? '').toString(),
      fromUid: (map['fromUid'] ?? '').toString(),
      toUid: (map['toUid'] ?? '').toString(),
      amount: parseAmount(map['amount']),
      note: (map['note'] ?? '').toString(),
      requestedAt: parseDate(map['requestedAt']),
      status: parseStatus(map['status']),
      resolvedAt: parseOptionalDate(map['resolvedAt']),
      resolvedBy: map['resolvedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'billOwnerId': billOwnerId,
      'fromUid': fromUid,
      'toUid': toUid,
      'amount': amount,
      'note': note,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }

  // -----------------------------
  // Utilities
  // -----------------------------

  bool get isPending => status == SettlementStatus.PENDING;
  bool get isApproved => status == SettlementStatus.APPROVED;
  bool get isRejected => status == SettlementStatus.REJECTED;

  SettlementRequest copyWith({
    String? id,
    String? billId,
    String? billOwnerId,
    String? fromUid,
    String? toUid,
    double? amount,
    String? note,
    DateTime? requestedAt,
    SettlementStatus? status,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return SettlementRequest(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      billOwnerId: billOwnerId ?? this.billOwnerId,
      fromUid: fromUid ?? this.fromUid,
      toUid: toUid ?? this.toUid,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  @override
  String toString() {
    return 'SettlementRequest(id: $id, billId: $billId, from: $fromUid, '
        'amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettlementRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// A settlement request that is still waiting on the payer, denormalised onto
/// the bill document under `pendingSettlements[payeeUid]`.
///
/// Keeping this on the bill means a card can render "Rs X awaiting approval"
/// straight from the bill stream, and it lets the request transaction enforce
/// one open request per payee atomically — a subcollection query cannot run
/// inside a Firestore transaction.
@immutable
class PendingSettlement {
  final String requestId;
  final double amount;
  final DateTime requestedAt;
  final String note;

  const PendingSettlement({
    required this.requestId,
    required this.amount,
    required this.requestedAt,
    this.note = '',
  });

  factory PendingSettlement.fromMap(Map<String, dynamic> map) {
    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return PendingSettlement(
      requestId: (map['requestId'] ?? '').toString(),
      amount: parseAmount(map['amount']),
      requestedAt: parseDate(map['requestedAt']),
      note: (map['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'amount': amount,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'note': note,
    };
  }
}
