import 'package:finance_tracker/enums/TransactionType.dart';

class TransactionModel {
  // The unique ID of the transaction
  final String id;
  
  // The title of the transaction (e.g., "Grocery Shopping", "Salary", etc.)
  final String title;
  
  // The amount involved in the transaction (positive for income, negative for expenses)
  final int amount;
  
  // The date and time when the transaction occurred
  final DateTime date;
  
  // A brief transactionDescription or notes for the transaction
  final String transactionDescription;

  // Transaction Category
  final String category;
  
  // The type of the transaction, such as "Income", "Expense", etc.
  final String type;

  // Constructor for creating a new TransactionModel instance
  TransactionModel(  {
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.transactionDescription,
    required this.category,
    required this.type,
  });

  // Factory method to create a TransactionModel from a JSON map
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      
      id: json['id'],  // The ID of the transaction
      title: json['title'],  // The title of the transaction
      amount: json['amount'],  // The amount of the transaction
      transactionDescription: json["transactionDescription"],  // A transactionDescription of the transaction
      date: DateTime.parse(json['date']),  // The date of the transaction (converted to DateTime)
      category : json['category'], // The category of the transaction
      type: json["type"]// The transaction type (Income/Expense)
    );
  }

  // Method to convert TransactionModel to a JSON map for storage or API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,  // The ID of the transaction
      'title': title,  // The title of the transaction
      'amount': amount,  // The amount of the transaction
      'date': date.toIso8601String(),
      'category':category,  // The date in ISO8601 string format
      'type': type,  // The name of the transaction type (e.g., "Income")
    };
  }

  // Method to convert a list of TransactionModel objects to a list of JSON maps
  static List<Map<String, dynamic>> listToJson(List<TransactionModel> TransactionModels) {
    return TransactionModels.map((TransactionModel) => TransactionModel.toJson()).toList();
  }

  // Method to convert a list of JSON maps to a list of TransactionModel objects
  static List<TransactionModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => TransactionModel.fromJson(json)).toList();
  }
}
