import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/widgets/homePage/BalanceDisplayBox.dart';
import 'package:finance_tracker/widgets/homePage/RecentTransactionsWidget.dart';
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
      backgroundColor: const Color(0xfff8f8fa),
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
          children: [
            TotalBalanceWidget(),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BalaceDisplayBox(type: TransactionType.INCOME),
                BalaceDisplayBox(type: TransactionType.EXPENSE)
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(child: RecentTransactionsWidget())
          ],
        ),
      ),
    ));
  }
}
