import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class TransactionTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type; // 'INCOME' or 'EXPENSE'
  final DateTime createdAt;

  const TransactionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.createdAt,
  });

  factory TransactionTemplate.fromMap(Map<String, dynamic> map,
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

    return TransactionTemplate(
      id: (map['id'] ?? fallbackId ?? '').toString(),
      title: (map['title'] ?? 'Untitled').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? 'Others').toString(),
      type: (map['type'] ?? 'EXPENSE').toString().toUpperCase(),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TransactionTemplate copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? type,
    DateTime? createdAt,
  }) {
    return TransactionTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
