import 'package:flutter/material.dart';

class TotalBalanceWidget extends StatelessWidget {
  const TotalBalanceWidget({super.key});

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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total Balance",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
            Text(
              "\$15000",
              style: TextStyle(fontSize: 45, color: Colors.black),
            ),
          ],
        ));
  }
}
