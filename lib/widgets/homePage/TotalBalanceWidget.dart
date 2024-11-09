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
                  "https://img.freepik.com/free-psd/money-illustration-isolated_23-2151568546.jpg"),
              fit: BoxFit.cover)),
    );
  }
}
