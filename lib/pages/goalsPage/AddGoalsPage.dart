import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/GoalsFirestoreService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/BannerService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddGoalsPage extends StatefulWidget {
  const AddGoalsPage({super.key});

  @override
  _AddGoalsPageState createState() => _AddGoalsPageState();
}

class _AddGoalsPageState extends State<AddGoalsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  GoalsFirestoreService service = GoalsFirestoreService();
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
      actionDescription: 'add a goal',
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

  Future<void> saveGoal() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a goal',
    );
    if (!canProceed) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      _showSnack('Enter a valid amount.');
      return;
    }

    final goal = FinancialGoal(
      id: const Uuid().v6(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      targetAmount: amount,
      currentAmount: 25000,
      deadline: _selectedDate,
    );

    _showLoadingDialog();

    try {
      await service.addGoals(
        FirebaseAuth.instance.currentUser!.uid,
        goal,
      );

      if (!mounted) return;

      _hideLoadingDialog();
      BannerService().showInterstitialAd();
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _hideLoadingDialog();
      _showSnack(e.message ?? 'Failed to save goal.');
    } catch (e) {
      _hideLoadingDialog();
      _showSnack('Failed to save goal. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: const StandardAppBar(
        title: 'Add Goal',
        useCustomDesign: true,
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

                // Amount
                const Text("Title",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 5,
                ),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

                const Text("Deadline",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.calendar_today, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 233, 233, 130),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: saveGoal,
                    child: const Text(
                      "Save Goal",
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
