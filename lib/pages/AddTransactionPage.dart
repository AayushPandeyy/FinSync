import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/v6.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'EXPENSE';
  FirestoreService service = FirestoreService();

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    TransactionModel transaction = TransactionModel(
        id: const UuidV6().generate(),
        title: _titleController.text,
        amount: int.parse(_amountController.text),
        date: _selectedDate,
        transactionDescription: _descriptionController.text,
        type: _transactionType);
    DialogBox().showLoadingDialog(context);
    await service.addTransaction(
        FirebaseAuth.instance.currentUser!.uid, transaction);
    Navigator.pop(context);
    Navigator.pop(context);
    // Function to save transaction to Firestore or any other backend.
    print("Saving transaction");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor:
            _transactionType == "EXPENSE" ? Colors.red : Colors.green,
        elevation: 0,
        title: const Text('Add Transaction', style: TextStyle(fontSize: 24)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type
              const Center(
                child: Text(
                  "Transaction Type",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ChoiceChip(
                    label: const Text("Income"),
                    selected: _transactionType == "INCOME",
                    onSelected: (selected) {
                      setState(() {
                        _transactionType = "INCOME";
                      });
                    },
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                        color: _transactionType == "INCOME"
                            ? Colors.white
                            : Colors.black),
                  ),
                  ChoiceChip(
                    label: const Text("Expense"),
                    selected: _transactionType == "EXPENSE",
                    onSelected: (selected) {
                      setState(() {
                        _transactionType = "EXPENSE";
                      });
                    },
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                        color: _transactionType == "EXPENSE"
                            ? Colors.white
                            : Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount
              const Text("Title",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Enter title",
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Amount",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Description
              const Text("Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Enter description",
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Date
              const Text("Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat.yMMMMd().format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.teal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _saveTransaction,
                  child: const Text(
                    "Save Transaction",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}