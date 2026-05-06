import 'package:finance_tracker/models/Category.dart';
import 'package:flutter/material.dart';

class Categories {
  // 💰 Income Categories
  final List<Category> incomeCategories = [
    Category(name: 'Salary', icon: Icons.work),
    Category(name: 'Business', icon: Icons.business),
    Category(name: 'Freelance', icon: Icons.laptop),
    Category(name: 'Investments', icon: Icons.show_chart),
    Category(name: 'Interest', icon: Icons.savings),
    Category(name: 'Rental Income', icon: Icons.home),
    Category(name: 'Dividends', icon: Icons.trending_up),
    Category(name: 'Bonus', icon: Icons.card_giftcard),
    Category(name: 'Refunds', icon: Icons.replay),
    Category(name: 'Side Hustle', icon: Icons.handyman),
    Category(name: 'Others', icon: Icons.more_horiz),
  ];

  // 💸 Expense Categories
  final List<Category> expenseCategories = [
    Category(name: 'Groceries', icon: Icons.shopping_cart),
    Category(name: 'Bills', icon: Icons.receipt),
    Category(name: 'Transportation', icon: Icons.directions_bus),
    Category(name: 'Health', icon: Icons.local_hospital),
    Category(name: 'Entertainment', icon: Icons.movie),
    Category(name: 'Shopping', icon: Icons.shopping_bag),
    Category(name: 'Food & Dining', icon: Icons.restaurant),
    Category(name: 'Travel', icon: Icons.airplanemode_active),
    Category(name: 'Education', icon: Icons.school),
    Category(name: 'Personal Care', icon: Icons.spa),
    Category(name: 'Gifts & Donations', icon: Icons.card_giftcard),
    Category(name: 'Insurance', icon: Icons.security),
    Category(name: 'Rent', icon: Icons.house),
    Category(name: 'Utilities', icon: Icons.electrical_services),
    Category(name: 'Subscriptions', icon: Icons.subscriptions),
    Category(name: 'Others', icon: Icons.more_horiz),
  ];

  /// Get all categories combined (for backward compatibility and icon lookups)
  List<Category> get categories => [...incomeCategories, ...expenseCategories];

  /// Get categories by transaction type
  List<Category> getCategories(String type) {
    return type.toUpperCase() == 'INCOME'
        ? incomeCategories
        : expenseCategories;
  }
}
