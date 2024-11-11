import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EditTransactionPage extends StatefulWidget {
  final String id;
  final String type;
  final String title;
  final String description;
  final int amount;
  final String category;
  final DateTime date;
  const EditTransactionPage(
      {super.key,
      required this.type,
      required this.title,
      required this.description,
      required this.amount,
      required this.category,
      required this.date,
      required this.id});

  @override
  _EditTransactionPageState createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  String? _selectedValue;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _transactionType;
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
        id: widget.id,
        category: _selectedValue!,
        title: _titleController.text,
        amount: int.parse(_amountController.text),
        date: _selectedDate!,
        transactionDescription: _descriptionController.text,
        type: _transactionType!);
    DialogBox().showLoadingDialog(context);
    await service.updateTransaction(
        uid: FirebaseAuth.instance.currentUser!.uid, transaction: transaction);
    Navigator.pop(context);
    Navigator.pop(context);
    // Function to save transaction to Firestore or any other backend.
    print("Saving transaction");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _titleController.text = widget.title;
      _descriptionController.text = widget.description;
      _amountController.text = widget.amount.toString();
      _selectedDate = widget.date;
      _selectedValue = widget.category;
      _transactionType = widget.type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor:
            _transactionType == "EXPENSE" ? Colors.red : Colors.green,
        elevation: 0,
        title: const Text('Edit Transaction', style: TextStyle(fontSize: 24)),
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
              const SizedBox(
                height: 5,
              ),
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
              const SizedBox(
                height: 5,
              ),
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
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  prefixIcon: const Icon(Icons.money),
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
              const SizedBox(
                height: 5,
              ),
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
              const Text("Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 5,
              ),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        // width: 1,
                        ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedValue,
                      hint: Text("Select an option",
                          style: GoogleFonts.afacad(fontSize: 16)),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 28,
                      ),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedValue = value;
                        });
                      },
                      items: Categories().categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(category['icon'], color: Colors.blueGrey),
                                const SizedBox(width: 10),
                                Text(category['name'],
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text("Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 5,
              ),
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
                        DateFormat.yMMMMd().format(_selectedDate!),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: _transactionType == "EXPENSE"
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _transactionType == "EXPENSE"
                        ? Colors.red
                        : Colors.green,
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
