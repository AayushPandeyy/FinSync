import 'package:finance_tracker/models/SettlementRequest.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One row in a bill's settlement history.
///
/// Shows approve / reject only when the viewer is the payer and the request is
/// still open. Everyone else sees the same row as a record of what happened.
class SettlementRequestTile extends StatelessWidget {
  final SettlementRequest request;

  /// Display name of whoever asked to settle.
  final String requesterName;

  final String currencySymbol;

  /// True when the signed-in user is the payer, and so may resolve this.
  final bool canApprove;

  /// True when the signed-in user is the one who asked, and so may withdraw it.
  final bool canCancel;

  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const SettlementRequestTile({
    super.key,
    required this.request,
    required this.requesterName,
    required this.currencySymbol,
    this.canApprove = false,
    this.canCancel = false,
    this.isBusy = false,
    this.onApprove,
    this.onReject,
    this.onCancel,
  });

  static const _ink = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF999999);
  static const _label = Color(0xFF666666);
  static const _border = Color(0xFFE5E5E5);
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFE63946);
  static const _amber = Color(0xFFF39C12);

  /// A request the requester withdrew reads as "Withdrawn", not "Declined" —
  /// same stored status, different story.
  bool get _wasWithdrawn =>
      request.isRejected && request.resolvedBy == request.fromUid;

  Color get _statusColor {
    if (request.isPending) return _amber;
    if (request.isApproved) return _green;
    return _wasWithdrawn ? _muted : _red;
  }

  String get _statusLabel {
    if (request.isPending) return 'Awaiting approval';
    if (request.isApproved) return 'Approved';
    return _wasWithdrawn ? 'Withdrawn' : 'Declined';
  }

  IconData get _statusIcon {
    if (request.isPending) return Icons.schedule;
    if (request.isApproved) return Icons.check_circle_outline;
    return _wasWithdrawn ? Icons.undo : Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final showActions =
        request.isPending && (canApprove || canCancel);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: request.isPending ? _amber.withOpacity(0.45) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon, size: 18, color: _statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_statusLabel · ${DateFormat('d MMM, h:mm a').format(request.requestedAt)}',
                      style: TextStyle(fontSize: 12, color: _statusColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currencySymbol ${formatter.format(request.amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                request.note,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.35, color: _label),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            if (canApprove)
              Row(
                children: [
                  Expanded(
                    child: _outlineButton(
                      label: 'Decline',
                      color: _red,
                      onTap: isBusy ? null : onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _filledButton(
                      label: 'Approve',
                      color: _green,
                      onTap: isBusy ? null : onApprove,
                    ),
                  ),
                ],
              )
            else
              _outlineButton(
                label: 'Withdraw request',
                color: _label,
                onTap: isBusy ? null : onCancel,
              ),
          ],
        ],
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.45)),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _filledButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
