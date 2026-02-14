import 'package:finance_tracker/models/Category.dart';
import 'package:finance_tracker/models/Subscription.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/SubscriptionFirestoreService.dart';
import 'package:finance_tracker/utilities/BannerService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddSubscriptionPage extends StatefulWidget {
  const AddSubscriptionPage({super.key});

  @override
  State<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoadingDialogVisible = false;

  DateTime _selectedDate = DateTime.now();
  String _selectedBillingCycle = 'Monthly';
  String _selectedCategory = 'Entertainment';
  IconData _selectedIcon = Icons.movie_outlined;

  final SubscriptionFirestoreService service = SubscriptionFirestoreService();

  final List<String> _billingCycles = ['Monthly', 'Yearly', 'Weekly'];

  final List<Category> categories = Categories().categories;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardOfflineEntry());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
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
      actionDescription: 'add a subscription',
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

  Future<void> _saveSubscription() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a subscription',
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

    final subscription = Subscription(
      name: _nameController.text.trim(),
      amount: amount,
      billingCycle: _selectedBillingCycle,
      nextBillingDate: _selectedDate,
      category: _selectedCategory,
      id: Uuid().v6(),
      isActive: true,
    );

    _showLoadingDialog();

    try {
      await service.addSubscription(
        FirebaseAuth.instance.currentUser!.uid,
        subscription,
      );

      _hideLoadingDialog();
      if (!mounted) return;

      BannerService().showInterstitialAd();
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _hideLoadingDialog();
      _showSnack(e.message ?? 'Failed to add subscription.');
    } catch (e) {
      _hideLoadingDialog();
      _showSnack('Failed to add subscription. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: const StandardAppBar(
        title: 'Add Subscription',
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
                // Subscription Name
                const Text(
                  "Subscription Name",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "e.g., Netflix, Spotify",
                    prefixIcon: const Icon(Icons.subscriptions),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subscription name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Amount
                const Text(
                  "Amount",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "0.00",
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

                // Billing Cycle
                const Center(
                  child: Text(
                    "Billing Cycle",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _billingCycles.map((cycle) {
                    return ChoiceChip(
                      label: Text(cycle),
                      selected: _selectedBillingCycle == cycle,
                      onSelected: (selected) {
                        setState(() {
                          _selectedBillingCycle = cycle;
                        });
                      },
                      selectedColor: const Color(0xFF4A90E2),
                      labelStyle: TextStyle(
                        color: _selectedBillingCycle == cycle
                            ? Colors.white
                            : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Next Billing Date
                const Text(
                  "Next Billing Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
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
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4A90E2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category
                const Text(
                  "Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category.name;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 14,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(category.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category.name;
                          _selectedIcon = category.icon;
                        });
                      },
                      selectedColor: const Color(0xFF4A90E2),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),

                // Save Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveSubscription,
                    child: const Text(
                      "Add Subscription",
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
