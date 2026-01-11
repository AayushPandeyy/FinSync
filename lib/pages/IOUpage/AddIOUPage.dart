import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String _selectedType = 'owe'; // 'owe' or 'owed'
  bool _hasDueDate = false;
  IconData _selectedIcon = Icons.person;

  final List<Map<String, dynamic>> _icons = [
    {'name': 'Person', 'icon': Icons.person},
    {'name': 'Dinner', 'icon': Icons.restaurant},
    {'name': 'Movie', 'icon': Icons.movie},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Coffee', 'icon': Icons.coffee},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Emergency', 'icon': Icons.emergency},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

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

  void _saveIOU() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save IOU to database
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IOU added successfully!'),
          backgroundColor: Color(0xFF06D6A0),
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
            // Custom Navigation Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1A1A1A),
                        size: 18,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title section
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add IOU",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.8,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Track what you owe or are owed",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.05),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Selection
                      _buildSectionTitle('Type', width),
                      SizedBox(height: height * 0.01),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFE5E5E5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedType = 'owe';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.018,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedType == 'owe'
                                        ? const Color(0xFFE63946)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 16,
                                        color: _selectedType == 'owe'
                                            ? Colors.white
                                            : const Color(0xFF666666),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'I Owe',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _selectedType == 'owe'
                                              ? Colors.white
                                              : const Color(0xFF666666),
                                          fontWeight: _selectedType == 'owe'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: width * 0.038,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedType = 'owed';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.018,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedType == 'owed'
                                        ? const Color(0xFF06D6A0)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 16,
                                        color: _selectedType == 'owed'
                                            ? Colors.white
                                            : const Color(0xFF666666),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Owes Me',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _selectedType == 'owed'
                                              ? Colors.white
                                              : const Color(0xFF666666),
                                          fontWeight: _selectedType == 'owed'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: width * 0.038,
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
                      
                      SizedBox(height: height * 0.025),

                      // Person Name
                      _buildSectionTitle('Person Name', width),
                      SizedBox(height: height * 0.01),
                      _buildTextField(
                        controller: _personNameController,
                        hint: 'e.g., John Doe',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter person name';
                          }
                          return null;
                        },
                        width: width,
                      ),
                      
                      SizedBox(height: height * 0.025),

                      // Amount
                      _buildSectionTitle('Amount (Rs)', width),
                      SizedBox(height: height * 0.01),
                      _buildTextField(
                        controller: _amountController,
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        width: width,
                      ),

                      SizedBox(height: height * 0.025),

                      // Description
                      _buildSectionTitle('Description', width),
                      SizedBox(height: height * 0.01),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'e.g., Dinner split, Movie tickets',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                        width: width,
                      ),

                      SizedBox(height: height * 0.025),

                      // Date
                      _buildSectionTitle('Date', width),
                      SizedBox(height: height * 0.01),
                      GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF4A90E2),
                                size: 20,
                              ),
                              SizedBox(width: width * 0.03),
                              Text(
                                DateFormat('d MMM yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.025),

                      // Due Date Checkbox
                      _buildSectionTitle('Due Date', width),
                      SizedBox(height: height * 0.01),
                      
                      // Checkbox for "Is there a due date?"
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _hasDueDate = !_hasDueDate;
                            if (!_hasDueDate) {
                              _selectedDueDate = null;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
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
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _hasDueDate
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Set a due date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Due Date Picker (shown only if checkbox is checked)
                      if (_hasDueDate) ...[
                        SizedBox(height: height * 0.015),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: EdgeInsets.all(width * 0.04),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F7FF),
                              border: Border.all(
                                color: const Color(0xFF4A90E2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  color: Color(0xFF4A90E2),
                                  size: 20,
                                ),
                                SizedBox(width: width * 0.03),
                                Text(
                                  _selectedDueDate != null
                                      ? DateFormat('d MMM yyyy').format(_selectedDueDate!)
                                      : 'Select due date',
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF4A90E2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: height * 0.025),

                      // Icon Selection
                      _buildSectionTitle('Icon', width),
                      SizedBox(height: height * 0.015),
                      Wrap(
                        spacing: width * 0.025,
                        runSpacing: height * 0.015,
                        children: _icons.map((iconData) {
                          final isSelected = _selectedIcon == iconData['icon'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = iconData['icon'];
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: height * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF4A90E2) 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4A90E2)
                                      : const Color(0xFFE5E5E5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconData['icon'],
                                    size: width * 0.045,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF666666),
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    iconData['name'],
                                    style: TextStyle(
                                      fontSize: width * 0.035,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: height * 0.04),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveIOU,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: height * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            backgroundColor: const Color(0xFF4A90E2),
                          ),
                          child: Text(
                            'Add IOU',
                            style: TextStyle(
                              fontSize: width * 0.042,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

  Widget _buildSectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.038,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
      ),
    );
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
      style: TextStyle(
        fontSize: width * 0.04,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4A90E2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE63946),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE63946),
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.04,
        ),
      ),
    );
  }
}