import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalBalanceWidget extends StatelessWidget {
  final String title;
  final int balance;
  const TotalBalanceWidget(
      {super.key, required this.balance, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        width: MediaQuery.sizeOf(context).width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
                image: AssetImage("assets/images/bubble_bg.jpg"),
                fit: BoxFit.cover)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            Text(
              (NumberFormat.currency(symbol: 'Rs ').format(balance)),
              style: const TextStyle(fontSize: 45, color: Colors.black),
            ),
          ],
        ));
  }
}
