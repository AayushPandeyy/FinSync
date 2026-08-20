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
    );
  }

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
