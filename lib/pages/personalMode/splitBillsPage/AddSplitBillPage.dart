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

  // Participant state
  Set<String> _selectedParticipants = {};
  Map<String, String> _friendNames = {};

  // splitAmounts[uid] = how much that person owes the payer.
  // Includes the payer themselves (their own share of the bill).
  Map<String, double> _splitAmounts = {};
  Map<String, TextEditingController> _participantControllers = {};

  // When true, amounts are kept equal automatically.
  bool _isEqualSplit = true;

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

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Keep the payer's own share tracked from the start.
    _splitAmounts[_currentUserId] = 0.0;

    // Recompute equal split whenever the total amount field changes.
    _amountController.addListener(_onAmountChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _guardOfflineEntry());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    for (final c in _participantControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Connectivity guard ───────────────────────────────────────────────────

  Future<void> _guardOfflineEntry() async {
    await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a split bill',
      popCurrentRouteOnFailure: true,
    );
  }

  // ─── Splitting logic ──────────────────────────────────────────────────────

  /// Full list of people sharing this bill: payer + selected friends.
  List<String> get _allParticipants =>
      [_currentUserId, ..._selectedParticipants];

  /// Equal share per person (rounded to 2 dp; last person absorbs rounding).
  double _equalShare(double total, int count) {
    if (count == 0) return 0;
    return double.parse((total / count).toStringAsFixed(2));
  }

  /// Called whenever the total amount field changes (only in equal-split mode).
  void _onAmountChanged() {
    if (_isEqualSplit) _applyEqualSplit();
  }

  /// Distributes the total evenly across all participants and updates both
  /// [_splitAmounts] and every participant's text controller.
  void _applyEqualSplit() {
    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final count = _allParticipants.length;
    final share = _equalShare(total, count);

    setState(() {
      for (final uid in _allParticipants) {
        _splitAmounts[uid] = share;
        _participantControllers[uid]?.text =
            share > 0 ? share.toStringAsFixed(2) : '';
      }

      // Absorb rounding difference in the payer's own share.
      if (count > 0) {
        final friendsTotal = _selectedParticipants.fold(
            0.0, (sum, uid) => sum + (_splitAmounts[uid] ?? 0.0));
        _splitAmounts[_currentUserId] =
            double.parse((total - friendsTotal).toStringAsFixed(2));
      }
    });
  }

  /// Switches between equal-split and manual modes.
  void _toggleSplitMode(bool equalSplit) {
    setState(() {
      _isEqualSplit = equalSplit;
      if (equalSplit) {
        _applyEqualSplit();
      } else {
        // In manual mode clear all fields so the user starts fresh.
        for (final uid in _allParticipants) {
          _splitAmounts[uid] = 0.0;
          _participantControllers[uid]?.text = '';
        }
      }
    });
  }

  /// Called when a friend is added or removed; keeps the split consistent.
  void _onParticipantsChanged() {
    // Ensure a controller exists for every participant (including payer).
    for (final uid in _allParticipants) {
      _participantControllers.putIfAbsent(uid, () => TextEditingController());
    }

    if (_isEqualSplit) {
      _applyEqualSplit();
    } else {
      // In manual mode just zero out any newly-added participant.
      for (final uid in _allParticipants) {
        _splitAmounts.putIfAbsent(uid, () => 0.0);
      }
    }
  }

  // ─── Validation helpers ───────────────────────────────────────────────────

  /// Returns a user-facing error string or null if everything is valid.
  String? _validateSplits(double total) {
    if (_selectedParticipants.isEmpty) {
      return 'Please select at least one participant';
    }

    final sumOfFriendShares = _selectedParticipants.fold(
        0.0, (sum, uid) => sum + (_splitAmounts[uid] ?? 0.0));

    if (!_isEqualSplit) {
      // In manual mode the friend shares must not exceed the total.
      if (sumOfFriendShares > total + 0.01) {
        return 'Sum of participant amounts (${sumOfFriendShares.toStringAsFixed(2)}) exceeds total (${total.toStringAsFixed(2)})';
      }
      // Warn if no amounts have been entered at all.
      if (sumOfFriendShares == 0.0) {
        return 'Please enter at least one participant amount';
      }
    }

    return null;
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveSplitBill() async {
    final canProceed = await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'add a split bill',
    );
    if (!canProceed) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final total = double.parse(_amountController.text.trim());

    final validationError = _validateSplits(total);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    _showLoadingDialog();

    try {
      // Build the final splitAmounts map.
      // friend share  = what they owe the payer.
      // payer share   = their own portion (total − sum of friend shares).
      final Map<String, double> finalSplitAmounts = {};

      final sumOfFriendShares = _selectedParticipants.fold(
          0.0, (sum, uid) => sum + (_splitAmounts[uid] ?? 0.0));

      // Payer's own share is whatever is left after friends' portions.
      finalSplitAmounts[_currentUserId] =
          double.parse((total - sumOfFriendShares).toStringAsFixed(2));

      for (final uid in _selectedParticipants) {
        finalSplitAmounts[uid] =
            double.parse((_splitAmounts[uid] ?? 0.0).toStringAsFixed(2));
      }

      final splitBill = SplitBill(
        id: const Uuid().v1(),
        title: _titleController.text.trim(),
        totalAmount: total,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        paidBy: _currentUserId,
        splitAmounts: finalSplitAmounts,
        category: _selectedCategory,
        participants: _allParticipants,
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

  // ─── Dialog helpers ───────────────────────────────────────────────────────

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
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: background,
      ));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFF39C12),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
            // Nav bar
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
                          'Add Split Bill',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF1A1A1A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Divide expenses with friends',
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

            // Form
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
                        validator: (v) => (v == null || v.isEmpty)
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
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter amount';
                          }
                          final parsed = double.tryParse(v);
                          if (parsed == null) {
                            return 'Enter a valid number';
                          }
                          if (parsed <= 0) {
                            return 'Amount must be greater than 0';
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

  // ─── UI helpers ───────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, double width) => Text(
        title,
        style: TextStyle(fontSize: width * 0.038, fontWeight: FontWeight.w600),
      );

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
        items: _categories
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: TextStyle(fontSize: width * 0.04)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedCategory = v);
        },
      ),
    );
  }

  // ─── Participants section ─────────────────────────────────────────────────

  Widget _buildParticipantsSection(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedParticipants.isNotEmpty) ...[
          // ── Split mode toggle ──────────────────────────────────────────
          _buildSplitModeToggle(width),
          const SizedBox(height: 12),

          // ── Summary row ────────────────────────────────────────────────
          _buildSplitSummary(width),
          const SizedBox(height: 12),

          // ── Per-participant rows ───────────────────────────────────────
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
                  endIndent: 16),
              itemBuilder: (context, index) {
                final uid = _selectedParticipants.toList()[index];
                return _buildParticipantRow(uid, width);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Add participants button ─────────────────────────────────────
        GestureDetector(
          onTap: _showAddParticipantsDialog,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF39C12), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline,
                    color: Color(0xFFF39C12), size: 20),
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

  /// Toggle between "Split Equally" and "Custom" modes.
  Widget _buildSplitModeToggle(double width) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _splitModeTab('Split Equally', _isEqualSplit,
              () => _toggleSplitMode(true), width),
          _splitModeTab(
              'Custom', !_isEqualSplit, () => _toggleSplitMode(false), width),
        ],
      ),
    );
  }

  Widget _splitModeTab(
      String label, bool active, VoidCallback onTap, double width) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: width * 0.035,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? const Color(0xFFF39C12) : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows total vs sum-of-shares so the user knows if there's a remainder.
  Widget _buildSplitSummary(double width) {
    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final assigned = _selectedParticipants.fold(
        0.0, (sum, uid) => sum + (_splitAmounts[uid] ?? 0.0));
    final payerShare = double.parse((total - assigned).toStringAsFixed(2));
    final remaining = double.parse((total - assigned).toStringAsFixed(2));
    final isBalanced = remaining.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isBalanced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBalanced ? const Color(0xFF81C784) : const Color(0xFFF39C12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your share',
                style:
                    TextStyle(fontSize: width * 0.032, color: Colors.grey[600]),
              ),
              Text(
                payerShare >= 0 ? payerShare.toStringAsFixed(2) : '—',
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isBalanced ? 'Fully assigned' : 'Unassigned',
                style: TextStyle(
                    fontSize: width * 0.032,
                    color: isBalanced
                        ? const Color(0xFF2E7D32)
                        : Colors.orange[800]),
              ),
              Text(
                isBalanced ? '✓' : remaining.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.w700,
                  color:
                      isBalanced ? const Color(0xFF2E7D32) : Colors.orange[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(String uid, double width) {
    final name = _friendNames[uid] ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    _participantControllers.putIfAbsent(uid, () => TextEditingController());

    // Keep controller text in sync when in equal-split mode.
    final currentAmount = _splitAmounts[uid] ?? 0.0;
    final controller = _participantControllers[uid]!;
    if (_isEqualSplit) {
      final formatted =
          currentAmount > 0 ? currentAmount.toStringAsFixed(2) : '';
      if (controller.text != formatted) {
        controller.text = formatted;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF39C12))),
          ),
          const SizedBox(width: 10),

          // Name + "owes you" label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A))),
                Text('owes you',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),

          // Amount input
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              readOnly: _isEqualSplit,
              onChanged: _isEqualSplit
                  ? null
                  : (value) {
                      setState(() {
                        final parsed = double.tryParse(value) ?? 0.0;
                        _splitAmounts[uid] = parsed < 0 ? 0.0 : parsed;
                      });
                    },
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: _isEqualSplit,
                fillColor:
                    _isEqualSplit ? const Color(0xFFF5F5F5) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFF39C12), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // Remove button
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedParticipants.remove(uid);
                _splitAmounts.remove(uid);
                _participantControllers[uid]?.dispose();
                _participantControllers.remove(uid);
                _onParticipantsChanged();
              });
            },
            child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─── Add Participants Bottom Sheet ────────────────────────────────────────

  void _showAddParticipantsDialog() {
    _searchController.clear();
    _searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C1A18),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
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

                      // Header
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
                                child: Icon(Icons.close_rounded,
                                    size: 18,
                                    color: Colors.white.withOpacity(0.55)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                color: Color(0xFFF5F0EB), fontSize: 15),
                            onChanged: (v) => setDialogState(
                                () => _searchQuery = v.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: 'Search friends...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.28),
                                fontSize: 15,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 14, right: 10),
                                child: Icon(Icons.search_rounded,
                                    size: 20,
                                    color: const Color(0xFFF39C12)
                                        .withOpacity(0.8)),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 44, minHeight: 44),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Section label
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

                      // Friends list
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: friendsService.getFriends(_currentUserId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(0xFFF39C12)),
                                      strokeWidth: 2));
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Something went wrong',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 14)));
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
                                    Text('No friends yet',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white
                                                .withOpacity(0.35))),
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
                                          strokeWidth: 2));
                                }

                                final friendNames = namesSnapshot.data ?? {};

                                var filtered = friendships
                                    .map((f) {
                                      final fid =
                                          f['requesterId'] == _currentUserId
                                              ? f['receiverId']
                                              : f['requesterId'];
                                      return MapEntry(
                                          fid, friendNames[fid] ?? 'Unknown');
                                    })
                                    .where((e) =>
                                        e.key != _currentUserId &&
                                        (_searchQuery.isEmpty ||
                                            e.value
                                                .toLowerCase()
                                                .contains(_searchQuery)))
                                    .toList();

                                if (filtered.isEmpty) {
                                  return Center(
                                      child: Text(
                                          'No results for "$_searchQuery"',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white
                                                  .withOpacity(0.35))));
                                }

                                return ListView.separated(
                                  controller: scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 4, 20, 12),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final entry = filtered[i];
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
                                            _splitAmounts.remove(friendId);
                                            _participantControllers[friendId]
                                                ?.dispose();
                                            _participantControllers
                                                .remove(friendId);
                                          } else {
                                            _selectedParticipants.add(friendId);
                                            _friendNames[friendId] = friendName;
                                          }
                                        });
                                        setState(() {
                                          _friendNames[friendId] = friendName;
                                          _onParticipantsChanged();
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
                                              child: Text(initials,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFF39C12)
                                                        : Colors.white
                                                            .withOpacity(0.55),
                                                  )),
                                            ),
                                            const SizedBox(width: 13),
                                            Expanded(
                                              child: Text(friendName,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFFF5F0EB)
                                                        : Colors.white
                                                            .withOpacity(0.65),
                                                    letterSpacing: 0.1,
                                                  )),
                                            ),
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
                                                          color: Colors.white))
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

                      // Bottom action bar
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
                                  color: Colors.white.withOpacity(0.07))),
                        ),
                        child: Row(
                          children: [
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
                                            color:
                                                Colors.white.withOpacity(0.1)),
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
                                  child: const Text('Confirm',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      )),
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
    ).then((_) => setState(() {}));
  }

  // ─── Firestore helpers ────────────────────────────────────────────────────

  Future<Map<String, String>> _getFriendNames(
      List<Map<String, dynamic>> friendships) async {
    final result = <String, String>{};
    final firestore = FirebaseFirestore.instance;
    for (final f in friendships) {
      final fid = f['requesterId'] == _currentUserId
          ? f['receiverId']
          : f['requesterId'];
      try {
        final doc = await firestore.collection('Users').doc(fid).get();
        if (doc.exists) {
          result[fid] = doc.data()?['username'] ?? 'Unknown';
        }
      } catch (_) {
        result[fid] = 'Unknown';
      }
    }
    return result;
  }
}
