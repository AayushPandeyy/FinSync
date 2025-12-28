import 'package:finance_tracker/models/Category.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatefulWidget {
  final List<Category> categories;
  final Function(Category) onChanged;

  const CategoryDropdown({
    Key? key,
    required this.categories,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CategoryDropdownState createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  Category? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Category>(
          value: selectedCategory,
          hint: Row(
            children: [
              Icon(Icons.category, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Text(
                "Select Category",
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ],
          ),
          items: widget.categories.map((Category category) {
            return DropdownMenuItem<Category>(
              value: category,
              child: Row(
                children: [
                  Icon(category.icon, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (Category? value) {
            setState(() {
              selectedCategory = value;
            });
            if (value != null) widget.onChanged(value);
          },
        ),
      ),
    );
  }
}
