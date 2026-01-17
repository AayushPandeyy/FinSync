import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/widgets/homePage/TransactionDetailPopUp.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DialogBox {
  void showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
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

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
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
