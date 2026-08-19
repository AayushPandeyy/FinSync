import 'package:finance_tracker/models/Family.dart';
import 'package:finance_tracker/pages/familyMode/AddFamilyTransactionPage.dart';
import 'package:finance_tracker/service/FamilyFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:finance_tracker/widgets/familyMode/FamilyTransactionTile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The full shared ledger, filterable by type and by member.
class FamilyTransactionsPage extends StatefulWidget {
  const FamilyTransactionsPage({super.key, required this.family});

  final Family family;

  @override
  State<FamilyTransactionsPage> createState() => _FamilyTransactionsPageState();
}

class _FamilyTransactionsPageState extends State<FamilyTransactionsPage> {
  static const Color _accent = Color(0xFFE67E22);

  final FamilyFirestoreService _service = FamilyFirestoreService();

  /// `null` means "everything".
  String? _typeFilter;
  String? _memberFilter;

  String get _currency => CurrencyService.getCurrencySymbolSync();

  bool _canManage(FamilyTransaction transaction) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    // Your own entries, or anything if you run the family.
    return transaction.createdBy == uid || widget.family.isAdmin(uid);
  }

  Future<void> _openDetail(FamilyTransaction transaction) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _TransactionDetailSheet(
        transaction: transaction,
        currency: _currency,
        canManage: _canManage(transaction),
        onEdit: () {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFamilyTransactionPage(
                family: widget.family,
                existing: transaction,
              ),
            ),
          );
        },
        onDelete: () async {
          Navigator.pop(sheetContext);
          await _delete(transaction);
        },
      ),
    );
  }

  Future<void> _delete(FamilyTransaction transaction) async {
    final confirmed = await DialogBox().showConfirmationDialog(
      context,
      title: 'Delete entry',
      message: 'This removes "${transaction.title}" from the family ledger and '
          'adjusts the shared totals.',
      confirmText: 'Delete',
      isDangerous: true,
    );
    if (!confirmed) return;

    try {
      await _service.deleteTransaction(
        familyId: widget.family.id,
        transaction: transaction,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Entry deleted.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Could not delete the entry.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Family Ledger',
        subtitle: widget.family.name,
        useCustomDesign: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddFamilyTransactionPage(family: widget.family),
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: StreamBuilder<List<FamilyTransaction>>(
                stream: _service.getTransactions(widget.family.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final all = snapshot.data ?? const <FamilyTransaction>[];
                  final filtered = all.where((tx) {
                    if (_typeFilter != null && tx.type != _typeFilter) {
                      return false;
                    }
                    if (_memberFilter != null &&
                        tx.createdBy != _memberFilter) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _EmptyState(
                      hasFilters:
                          _typeFilter != null || _memberFilter != null,
                    );
                  }

                  return _buildGroupedList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Groups by day so a long ledger stays scannable.
  Widget _buildGroupedList(List<FamilyTransaction> transactions) {
    final groups = <String, List<FamilyTransaction>>{};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      groups.putIfAbsent(key, () => []).add(tx);
    }

    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final items = groups[key]!;
        final date = DateTime.parse(key);

        final dayTotal = items.fold<double>(
          0,
          (sum, tx) => sum + (tx.isExpense ? -tx.amount : tx.amount),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDayLabel(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '${dayTotal >= 0 ? '+' : '−'} $_currency '
                    '${dayTotal.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dayTotal >= 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    FamilyTransactionTile(
                      transaction: items[i],
                      currency: _currency,
                      onTap: () => _openDetail(items[i]),
                    ),
                    if (i != items.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.grey.withOpacity(0.12),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildTypeChip(null, 'All'),
              const SizedBox(width: 8),
              _buildTypeChip('INCOME', 'Income'),
              const SizedBox(width: 8),
              _buildTypeChip('EXPENSE', 'Expense'),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<FamilyMember>>(
            stream: _service.getMembers(widget.family.id),
            builder: (context, snapshot) {
              final members = snapshot.data ?? const <FamilyMember>[];
              if (members.length < 2) return const SizedBox.shrink();

              return SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildMemberChip(null, 'Everyone'),
                    ...members.map(
                      (member) => _buildMemberChip(
                        member.uid,
                        member.username,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String? type, String label) {
    final selected = _typeFilter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberChip(String? uid, String label) {
    final selected = _memberFilter == uid;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _memberFilter = uid),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withOpacity(0.14)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? _accent : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({
    required this.transaction,
    required this.currency,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyTransaction transaction;
  final String currency;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final color = isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                transaction.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${isExpense ? '−' : '+'} $currency '
                '${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.person_rounded,
                label: 'Added by',
                value: transaction.createdByDesignation.isEmpty
                    ? transaction.createdByName
                    : '${transaction.createdByName} '
                        '(${transaction.createdByDesignation})',
              ),
              _DetailRow(
                icon: Icons.category_rounded,
                label: 'Category',
                value: transaction.category,
              ),
              _DetailRow(
                icon: Icons.event_rounded,
                label: 'Date',
                value: DateFormat.yMMMMd().format(transaction.date),
              ),
              if (transaction.description.isNotEmpty)
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Note',
                  value: transaction.description,
                ),
              if (canManage) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9AA3AF)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(39),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 34,
              color: Color(0xFF9AA3AF),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilters ? 'Nothing matches those filters' : 'No family entries yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try widening the type or member filter.'
                : 'Add the first shared income or expense.',
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF9AA3AF)),
          ),
        ],
      ),
    );
  }
}
