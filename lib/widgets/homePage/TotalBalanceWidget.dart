import 'package:flutter/material.dart';

class TotalBalanceWidget extends StatelessWidget {
  final int balance;
  const TotalBalanceWidget({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        width: MediaQuery.sizeOf(context).width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
                image: NetworkImage(
                    "https://w0.peakpx.com/wallpaper/544/197/HD-wallpaper-circles-android-bubbles-colorful-colour-colourful-pattern.jpg"),
                fit: BoxFit.cover)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Total Balance",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
            Text(
              "\$$balance",
              style: const TextStyle(fontSize: 45, color: Colors.black),
            ),
          ],
        ));
  }
}
