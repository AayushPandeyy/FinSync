import 'package:finance_tracker/widgets/homePage/TotalBalanceWidget.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))
        ],
        title: const Text(
          "My Wallet",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: const SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [TotalBalanceWidget()],
        ),
      ),
    ));
  }
}
