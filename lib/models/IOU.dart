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

  factory IOU.fromMap(Map<String, dynamic> map) {
    return IOU(
      id: map['id'] as String,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: (map['date'] as Timestamp).toDate(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      iouType: IOUType.values.firstWhere(
        (e) => e.name == map['iouType'],
      ),
      status: IOUStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      category: map['category'] as String,
      settledAmount: map['settledAmount'] != null
          ? (map['settledAmount'] as num).toDouble()
          : 0.0,
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
