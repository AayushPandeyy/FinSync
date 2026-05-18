import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    };
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
    );
  }
}
