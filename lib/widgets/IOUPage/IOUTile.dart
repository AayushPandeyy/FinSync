import 'package:finance_tracker/widgets/IOUPage/IOUPopup.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:intl/intl.dart';

// Updated IOUTile with popup
class IOUTile extends StatefulWidget {
  final IOU iou;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSettle;
  final VoidCallback onPartialSettle;

  /// Supplied for IOUs a split bill created. When present, tapping the tile
  /// opens the bill instead of the edit/settle popup — a split-linked IOU is
  /// owned by its bill and must not be settled privately, or the two sides of
  /// the mirror drift apart.
  final VoidCallback? onOpenSplitBill;

  const IOUTile(
      {super.key,
      required this.iou,
      required this.onEdit,
      required this.onDelete,
      required this.onSettle,
      required this.onPartialSettle,
      this.onOpenSplitBill});

  @override
  State<IOUTile> createState() => _IOUTileState();
}

class _IOUTileState extends State<IOUTile> {
  String _currencySymbol = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isSettled = widget.iou.status == IOUStatus.SETTLED;
    final isOverdue = widget.iou.dueDate != null &&
        widget.iou.dueDate!.isBefore(DateTime.now());
    final hasPartialSettlement = widget.iou.settledAmount > 0 && !isSettled;
    final remaining = widget.iou.amount - widget.iou.settledAmount;
    final progress = widget.iou.amount > 0
        ? (widget.iou.settledAmount / widget.iou.amount).clamp(0.0, 1.0)
        : 0.0;

    Color getStatusColor() {
      if (isSettled) return const Color(0xFF4A90E2); // Blue for settled
      if (isOverdue) return const Color(0xFFF57C00); // Orange for overdue
      return const Color(0xFFF57C00); // Pending
    }

    String getStatusText() {
      if (isSettled) return 'Settled';
      if (hasPartialSettlement) return 'Partial';
      if (isOverdue) return 'Overdue';
      return 'Pending';
    }

    Color getStatusBadgeColor() {
      if (isSettled) return const Color(0xFF4A90E2);
      if (hasPartialSettlement) return const Color(0xFF4A90E2);
      if (isOverdue) return const Color(0xFFF57C00);
      return const Color(0xFFF57C00);
    }

    final isSplitLinked = widget.iou.isSplitLinked;
    final awaitingApproval = widget.iou.hasPendingApproval;

    return GestureDetector(
      onTap: () {
        if (isSplitLinked && widget.onOpenSplitBill != null) {
          widget.onOpenSplitBill!();
          return;
        }
        showDialog(
          context: context,
          builder: (context) => IOUDetailPopup(
            iou: widget.iou,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onSettle: widget.onSettle,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.015),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSettled
                ? const Color(0xFFE5E5E5)
                : (isOverdue
                    ? const Color(0xFFF57C00).withOpacity(0.3)
                    : const Color(0xFFE5E5E5)),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // --- Left: Person info ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.iou.personName,
                          style: TextStyle(
                              fontSize: width * 0.042,
                              fontWeight: FontWeight.w600,
                              decoration: isSettled
                                  ? TextDecoration.lineThrough
                                  : null)),
                      SizedBox(height: width * 0.01),
                      Text(widget.iou.description,
                          style: TextStyle(
                              fontSize: width * 0.032,
                              color: const Color(0xFF999999)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (isSplitLinked) ...[
                        SizedBox(height: width * 0.015),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39C12).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_split,
                                  size: width * 0.03,
                                  color: const Color(0xFFF39C12)),
                              const SizedBox(width: 4),
                              Text(
                                'Split bill',
                                style: TextStyle(
                                  fontSize: width * 0.026,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF39C12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // --- Right: Amount + Type + Status ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Amount
                    Text(
                      '$_currencySymbol ${widget.iou.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: widget.iou.iouType == IOUType.OWE
                            ? const Color(0xFFE63946)
                            : const Color(0xFF06D6A0),
                        fontSize: width * 0.042,
                        fontWeight: FontWeight.w600,
                        decoration:
                            isSettled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // IOU Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.iou.iouType == IOUType.OWE
                            ? const Color(0xFFE63946).withOpacity(0.1)
                            : const Color(0xFF06D6A0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.iou.iouType == IOUType.OWE ? 'I Owe' : 'Owes Me',
                        style: TextStyle(
                            fontSize: width * 0.028,
                            fontWeight: FontWeight.w600,
                            color: widget.iou.iouType == IOUType.OWE
                                ? const Color(0xFFE63946)
                                : const Color(0xFF06D6A0)),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // --- Status badge ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: getStatusBadgeColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        getStatusText(),
                        style: TextStyle(
                          fontSize: width * 0.028,
                          fontWeight: FontWeight.w600,
                          color: getStatusBadgeColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // --- Awaiting the payer's approval ---
            if (awaitingApproval) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Color(0xFFF39C12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_currencySymbol ${widget.iou.pendingSettleAmount.toStringAsFixed(0)} awaiting approval',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A6114),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --- Settlement progress bar ---
            if (hasPartialSettlement) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE5E5E5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4A90E2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settled: $_currencySymbol ${widget.iou.settledAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: width * 0.028,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                  Text(
                    'Remaining: $_currencySymbol ${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: width * 0.028,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
