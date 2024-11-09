import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
            child: LottieBuilder.asset("assets/lottiejson/loading.json"),
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
}
