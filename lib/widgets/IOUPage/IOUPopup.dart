import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IOUDetailPopup extends StatelessWidget {
  final IOU iou;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSettle;

  const IOUDetailPopup({
    super.key,
    required this.iou,
    required this.onEdit,
    required this.onDelete,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isSettled = iou.status == IOUStatus.SETTLED;
    final isOverdue =
        iou.dueDate != null && iou.dueDate!.isBefore(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    iou.personName,
                    style: TextStyle(
                      fontSize: width * 0.052,
                      fontWeight: FontWeight.bold,
                      decoration: isSettled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: width * 0.04),

            // Amount
            Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: iou.iouType == IOUType.OWE
                    ? const Color(0xFFE63946).withOpacity(0.05)
                    : const Color(0xFF06D6A0).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: width * 0.038,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    'Rs ${iou.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: width * 0.048,
                      fontWeight: FontWeight.bold,
                      color: iou.iouType == IOUType.OWE
                          ? const Color(0xFFE63946)
                          : Colors.orangeAccent,
                      decoration: isSettled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: width * 0.04),

            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: iou.iouType == IOUType.OWE
                    ? const Color(0xFFE63946).withOpacity(0.1)
                    : const Color(0xFF06D6A0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                iou.iouType == IOUType.OWE ? 'I Owe' : 'Owes Me',
                style: TextStyle(
                  fontSize: width * 0.032,
                  fontWeight: FontWeight.w600,
                  color: iou.iouType == IOUType.OWE
                      ? const Color(0xFFE63946)
                      : const Color(0xFF06D6A0),
                ),
              ),
            ),
            SizedBox(height: width * 0.04),

            // Description
            _buildInfoRow('Description', iou.description, width),
            SizedBox(height: width * 0.03),

            // Date
            _buildInfoRow(
              'Date',
              DateFormat('MMM dd, yyyy').format(iou.date),
              width,
            ),
            SizedBox(height: width * 0.03),

            // Due Date
            if (iou.dueDate != null) ...[
              _buildInfoRow(
                'Due Date',
                DateFormat('MMM dd, yyyy').format(iou.dueDate!),
                width,
                valueColor:
                    isOverdue && !isSettled ? const Color(0xFFF57C00) : null,
              ),
              SizedBox(height: width * 0.03),
            ],

            // Status
            _buildInfoRow(
              'Status',
              isSettled ? 'Settled' : 'Pending',
              width,
              valueColor:
                  isSettled ? const Color(0xFF06D6A0) : const Color(0xFFF57C00),
            ),
            SizedBox(height: width * 0.06),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE63946),
                      side: const BorderSide(color: Color(0xFFE63946)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: width * 0.03),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onSettle();
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Settle Partially'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  foregroundColor: const Color(0xFF06D6A0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (!isSettled) ...[
              SizedBox(height: width * 0.03),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onSettle();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Settled'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06D6A0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double width,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width * 0.25,
          child: Text(
            label,
            style: TextStyle(
              fontSize: width * 0.036,
              color: const Color(0xFF999999),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: width * 0.036,
              fontWeight: FontWeight.w500,
              color: valueColor ?? const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}
