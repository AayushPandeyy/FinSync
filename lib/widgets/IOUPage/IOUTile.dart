import 'package:finance_tracker/widgets/IOUPage/IOUPopup.dart';
import 'package:flutter/material.dart';
import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:intl/intl.dart';

// Updated IOUTile with popup
class IOUTile extends StatelessWidget {
  final IOU iou;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSettle;
  final VoidCallback onPartialSettle;

  const IOUTile({
    super.key,
    required this.iou,
    required this.onEdit,
    required this.onDelete,
    required this.onSettle,
    required this.onPartialSettle
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isSettled = iou.status == IOUStatus.SETTLED;
    final isOverdue =
        iou.dueDate != null && iou.dueDate!.isBefore(DateTime.now());

    Color getStatusColor() {
      if (isSettled) return const Color(0xFF4A90E2); // Blue for settled
      if (isOverdue) return const Color(0xFFF57C00); // Orange for overdue
      return const Color(0xFFF57C00); // Green for pending
    }

    String getStatusText() {
      if (isSettled) return 'Settled';
      if (isOverdue) return 'Overdue';
      return 'Pending';
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => IOUDetailPopup(
            
            iou: iou,
            onEdit: onEdit,
            onDelete: onDelete,
            onSettle: onSettle,
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
        child: Row(
          children: [
            // --- Left: Person info ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(iou.personName,
                      style: TextStyle(
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.w600,
                          decoration:
                              isSettled ? TextDecoration.lineThrough : null)),
                  SizedBox(height: width * 0.01),
                  Text(iou.description,
                      style: TextStyle(
                          fontSize: width * 0.032,
                          color: const Color(0xFF999999)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // --- Right: Amount + Type + Status ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount
                Text(
                  'Rs ${iou.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: iou.iouType == IOUType.OWE
                        ? const Color(0xFFE63946)
                        : const Color(0xFF06D6A0),
                    fontSize: width * 0.042,
                    fontWeight: FontWeight.w600,
                    decoration: isSettled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),

                // IOU Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: iou.iouType == IOUType.OWE
                        ? const Color(0xFFE63946).withOpacity(0.1)
                        : const Color(0xFF06D6A0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    iou.iouType == IOUType.OWE ? 'I Owe' : 'Owes Me',
                    style: TextStyle(
                        fontSize: width * 0.028,
                        fontWeight: FontWeight.w600,
                        color: iou.iouType == IOUType.OWE
                            ? const Color(0xFFE63946)
                            : const Color(0xFF06D6A0)),
                  ),
                ),

                const SizedBox(height: 4),

                // --- Status badge ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    getStatusText(),
                    style: TextStyle(
                      fontSize: width * 0.028,
                      fontWeight: FontWeight.w600,
                      color: getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
