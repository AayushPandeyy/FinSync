import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/BannerService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/v6.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedValue;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'INCOME';
  final TransactionFirestoreService service = TransactionFirestoreService();
  bool _isLoadingDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardOfflineEntry());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  Future<void> _guardOfflineEntry() async {
    await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a transaction',
      popCurrentRouteOnFailure: true,
    );
  }

  void _showLoadingDialog() {
    DialogBox().showLoadingDialog(context);
    _isLoadingDialogVisible = true;
  }

  void _hideLoadingDialog() {
    if (_isLoadingDialogVisible && mounted) {
      Navigator.of(context).pop();
      _isLoadingDialogVisible = false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _saveTransaction() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a transaction',
    );
    if (!canProceed) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedValue == null) {
      _showSnack('Please select a category.');
      return;
    }

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null) {
      _showSnack('Enter a valid amount.');
      return;
    }

    final transaction = TransactionModel(
      id: const UuidV6().generate(),
      category: _selectedValue!,
      title: _titleController.text.trim(),
      amount: parsedAmount,
      date: _selectedDate,
      transactionDescription: _descriptionController.text.trim(),
      type: _transactionType,
    );

    _showLoadingDialog();

    try {
      await service.addTransaction(
        FirebaseAuth.instance.currentUser!.uid,
        transaction,
      );

      if (!mounted) return;

      _hideLoadingDialog();
      BannerService().showInterstitialAd();
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _hideLoadingDialog();
      _showSnack(e.message ?? 'Failed to save transaction.');
    } catch (e) {
      _hideLoadingDialog();
      _showSnack('Failed to save transaction. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: const Color(0xFFF8F8FA),
            appBar: StandardAppBar(
              title: 'Add Transaction',
              useCustomDesign: true,
              backgroundColor:
                  _transactionType == "EXPENSE" ? Colors.red : Colors.green,
              titleColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type
                      const Center(
                        child: Text(
                          "Transaction Type",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFormField(
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Amount",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: "Enter amount",
                          prefixIcon: const Icon(Icons.money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text("Description",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: "Enter description",
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date
                      const Text("Category",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 5,
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 4),
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
                                  value: category.name,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(category.icon,
                                            color: Colors.blueGrey),
                                        const SizedBox(width: 10),
                                        Text(category.name,
                                            style:
                                                const TextStyle(fontSize: 16)),
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(
                        height: 5,
                      ),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
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
            )));
  }
}
