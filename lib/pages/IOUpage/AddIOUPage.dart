import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/service/IOUFirestoreService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddIOUPage extends StatefulWidget {
  const AddIOUPage({super.key});

  @override
  State<AddIOUPage> createState() => _AddIOUPageState();
}

class _AddIOUPageState extends State<AddIOUPage> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  IOUType _selectedType = IOUType.OWE; // default "I Owe"
  bool _hasDueDate = false;
  IconData _selectedIcon = Icons.person;

  final Ioufirestoreservice firestoreService = Ioufirestoreservice();

  final List<String> _categories = [
    'Personal',
    'Food',
    'Entertainment',
    'Shopping',
    'Coffee',
    'Transport',
    'Gift',
    'Emergency',
    'Other',
  ];

  String _selectedCategory = 'Personal';

  InterstitialAd? _interstitialAd;

  void _showInterstitialAd() {
    InterstitialAd.load(
      // adUnitId: 'ca-app-pub-3940256099942544/1033173712', // test Ad Unit ID
      adUnitId:'ca-app-pub-3804780729029008/1042521213',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          _interstitialAd!.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate
          ? (_selectedDueDate ?? DateTime.now().add(const Duration(days: 7)))
          : _selectedDate,
      firstDate: isDueDate ? DateTime.now() : DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90E2),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _selectedDueDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _saveIOU() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading
    DialogBox().showLoadingDialog(context);

    try {
      // Create IOU object
      final iou = IOU(
        id: Uuid().v1(),
        personName: _personNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        dueDate: _hasDueDate ? _selectedDueDate : null,
        iouType: _selectedType,
        category: _selectedCategory,
      );

      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Add to Firestore
      await firestoreService.addIOU(userId, iou);

      // Close loading dialog
      Navigator.of(context).pop();

      _showInterstitialAd();

      // Close AddIOUPage
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IOU added successfully!'),
          backgroundColor: Color(0xFF06D6A0),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add IOU: $e'),
          backgroundColor: const Color(0xFFE63946),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- Navigation Bar ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF1A1A1A), size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add IOU",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF1A1A1A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Track what you owe or are owed",
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: const Color(0xFFF0F0F0)),

            // --- Form ---
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.05),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Type', width),
                      const SizedBox(height: 12),
                      _buildTypeSelector(width, height),

                      SizedBox(height: height * 0.025),
                      _buildSectionTitle('Person Name', width),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _personNameController,
                        hint: 'e.g., John Doe',
                        width: width,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter person name'
                            : null,
                      ),

                      SizedBox(height: height * 0.025),
                      _buildSectionTitle('Amount (Rs)', width),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _amountController,
                        hint: '0.00',
                        width: width,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: height * 0.025),
                      _buildSectionTitle('Description', width),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'e.g., Dinner split',
                        width: width,
                        maxLines: 3,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter description'
                            : null,
                      ),

                      SizedBox(height: height * 0.025),
                      _buildSectionTitle('Date', width),
                      const SizedBox(height: 8),
                      _buildDatePicker(width, false),

                      SizedBox(height: height * 0.025),
                      _buildSectionTitle('Due Date', width),
                      const SizedBox(height: 8),
                      _buildDueDateSelector(width),

                      SizedBox(height: height * 0.025),
                      _buildSectionTitle('Category', width),
                      const SizedBox(height: 12),
                      _buildCategoryPicker(width, height),

                      SizedBox(height: height * 0.04),
                      // --- Save Button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveIOU,
                          style: ElevatedButton.styleFrom(
                            padding:
                                EdgeInsets.symmetric(vertical: height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF4A90E2),
                          ),
                          child: Text(
                            'Add IOU',
                            style: TextStyle(
                                fontSize: width * 0.042,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionTitle(String title, double width) {
    return Text(title,
        style: TextStyle(fontSize: width * 0.038, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required double width,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.04),
      ),
    );
  }

  Widget _buildTypeSelector(double width, double height) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = IOUType.OWE),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: height * 0.018),
              decoration: BoxDecoration(
                color: _selectedType == IOUType.OWE
                    ? const Color(0xFFE63946)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_downward,
                      color: _selectedType == IOUType.OWE
                          ? Colors.white
                          : const Color(0xFF666666),
                      size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'I Owe',
                    style: TextStyle(
                        color: _selectedType == IOUType.OWE
                            ? Colors.white
                            : const Color(0xFF666666),
                        fontWeight: _selectedType == IOUType.OWE
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: width * 0.038),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = IOUType.OWED),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: height * 0.018),
              decoration: BoxDecoration(
                color: _selectedType == IOUType.OWED
                    ? const Color(0xFF06D6A0)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_upward,
                      color: _selectedType == IOUType.OWED
                          ? Colors.white
                          : const Color(0xFF666666),
                      size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Owes Me',
                    style: TextStyle(
                        color: _selectedType == IOUType.OWED
                            ? Colors.white
                            : const Color(0xFF666666),
                        fontWeight: _selectedType == IOUType.OWED
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: width * 0.038),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(double width, bool isDueDate) {
    final date = isDueDate ? _selectedDueDate ?? DateTime.now() : _selectedDate;
    return GestureDetector(
      onTap: () => _selectDate(context, isDueDate),
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF4A90E2)),
            const SizedBox(width: 12),
            Text(
              DateFormat('d MMM yyyy').format(date),
              style: TextStyle(
                  fontSize: width * 0.04, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector(double width) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _hasDueDate = !_hasDueDate;
              if (!_hasDueDate) _selectedDueDate = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _hasDueDate
                        ? const Color(0xFF4A90E2)
                        : Colors.transparent,
                    border: Border.all(
                        color: _hasDueDate
                            ? const Color(0xFF4A90E2)
                            : const Color(0xFFCCCCCC),
                        width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _hasDueDate
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                const Text('Set a due date', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        if (_hasDueDate) ...[
          const SizedBox(height: 8),
          _buildDatePicker(width, true),
        ],
      ],
    );
  }

  Widget _buildCategoryPicker(double width, double height) {
    return Wrap(
      spacing: width * 0.025,
      runSpacing: height * 0.015,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.045,
              vertical: height * 0.014,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A90E2) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A90E2)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: width * 0.035,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
