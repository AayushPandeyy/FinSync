import 'package:finance_tracker/models/Category.dart';
import 'package:finance_tracker/models/Family.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/FamilyFirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Adds or edits a shared recurring bill. `paidBy` records which member picks
/// up the tab so the family can see who is carrying which subscription.
class AddFamilySubscriptionPage extends StatefulWidget {
  const AddFamilySubscriptionPage({
    super.key,
    required this.family,
    this.existing,
  });

  final Family family;
  final FamilySubscription? existing;

  @override
  State<AddFamilySubscriptionPage> createState() =>
      _AddFamilySubscriptionPageState();
}

class _AddFamilySubscriptionPageState extends State<AddFamilySubscriptionPage> {
  static const Color _accent = Color(0xFFE67E22);
  static const List<String> _billingCycles = ['Monthly', 'Yearly', 'Weekly'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  final FamilyFirestoreService _service = FamilyFirestoreService();
  final List<Category> _categories = Categories().getCategories('EXPENSE');

  late String _billingCycle;
  late DateTime _nextBillingDate;
  late String _category;

  String? _paidByUid;
  String _paidByName = 'Family';

  bool _busy = false;
  bool _isLoadingDialogVisible = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _billingCycle = existing?.billingCycle ?? 'Monthly';
    _nextBillingDate = existing?.nextBillingDate ??
        DateTime.now().add(const Duration(days: 30));
    _category = existing?.category ?? 'Subscriptions';
    _paidByUid = existing?.paidByUid.isEmpty ?? true
        ? FirebaseAuth.instance.currentUser?.uid
        : existing!.paidByUid;
    _paidByName = existing?.paidByName ?? 'Family';

    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.amount.toString();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConnectivityService.ensureConnected(
        context,
        actionDescription: 'manage family subscriptions',
        popCurrentRouteOnFailure: true,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _nextBillingDate = picked);
  }

  Future<void> _save() async {
    if (!await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'save a family subscription',
    )) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount.');
      return;
    }

    setState(() => _busy = true);
    _showLoadingDialog();

    final subscription = FamilySubscription(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      amount: amount,
      billingCycle: _billingCycle,
      nextBillingDate: _nextBillingDate,
      category: _category,
      isActive: widget.existing?.isActive ?? true,
      paidByUid: _paidByUid ?? '',
      paidByName: _paidByName,
      createdBy: widget.existing?.createdBy ?? user.uid,
    );

    try {
      if (_isEditing) {
        await _service.updateSubscription(
          familyId: widget.family.id,
          subscription: subscription,
        );
      } else {
        await _service.addSubscription(
          familyId: widget.family.id,
          subscription: subscription,
        );
      }

      _hideLoadingDialog();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _hideLoadingDialog();
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Could not save the subscription. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: _isEditing ? 'Edit Subscription' : 'Add Subscription',
        subtitle: widget.family.name,
        useCustomDesign: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Subscription name'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    hint: 'e.g. Netflix, Electricity',
                    icon: Icons.subscriptions_rounded,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 20),
                const _Label('Amount'),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration(
                    hint: '0.00',
                    icon: Icons.payments_rounded,
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
                const _Label('Billing cycle'),
                Row(
                  children: _billingCycles.map((cycle) {
                    final selected = _billingCycle == cycle;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _billingCycle = cycle),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _accent
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              cycle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const _Label('Next billing date'),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat.yMMMMd().format(_nextBillingDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const Icon(Icons.calendar_today, color: _accent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _Label('Paid by'),
                _buildPaidByPicker(),
                const SizedBox(height: 20),
                const _Label('Category'),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: _categories.map((category) {
                    final selected = _category == category.name;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 14,
                            color: selected ? Colors.white : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(category.name),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _category = category.name),
                      selectedColor: _accent,
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color:
                            selected ? Colors.white : const Color(0xFF374151),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor: _accent.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Save changes' : 'Add subscription',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildPaidByPicker() {
    return StreamBuilder<List<FamilyMember>>(
      stream: _service.getMembers(widget.family.id),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <FamilyMember>[];
        if (members.isEmpty) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // Default to whoever is adding it, once the roster has loaded.
        if (_paidByName == 'Family' && _paidByUid != null) {
          final self = members.where((m) => m.uid == _paidByUid);
          if (self.isNotEmpty) {
            _paidByName = self.first.username;
          }
        }

        return Wrap(
          spacing: 6,
          runSpacing: 2,
          children: members.map((member) {
            final selected = _paidByUid == member.uid;
            return ChoiceChip(
              label: Text('${member.username} (${member.designation})'),
              selected: selected,
              onSelected: (_) => setState(() {
                _paidByUid = member.uid;
                _paidByName = member.username;
              }),
              selectedColor: _accent,
              backgroundColor: const Color(0xFFF3F4F6),
              side: BorderSide.none,
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

InputDecoration _decoration({required String hint, required IconData icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF9AA3AF)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
