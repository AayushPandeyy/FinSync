import 'package:finance_tracker/enums/businessTransactions/PaymentMethod.dart';
import 'package:finance_tracker/enums/businessTransactions/TransactionStatus.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';

class BusinessTransaction {
  final String id;
  final String businessId;

  final TransactionType type;
  final double amount;
  final String currency;

  final DateTime date;

  final String category;
  final String? description;

  final PaymentMethod paymentMethod;
  final TransactionStatus status;

  final String? clientId; // for income
  final String? vendorId; // for expenses

  final String? invoiceId;

  final bool isRecurring;

  final bool taxIncluded;
  final double? taxAmount;

  final List<String>? tags;

  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessTransaction({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    this.description,
    required this.paymentMethod,
    required this.status,
    this.clientId,
    this.vendorId,
    this.invoiceId,
    this.isRecurring = false,
    this.taxIncluded = false,
    this.taxAmount,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessTransaction copyWith({
    String? id,
    String? businessId,
    TransactionType? type,
    double? amount,
    String? currency,
    DateTime? date,
    String? category,
    String? description,
    PaymentMethod? paymentMethod,
    TransactionStatus? status,
    String? clientId,
    String? vendorId,
    String? invoiceId,
    bool? isRecurring,
    bool? taxIncluded,
    double? taxAmount,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessTransaction(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      vendorId: vendorId ?? this.vendorId,
      invoiceId: invoiceId ?? this.invoiceId,
      isRecurring: isRecurring ?? this.isRecurring,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      taxAmount: taxAmount ?? this.taxAmount,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'clientId': clientId,
      'vendorId': vendorId,
      'invoiceId': invoiceId,
      'isRecurring': isRecurring,
      'taxIncluded': taxIncluded,
      'taxAmount': taxAmount,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusinessTransaction.fromMap(Map<String, dynamic> map) {
    return BusinessTransaction(
      id: map['id'],
      businessId: map['businessId'],
      type: TransactionType.values.byName(map['type']),
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      description: map['description'],
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod']),
      status: TransactionStatus.values.byName(map['status']),
      clientId: map['clientId'],
      vendorId: map['vendorId'],
      invoiceId: map['invoiceId'],
      isRecurring: map['isRecurring'] ?? false,
      taxIncluded: map['taxIncluded'] ?? false,
      taxAmount: map['taxAmount']?.toDouble(),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
