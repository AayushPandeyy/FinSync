import 'package:flutter/material.dart';

class Loan {
  final String id;
  final String name;
  final double totalAmount;
  final double paidAmount;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final String type; // 'given' or 'taken'
  final String lender; // person/institution name
  final IconData icon;
  final Color color;

  Loan({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.paidAmount,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    required this.type,
    required this.lender,
    this.icon = Icons.account_balance_wallet,
    this.color = const Color(0xFF4A90E2),
  });

  double get remainingAmount => totalAmount - paidAmount;
  double get progressPercentage => (paidAmount / totalAmount) * 100;
}