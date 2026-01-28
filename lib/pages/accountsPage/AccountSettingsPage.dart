import 'package:finance_tracker/service/AuthFirestoreService.dart';
import 'package:finance_tracker/service/UserFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final UserFirestoreService firestoreService = UserFirestoreService();
  final AuthFirestoreService authFirestoreService = AuthFirestoreService();
  // Non-editable email
  late String _email; // TODO: Get from Firebase Auth

  // Currency selection (default; overwritten from DB when loaded)
  String _selectedCurrency = 'NPR';

  bool _hasInitialized = false;

  final List<Map<String, String>> _currencies = [
    {'code': 'NPR', 'name': 'Nepali Rupee (Rs)', 'symbol': 'Rs'},
    {'code': 'USD', 'name': 'US Dollar (\$)', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro (€)', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound (£)', 'symbol': '£'},
    {'code': 'INR', 'name': 'Indian Rupee (₹)', 'symbol': '₹'},
    {'code': 'JPY', 'name': 'Japanese Yen (¥)', 'symbol': '¥'},
    {'code': 'AUD', 'name': 'Australian Dollar (A\$)', 'symbol': 'A\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar (C\$)', 'symbol': 'C\$'},
  ];

  @override
  void initState() {
    super.initState();

    _email = '';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DialogBox().showLoadingDialog(context);
    try {
      await firestoreService.updateByUserFields(
        user.uid,
        {
          "username": _usernameController.text.trim(),
          "phoneNumber": _phoneController.text.trim(),
          "preferredCurrency": _selectedCurrency,
        },
      );
      // Save currency symbol to SharedPreferences
      await CurrencyService.setCurrencyFromCode(_selectedCurrency);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Changes saved successfully!"),
          backgroundColor: Color(0xFF06D6A0),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save: $e"),
          backgroundColor: const Color(0xFFE63946),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthFirestoreService().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                (Route<dynamic> route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFFE63946),
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              DialogBox().showLoadingDialog(context);
              await firestoreService
                  .deleteUser(FirebaseAuth.instance.currentUser!.uid);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                (Route<dynamic> route) => false,
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFE63946),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _currencyForCode(String? code) {
    if (code == null || code.isEmpty) return _currencies.first;
    return _currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => _currencies.first,
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Currency",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                ...(_currencies.map((currency) {
                  bool isSelected = _selectedCurrency == currency['code'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency['code']!;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF0F7FF)
                            : const Color(0xFFF8F8FA),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFFE5E5E5),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4A90E2).withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                currency['symbol']!,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF4A90E2)
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency['code']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency['name']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF999999),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF4A90E2), size: 24),
                        ],
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Account Settings",
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
                          "Manage your profile",
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

            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),

            // Content
            StreamBuilder<List<Map<String, dynamic>>>(
                stream: firestoreService.getUserDataByEmail(
                    FirebaseAuth.instance.currentUser!.email!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Expanded(
                      child: Center(child: Text("No Data Available.")),
                    );
                  }

                  final data = snapshot.data!;
                  final userData = data[0];

                  if (!_hasInitialized) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _usernameController.text =
                          userData["username"]?.toString() ?? '';
                      _phoneController.text =
                          userData["phoneNumber"]?.toString() ?? '';
                      _email = userData["email"]?.toString() ?? '';
                      final raw = userData["preferredCurrency"];
                      _selectedCurrency = (raw is String && raw.isNotEmpty)
                          ? (_currencies.any((c) => c['code'] == raw)
                              ? raw
                              : 'NPR')
                          : 'NPR';
                      setState(() => _hasInitialized = true);
                    });
                  }

                  if (!_hasInitialized) {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Section
                            _buildSectionHeader('Profile Information', width),
                            SizedBox(height: height * 0.015),

                            // Username
                            _buildSectionTitle('Username', width),
                            SizedBox(height: height * 0.01),
                            _buildTextField(
                              controller: _usernameController,
                              hint: 'Enter username',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter username';
                                }
                                return null;
                              },
                              width: width,
                            ),

                            SizedBox(height: height * 0.025),

                            // Phone Number
                            _buildSectionTitle('Phone Number', width),
                            SizedBox(height: height * 0.01),
                            _buildTextField(
                              controller: _phoneController,
                              hint: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                return null;
                              },
                              width: width,
                            ),

                            SizedBox(height: height * 0.025),

                            // Email (Non-editable)
                            _buildSectionTitle('Email', width),
                            SizedBox(height: height * 0.01),
                            Container(
                              padding: EdgeInsets.all(width * 0.04),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8FA),
                                border: Border.all(
                                  color: const Color(0xFFE5E5E5),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF999999),
                                    size: 20,
                                  ),
                                  SizedBox(width: width * 0.03),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: TextStyle(
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E5E5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Not editable',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: height * 0.04),

                            // Preferences Section
                            _buildSectionHeader('Preferences', width),
                            SizedBox(height: height * 0.015),

                            // Currency
                            _buildSectionTitle('Preferred Currency', width),
                            SizedBox(height: height * 0.01),
                            GestureDetector(
                              onTap: _showCurrencyPicker,
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
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A90E2)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _currencyForCode(
                                              _selectedCurrency)['symbol']!,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4A90E2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: width * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedCurrency,
                                            style: TextStyle(
                                              fontSize: width * 0.04,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _currencyForCode(
                                                _selectedCurrency)['name']!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF999999),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFF999999),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: height * 0.04),

                            // Save Changes Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveChanges,
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
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: width * 0.042,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: height * 0.04),

                            // Actions Section
                            _buildSectionHeader('Actions', width),
                            SizedBox(height: height * 0.015),

                            // Logout Button
                            GestureDetector(
                              onTap: _logout,
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
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A90E2)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.logout,
                                        color: Color(0xFF4A90E2),
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.03),
                                    const Expanded(
                                      child: Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFF999999),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: height * 0.015),

                            // Delete Account Button
                            GestureDetector(
                              onTap: _deleteAccount,
                              child: Container(
                                padding: EdgeInsets.all(width * 0.04),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3F3),
                                  border: Border.all(
                                    color: const Color(0xFFE63946)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE63946)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_forever,
                                        color: Color(0xFFE63946),
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.03),
                                    const Expanded(
                                      child: Text(
                                        'Delete Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFE63946),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFFE63946),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: height * 0.02),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double width) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
      ],
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
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
