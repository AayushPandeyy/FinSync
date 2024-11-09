import 'package:finance_tracker/enums/TransactionType.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  // Method to convert JSON data to a Transaction object
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values.byName(json['type']),
    );
  }

  // Method to convert Transaction object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  // Method to convert a list of Transactions to JSON format
  static List<Map<String, dynamic>> listToJson(List<Transaction> transactions) {
    return transactions.map((transaction) => transaction.toJson()).toList();
  }

  // Method to convert a JSON list to a list of Transaction objects
  static List<Transaction> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }
}
