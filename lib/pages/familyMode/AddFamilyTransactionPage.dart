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

/// Books an income or expense against the family pot. Also handles editing —
/// pass [existing] to switch the form into edit mode.
class AddFamilyTransactionPage extends StatefulWidget {
  const AddFamilyTransactionPage({
    super.key,
    required this.family,
    this.transactionType = 'EXPENSE',
    this.existing,
  });

  final Family family;

  /// `INCOME` or `EXPENSE`. Ignored when [existing] is supplied.
  final String transactionType;

  final FamilyTransaction? existing;

  @override
  State<AddFamilyTransactionPage> createState() =>
      _AddFamilyTransactionPageState();
}

class _AddFamilyTransactionPageState extends State<AddFamilyTransactionPage> {
  static const Color _accent = Color(0xFFE67E22);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final FamilyFirestoreService _service = FamilyFirestoreService();

  late String _type;
  late DateTime _date;
  late String _category;

  bool _busy = false;
  bool _isLoadingDialogVisible = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _type = existing?.type ??
        (widget.transactionType == 'INCOME' ? 'INCOME' : 'EXPENSE');
    _date = existing?.date ?? DateTime.now();
    _category = existing?.category ?? _categoriesFor(_type).first.name;

    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toString();
      _descriptionController.text = existing.description;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConnectivityService.ensureConnected(
        context,
        actionDescription: 'add a family transaction',
        popCurrentRouteOnFailure: true,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Category> _categoriesFor(String type) => Categories().getCategories(type);

  void _setType(String type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      // Income and expense have disjoint category lists.
      _category = _categoriesFor(type).first.name;
    });
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
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!await ConnectivityService.ensureConnected(
      context,
      actionDescription: 'save a family transaction',
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

    try {
      if (_isEditing) {
        final existing = widget.existing!;
        await _service.updateTransaction(
          familyId: widget.family.id,
          transaction: FamilyTransaction(
            id: existing.id,
            title: _titleController.text.trim(),
            amount: amount,
            date: _date,
            description: _descriptionController.text.trim(),
            category: _category,
            type: _type,
            createdBy: existing.createdBy,
            createdByName: existing.createdByName,
            createdByDesignation: existing.createdByDesignation,
          ),
        );
      } else {
        // Stamp the author's name and designation onto the entry so the ledger
        // stays readable even if they later leave the family.
        final member =
            await _service.getMemberOnce(widget.family.id, user.uid);

        await _service.addTransaction(
          familyId: widget.family.id,
          transaction: FamilyTransaction(
            id: const Uuid().v4(),
            title: _titleController.text.trim(),
            amount: amount,
            date: _date,
            description: _descriptionController.text.trim(),
            category: _category,
            type: _type,
            createdBy: user.uid,
            createdByName: member?.username ?? (user.displayName ?? 'Member'),
            createdByDesignation: member?.designation ?? '',
          ),
        );
      }

      _hideLoadingDialog();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FamilyException catch (e) {
      _hideLoadingDialog();
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack(e.message);
    } catch (_) {
      _hideLoadingDialog();
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnack('Could not save the transaction. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesFor(_type);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: _isEditing ? 'Edit Family Entry' : 'Add Family Entry',
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
                _buildTypeToggle(),
                const SizedBox(height: 22),
                const _Label('Title'),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(
                    hint: _type == 'INCOME'
                        ? 'e.g. Monthly salary'
                        : 'e.g. Grocery run',
                    icon: Icons.title_rounded,
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Title is required'
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
                const _Label('Date'),
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
                          DateFormat.yMMMMd().format(_date),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const Icon(Icons.calendar_today, color: _accent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _Label('Category'),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: categories.map((category) {
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
                        color: selected ? Colors.white : const Color(0xFF374151),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const _Label('Note (optional)'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(
                    hint: 'Anything the rest of the family should know',
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: _accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This goes into ${widget.family.name}\'s shared '
                          'ledger — not your personal books.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
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
                      _isEditing ? 'Save changes' : 'Add to family',
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

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF0F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTypeButton(
            'INCOME',
            'Income',
            Icons.add_circle_outline_rounded,
            const Color(0xFF16A34A),
          ),
          _buildTypeButton(
            'EXPENSE',
            'Expense',
            Icons.remove_circle_outline_rounded,
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? color : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
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
