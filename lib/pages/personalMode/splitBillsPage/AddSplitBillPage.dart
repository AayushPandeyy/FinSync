import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/FriendsFirestoreService.dart';
import 'package:finance_tracker/service/SplitBillsFirestoreService.dart';
import 'package:finance_tracker/utilities/BannerService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddSplitBillPage extends StatefulWidget {
  const AddSplitBillPage({super.key});

  @override
  State<AddSplitBillPage> createState() => _AddSplitBillPageState();
}

class _AddSplitBillPageState extends State<AddSplitBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoadingDialogVisible = false;

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Other';
  Set<String> _selectedParticipants = {};
  Map<String, String> _friendNames = {};
  Map<String, double> _participantAmounts = {};
  Map<String, TextEditingController> _participantControllers = {};
  String _searchQuery = '';

  late String _currentUserId;

  final List<String> _categories = [
    'Food',
    'Entertainment',
    'Shopping',
    'Transport',
    'Accommodation',
    'Utilities',
    'Gift',
    'Travel',
    'Emergency',
    'Other',
  ];

  final Friendsfirestoreservice friendsService = Friendsfirestoreservice();
  final SplitBillsFirestoreService splitBillsService =
      SplitBillsFirestoreService();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardOfflineEntry());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    for (final controller in _participantControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardOfflineEntry() async {
    await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a split bill',
      popCurrentRouteOnFailure: true,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF39C12),
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
        _selectedDate = picked;
      });
    }
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

  void _showSnack(String message,
      {Color background = const Color(0xFFE63946)}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: background,
        ),
      );
  }

  Future<void> _saveSplitBill() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a split bill',
    );
    if (!canProceed) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedParticipants.isEmpty) {
      _showSnack('Please select at least one participant');
      return;
    }

    _showLoadingDialog();

    try {
      final totalAmount = double.parse(_amountController.text.trim());
      final participants = [_currentUserId, ..._selectedParticipants];

      final splitAmounts = <String, double>{};

      // Add current user with their share (or 0 if they haven't entered an amount)
      splitAmounts[_currentUserId] = 0.0;

      // Add selected participants with their custom amounts
      for (final participantId in _selectedParticipants) {
        final amount = _participantAmounts[participantId] ?? 0.0;
        splitAmounts[participantId] = amount;
      }

      // Validate that total of splits equals or doesn't exceed total amount
      final totalSplits =
          splitAmounts.values.fold(0.0, (sum, val) => sum + val);
      if (totalSplits > totalAmount) {
        _hideLoadingDialog();
        _showSnack('Sum of participant amounts exceeds total amount');
        return;
      }

      final splitBill = SplitBill(
        id: Uuid().v1(),
        title: _titleController.text.trim(),
        totalAmount: totalAmount,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        paidBy: _currentUserId,
        splitAmounts: splitAmounts,
        category: _selectedCategory,
        participants: participants,
      );

      await splitBillsService.addSplitBill(_currentUserId, splitBill);

      _hideLoadingDialog();
      if (!mounted) return;

      BannerService().showInterstitialAd();
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _hideLoadingDialog();
      _showSnack(e.message ?? 'Failed to add split bill.');
    } catch (e) {
      _hideLoadingDialog();
      _showSnack('Failed to add split bill. Please try again.');
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
                          "Add Split Bill",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF1A1A1A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Divide expenses with friends",
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFFF0F0F0)),

            // --- Form ---
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05,
                  vertical: width * 0.03,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Title', width),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'e.g., Dinner at Restaurant',
                        width: width,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter a title'
                            : null,
                      ),
                      SizedBox(height: height * 0.015),
                      _buildSectionTitle('Total Amount', width),
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
                      SizedBox(height: height * 0.015),
                      _buildSectionTitle('Description', width),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'e.g., Party at home',
                        width: width,
                        maxLines: 2,
                      ),
                      SizedBox(height: height * 0.015),
                      _buildSectionTitle('Date', width),
                      const SizedBox(height: 8),
                      _buildDatePicker(width),
                      SizedBox(height: height * 0.015),
                      _buildSectionTitle('Category', width),
                      const SizedBox(height: 12),
                      _buildCategoryPicker(width),
                      SizedBox(height: height * 0.015),
                      _buildSectionTitle('Participants', width),
                      const SizedBox(height: 12),
                      _buildParticipantsSection(width),
                      SizedBox(height: height * 0.02),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveSplitBill,
                          style: ElevatedButton.styleFrom(
                            padding:
                                EdgeInsets.symmetric(vertical: height * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFFF39C12),
                          ),
                          child: Text(
                            'Add Split Bill',
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
          borderSide: const BorderSide(color: Color(0xFFF39C12), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.04),
      ),
    );
  }

  Widget _buildDatePicker(double width) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFFF39C12)),
            const SizedBox(width: 12),
            Text(
              DateFormat('d MMM yyyy').format(_selectedDate),
              style: TextStyle(
                  fontSize: width * 0.04, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(double width) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category, style: TextStyle(fontSize: width * 0.04)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedCategory = value);
          }
        },
      ),
    );
  }

  Widget _buildParticipantsSection(double width) {
    return Column(
      children: [
        if (_selectedParticipants.isNotEmpty)
          Column(
            children: [
              // Selected participants with amount inputs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedParticipants.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.grey[200],
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final participantId = _selectedParticipants.toList()[index];
                    final participantName =
                        _friendNames[participantId] ?? 'Unknown';

                    // Create controller if it doesn't exist
                    if (!_participantControllers.containsKey(participantId)) {
                      _participantControllers[participantId] =
                          TextEditingController();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // Participant name with remove button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        participantName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedParticipants
                                              .remove(participantId);
                                          _participantAmounts
                                              .remove(participantId);
                                          _participantControllers[
                                                  participantId]!
                                              .dispose();
                                          _participantControllers
                                              .remove(participantId);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Amount input field
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller:
                                  _participantControllers[participantId]!,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _participantAmounts[participantId] =
                                      double.tryParse(value) ?? 0.0;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5E5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5E5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF39C12),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        GestureDetector(
          onTap: _showAddParticipantsDialog,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFF39C12),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFFF39C12),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Participants',
                  style: TextStyle(
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF39C12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Add Participants Bottom Sheet ───────────────────────────────────────────
  //
  // FIX: Replaced showGeneralDialog (unconstrained overlay) with
  // showModalBottomSheet + DraggableScrollableSheet. This gives the Column
  // a definite bounded height so Expanded / Flexible children resolve
  // correctly and no longer overflow.
  //
  // Inside the sheet:
  //  • Header, search bar, and section label are fixed (non-scrolling).
  //  • The friends list uses ListView with shrinkWrap: false and the sheet's
  //    own scrollController, so scrolling is handled by DraggableScrollableSheet.
  // ────────────────────────────────────────────────────────────────────────────
  void _showAddParticipantsDialog() {
    _searchController.clear();
    _searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // lets the sheet grow beyond 50 %
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false, // sheet sizes itself; no full-screen stretch
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C1A18),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  // Column has a definite height from DraggableScrollableSheet
                  child: Column(
                    children: [
                      // ── Drag Handle ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // ── Header ───────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add Participants',
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFF5F0EB),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Choose from your friends',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.4),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Search Bar ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Color(0xFFF5F0EB),
                              fontSize: 15,
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search friends...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.28),
                                fontSize: 15,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 14, right: 10),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color:
                                      const Color(0xFFF39C12).withOpacity(0.8),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 4,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── Section Label ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
                        child: Row(
                          children: [
                            Text(
                              'FRIENDS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Friends List (scrollable, fills remaining space) ──
                      //
                      // Expanded works here because DraggableScrollableSheet
                      // gives this Column a tight, finite height constraint.
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: friendsService.getFriends(_currentUserId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFFF39C12)),
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Something went wrong',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }

                            final friendships = snapshot.data ?? [];

                            if (friendships.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_outline_rounded,
                                        size: 38,
                                        color: Colors.white.withOpacity(0.15)),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No friends yet',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return FutureBuilder<Map<String, String>>(
                              future: _getFriendNames(friendships),
                              builder: (context, namesSnapshot) {
                                if (namesSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(0xFFF39C12)),
                                      strokeWidth: 2,
                                    ),
                                  );
                                }

                                final friendNames = namesSnapshot.data ?? {};

                                List<MapEntry<dynamic, String>>
                                    filteredFriends =
                                    friendships.map((friendship) {
                                  final friendId = friendship['requesterId'] ==
                                          _currentUserId
                                      ? friendship['receiverId']
                                      : friendship['requesterId'];
                                  return MapEntry(friendId,
                                      friendNames[friendId] ?? 'Unknown');
                                }).where((entry) {
                                  if (entry.key == _currentUserId) return false;
                                  if (_searchQuery.isEmpty) return true;
                                  return entry.value
                                      .toLowerCase()
                                      .contains(_searchQuery);
                                }).toList();

                                if (_searchQuery.isEmpty &&
                                    filteredFriends.length > 5) {
                                  filteredFriends =
                                      filteredFriends.sublist(0, 5);
                                }

                                if (filteredFriends.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No results for "$_searchQuery"',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.35),
                                      ),
                                    ),
                                  );
                                }

                                // shrinkWrap: false + scrollController from
                                // DraggableScrollableSheet = correct scroll
                                // behaviour with no overflow.
                                return ListView.separated(
                                  controller: scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 4, 20, 12),
                                  itemCount: filteredFriends.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final entry = filteredFriends[index];
                                    final friendId = entry.key;
                                    final friendName = entry.value;
                                    final isSelected = _selectedParticipants
                                        .contains(friendId);
                                    final initials = friendName.isNotEmpty
                                        ? friendName[0].toUpperCase()
                                        : '?';

                                    return GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          if (isSelected) {
                                            _selectedParticipants
                                                .remove(friendId);
                                          } else {
                                            _selectedParticipants.add(friendId);
                                          }
                                        });
                                        // Sync chip strip on the parent page
                                        setState(() {
                                          if (!isSelected) {
                                            _friendNames[friendId] = friendName;
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        curve: Curves.easeOut,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFF39C12)
                                                  .withOpacity(0.12)
                                              : Colors.white.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFF39C12)
                                                    .withOpacity(0.5)
                                                : Colors.white
                                                    .withOpacity(0.08),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFFF39C12)
                                                        .withOpacity(0.25)
                                                    : Colors.white
                                                        .withOpacity(0.09),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                initials,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? const Color(0xFFF39C12)
                                                      : Colors.white
                                                          .withOpacity(0.55),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 13),

                                            // Name
                                            Expanded(
                                              child: Text(
                                                friendName,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: isSelected
                                                      ? const Color(0xFFF5F0EB)
                                                      : Colors.white
                                                          .withOpacity(0.65),
                                                  letterSpacing: 0.1,
                                                ),
                                              ),
                                            ),

                                            // Checkmark
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: isSelected
                                                  ? Container(
                                                      key: const ValueKey(
                                                          'check'),
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFF39C12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7),
                                                      ),
                                                      child: const Icon(
                                                        Icons.check_rounded,
                                                        size: 15,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Container(
                                                      key: const ValueKey(
                                                          'empty'),
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.18),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // ── Bottom Action Bar ────────────────────────────────
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          12,
                          20,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Selected count badge
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _selectedParticipants.isEmpty
                                  ? const SizedBox.shrink()
                                  : Container(
                                      key: ValueKey(
                                          _selectedParticipants.length),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        '${_selectedParticipants.length} selected',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.55),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                            ),

                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF39C12),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF39C12)
                                            .withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  Future<Map<String, String>> _getFriendNames(
      List<Map<String, dynamic>> friendships) async {
    final friendNames = <String, String>{};
    final firestore = FirebaseFirestore.instance;

    for (final friendship in friendships) {
      final friendId = friendship['requesterId'] == _currentUserId
          ? friendship['receiverId']
          : friendship['requesterId'];

      try {
        final userDoc = await firestore.collection('Users').doc(friendId).get();
        if (userDoc.exists) {
          friendNames[friendId] = userDoc.data()?['username'] ?? 'Unknown';
        }
      } catch (e) {
        friendNames[friendId] = 'Unknown';
      }
    }

    return friendNames;
  }
}
