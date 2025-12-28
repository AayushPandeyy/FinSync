import 'package:finance_tracker/models/Category.dart';
import 'package:flutter/material.dart';

class Categories {
  final List<Category> categories = [
    Category(name: 'Income', icon: Icons.attach_money),
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
    Category(name: 'Savings', icon: Icons.savings),
    Category(name: 'Investments', icon: Icons.show_chart),
    Category(name: 'Insurance', icon: Icons.security),
    Category(name: 'Others', icon: Icons.more_horiz),
  ];
}
