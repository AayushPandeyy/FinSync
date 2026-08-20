import 'package:finance_tracker/models/Family.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One row in a family ledger. Unlike the personal tile it always names the
/// member who booked the entry — that attribution is the point of family mode.
class FamilyTransactionTile extends StatelessWidget {
  const FamilyTransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.onTap,
    this.showDate = false,
  });

  final FamilyTransaction transaction;
  final String currency;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final color =
        isExpense ? const Color(0xFFE63946) : const Color(0xFF06D6A0);

    final byline = [
      transaction.category,
      transaction.createdByDesignation.isEmpty
          ? transaction.createdByName
          : '${transaction.createdByName} • ${transaction.createdByDesignation}',
      if (showDate) DateFormat.MMMd().format(transaction.date),
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExpense ? Icons.remove_circle : Icons.add_circle,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    byline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isExpense ? '−' : '+'} $currency '
              '${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
