import 'package:flutter/material.dart';

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String billingCycle;
  final DateTime nextBillingDate;
  final String category;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
  });
}