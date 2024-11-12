import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/pages/TransactionsBasedOnTypePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BalaceDisplayBox extends StatefulWidget {
  final int balance;
  final TransactionType type;
  const BalaceDisplayBox(
      {super.key, required this.type, required this.balance});

  @override
  State<BalaceDisplayBox> createState() => _BalaceDisplayBoxState();
}

class _BalaceDisplayBoxState extends State<BalaceDisplayBox> {
  @override
  Widget build(BuildContext context) {
    bool isExpense = TransactionType.EXPENSE == widget.type;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => TransactionsBasedOnTypePage(
                    type: isExpense ? "EXPENSE" : "INCOME")));
      },
      child: Container(
        height: 150,
        width: MediaQuery.sizeOf(context).width * 0.45,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
                backgroundColor: !isExpense
                    ? const Color.fromARGB(255, 161, 225, 163)
                    : const Color.fromARGB(255, 233, 156, 151),
                radius: 20,
                child: Icon(
                  isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isExpense ? Colors.red : Colors.green,
                )),
            Text(
              isExpense ? "Expense" : "Income",
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "Rs ${widget.balance}",
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
