import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/widgets/homePage/TransactionDetailPopUp.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DialogBox {
  // Success/Failure Message Dialog - money-minded design
  void showMessageDialog(
    BuildContext context, {
    required bool isSuccess,
    required String title,
    required String message,
  }) {
    final color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isSuccess ? Icons.check_circle : Icons.error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title with money-minded font
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // OK Button with gradient
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Confirmation Dialog - money-minded design
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF9FAFB),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDangerous
                        ? [
                            const Color(0xFFEF4444),
                            const Color(0xFFDC2626),
                          ]
                        : [
                            const Color(0xFFF59E0B),
                            const Color(0xFFD97706),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDangerous
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B))
                          .withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isDangerous
                      ? Icons.warning_rounded
                      : Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDangerous
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1F2937),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDangerous
                                ? [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626),
                                  ]
                                : [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isDangerous
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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

  // Loading Dialog (kept for backward compatibility with other pages)
  void showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      useRootNavigator: true,
      context: context,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (pop, res) => false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
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

  void showTransactionDetailPopUp(
      BuildContext context, TransactionModel transaction, IconData icon) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: Colors.transparent,
              content: TransactionDetailPopUp(
                icon: icon,
                title: transaction.title,
                amount: transaction.amount.toString(),
                date: transaction.date,
                description: transaction.transactionDescription,
                category: transaction.category,
                type: transaction.type,
              ),
            ));
  }
}
