import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/service/GoalsFirestoreService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditGoalPage extends StatefulWidget {
  final FinancialGoal goal;
  const EditGoalPage({super.key, required this.goal});

  @override
  _EditGoalPageState createState() => _EditGoalPageState();
}

class _EditGoalPageState extends State<EditGoalPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  GoalsFirestoreService service = GoalsFirestoreService();

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _amountController.text = widget.goal.targetAmount.toString();
      _titleController.text = widget.goal.title;
      _descriptionController.text = widget.goal.description;
      _selectedDate = widget.goal.deadline;
    });
  }

  void updateGoal() async {
    FinancialGoal goal = FinancialGoal(
        id: widget.goal.id,
        title: _titleController.text,
        description: _descriptionController.text,
        targetAmount: double.parse(_amountController.text),
        currentAmount: 25000,
        deadline: _selectedDate);
    DialogBox().showLoadingDialog(context);
    await service.updateGoal(FirebaseAuth.instance.currentUser!.uid, goal);
    Navigator.pop(context);
    Navigator.pop(context);
    // Function to save transaction to Firestore or any other backend.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: const StandardAppBar(
        title: 'Edit Goal',
        useCustomDesign: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type

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
              ),
              const SizedBox(height: 20),

              // Date

              const Text("Deadline",
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
                  onPressed: updateGoal,
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
    );
  }
}
