import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/service/SplitBillsFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SplitBillDetailPage extends StatefulWidget {
  final SplitBill splitBill;

  const SplitBillDetailPage({Key? key, required this.splitBill})
      : super(key: key);

  @override
  State<SplitBillDetailPage> createState() => _SplitBillDetailPageState();
}

class _SplitBillDetailPageState extends State<SplitBillDetailPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Future<Map<String, String>> _usernamesFuture;

  @override
  void initState() {
    super.initState();
    _usernamesFuture = _fetchUsernames();
    CurrencyService.initializeCurrency().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<Map<String, String>> _fetchUsernames() async {
    final Map<String, String> result = {};
    for (final uid in widget.splitBill.participants) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('Users').doc(uid).get();
        result[uid] = doc.data()?['username'] as String? ?? 'Unknown';
      } catch (_) {
        result[uid] = 'Unknown';
      }
    }
    return result;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '${CurrencyService.getCurrencySymbolSync()} ${formatter.format(amount)}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return Icons.restaurant;
      case 'travel':
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.electrical_services;
      case 'rent':
      case 'housing':
        return Icons.home;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.receipt_long;
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Split Bill',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this split bill? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF999999), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SplitBillsFirestoreService().deleteSplitBill(
                    widget.splitBill.paidBy, widget.splitBill.id);
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to delete. Please try again.')),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bill = widget.splitBill;
    final bool isPayer = bill.paidBy == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Nav Bar ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Bill Details',
                          style: TextStyle(
                            color: const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w700,
                            fontSize: width * 0.045,
                          ),
                        ),
                        const Text(
                          'Expense breakdown',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPayer)
                    GestureDetector(
                      onTap: _showDeleteDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline,
                            size: 20, color: Color(0xFFE63946)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<Map<String, String>>(
                future: _usernamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFF39C12)),
                    );
                  }

                  final usernames = snapshot.data ?? {};

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero Card ───────────────────────────────
                        _HeroCard(
                          bill: bill,
                          width: width,
                          categoryIcon: _categoryIcon(bill.category),
                          formatCurrency: _formatCurrency,
                        ),

                        const SizedBox(height: 16),

                        // ── Paid By ─────────────────────────────────
                        _InfoCard(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid by',
                                  style: TextStyle(
                                    color: const Color(0xFF999999),
                                    fontSize: width * 0.038,
                                  ),
                                ),
                                Text(
                                  usernames[bill.paidBy] ?? 'Unknown',
                                  style: TextStyle(
                                    color: const Color(0xFFF39C12),
                                    fontWeight: FontWeight.w600,
                                    fontSize: width * 0.038,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Who Owes What ───────────────────────────
                        Text(
                          'Who Owes What',
                          style: TextStyle(
                            color: const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                            fontSize: width * 0.038,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _InfoCard(
                          children: bill.splitAmounts.entries
                              .map((entry) => _ParticipantRow(
                                    uid: entry.key,
                                    amount: entry.value,
                                    username: usernames[entry.key] ?? 'Unknown',
                                    isPayer: entry.key == bill.paidBy,
                                    isCurrentUser: entry.key == currentUserId,
                                    formatCurrency: _formatCurrency,
                                    width: width,
                                  ))
                              .toList(),
                        ),

                        const SizedBox(height: 16),

                        // ── Summary Footer ──────────────────────────
                        Text(
                          'Split Summary',
                          style: TextStyle(
                            color: const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                            fontSize: width * 0.038,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SummaryCard(
                          bill: bill,
                          usernames: usernames,
                          formatCurrency: _formatCurrency,
                          width: width,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final SplitBill bill;
  final double width;
  final IconData categoryIcon;
  final String Function(double) formatCurrency;

  const _HeroCard({
    required this.bill,
    required this.width,
    required this.categoryIcon,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon,
                    color: const Color(0xFFF39C12), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        fontSize: width * 0.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM yyyy').format(bill.date),
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatCurrency(bill.totalAmount),
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w800,
              fontSize: width * 0.07,
            ),
          ),
          if (bill.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bill.description,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Text(
              bill.category,
              style: const TextStyle(
                color: Color(0xFFF39C12),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card wrapper ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _intersperse(
            children, const Divider(height: 20, color: Color(0xFFF0F0F0))),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return items;
    final result = <Widget>[items.first];
    for (int i = 1; i < items.length; i++) {
      result.add(separator);
      result.add(items[i]);
    }
    return result;
  }
}

// ── Participant Row ──────────────────────────────────────────────────────────

class _ParticipantRow extends StatelessWidget {
  final String uid;
  final double amount;
  final String username;
  final bool isPayer;
  final bool isCurrentUser;
  final String Function(double) formatCurrency;
  final double width;

  const _ParticipantRow({
    required this.uid,
    required this.amount,
    required this.username,
    required this.isPayer,
    required this.isCurrentUser,
    required this.formatCurrency,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final Color amountColor;
    final String label;
    final Color? rowTint;

    if (isPayer) {
      amountColor = const Color(0xFF2E7D32);
      label = 'You paid / Your share';
      rowTint = null;
    } else if (isCurrentUser) {
      amountColor = const Color(0xFFF39C12);
      label = 'Your share';
      rowTint = const Color(0xFFFFF8EE);
    } else {
      amountColor = const Color(0xFFE63946);
      label = '';
      rowTint = null;
    }

    Widget row = Row(
      children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isPayer
                ? const Color(0xFFE8F5E9)
                : isCurrentUser
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isPayer
                    ? const Color(0xFF2E7D32)
                    : isCurrentUser
                        ? const Color(0xFFF39C12)
                        : const Color(0xFF999999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: width * 0.038,
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        // Amount
        Text(
          formatCurrency(amount),
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.w700,
            fontSize: width * 0.038,
          ),
        ),
      ],
    );

    if (rowTint != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: rowTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: row,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: row,
    );
  }
}

// ── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SplitBill bill;
  final Map<String, String> usernames;
  final String Function(double) formatCurrency;
  final double width;

  const _SummaryCard({
    required this.bill,
    required this.usernames,
    required this.formatCurrency,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final participantCount = bill.participants.length;
    final totalAmount = bill.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total + Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                label: 'Total Amount',
                value: formatCurrency(totalAmount),
                valueColor: const Color(0xFF1A1A1A),
                width: width,
              ),
              _SummaryItem(
                label: 'Participants',
                value: '$participantCount people',
                valueColor: const Color(0xFFF39C12),
                width: width,
                alignRight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Share breakdown',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: width * 0.033,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Progress bars for each participant
          ...bill.splitAmounts.entries.map((entry) {
            final fraction = totalAmount > 0 ? entry.value / totalAmount : 0.0;
            final pct = (fraction * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        usernames[entry.key] ?? 'Unknown',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF39C12)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double width;
  final bool alignRight;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.width,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: width * 0.04,
          ),
        ),
      ],
    );
  }
}
