import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/widgets/homePage/TransactionDetailPopUp.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// Design tokens
class _DT {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F4);
  static const border = Color(0xFFE7E5E4);
  static const textPrimary = Color(0xFF1C1917);
  static const textSecondary = Color(0xFF78716C);
  static const success = Color(0xFF16A34A);
  static const successSurface = Color(0xFFF0FDF4);
  static const danger = Color(0xFFDC2626);
  static const dangerSurface = Color(0xFFFEF2F2);
  static const warning = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFFFBEB);
  static const btnText = Color(0xFFFFFFFF);

  static const radius = 20.0;
  static const radiusSm = 12.0;
}

class DialogBox {
  // ─── Success / Failure ───────────────────────────────────────────────────
  Future<void> showMessageDialog(
    BuildContext context, {
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    final color = isSuccess ? _DT.success : _DT.danger;
    final surfaceColor = isSuccess ? _DT.successSurface : _DT.dangerSurface;
    final icon =
        isSuccess ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _DT.bg,
            borderRadius: BorderRadius.circular(_DT.radius),
            border: Border.all(color: _DT.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon chip
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _DT.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: _DT.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _FilledButton(
                label: 'OK',
                color: color,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Confirmation ─────────────────────────────────────────────────────────
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final confirmColor = isDangerous ? _DT.danger : _DT.success;
    final iconColor = isDangerous ? _DT.danger : _DT.warning;
    final iconSurface = isDangerous ? _DT.dangerSurface : _DT.warningSurface;
    final icon =
        isDangerous ? Icons.delete_outline_rounded : Icons.help_outline_rounded;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _DT.bg,
            borderRadius: BorderRadius.circular(_DT.radius),
            border: Border.all(color: _DT.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon chip
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _DT.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: _DT.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      label: cancelText,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilledButton(
                      label: confirmText,
                      color: confirmColor,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  // ─── Loading ──────────────────────────────────────────────────────────────
  void showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      useRootNavigator: true,
      context: context,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (pop, res) => false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Center(
            child: LoadingAnimationWidget.twistingDots(
              leftDotColor: const Color(0xFF1A1A3F),
              rightDotColor: const Color(0xFFEA3799),
              size: 100,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Transaction Detail ───────────────────────────────────────────────────
  void showTransactionDetailPopUp(
      BuildContext context, TransactionModel transaction, IconData icon) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: TransactionDetailPopUp(
          icon: icon,
          title: transaction.title,
          amount: transaction.amount.toString(),
          date: transaction.date,
          description: transaction.transactionDescription,
          category: transaction.category,
          type: transaction.type,
        ),
      ),
    );
  }
}

// ─── Shared button widgets ────────────────────────────────────────────────────

class _FilledButton extends StatelessWidget {
  const _FilledButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_DT.radiusSm),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _DT.btnText,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _DT.surface,
          borderRadius: BorderRadius.circular(_DT.radiusSm),
          border: Border.all(color: _DT.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _DT.textSecondary,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
