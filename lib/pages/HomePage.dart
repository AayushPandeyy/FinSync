import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/widgets/homePage/BalanceDisplayBox.dart';
import 'package:finance_tracker/widgets/homePage/RecentTransactionsWidget.dart';
import 'package:finance_tracker/widgets/homePage/TotalBalanceWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirestoreService service = FirestoreService();
  FirebaseAuth auth = FirebaseAuth.instance;
  User currUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: StreamBuilder(
            stream: service.getUserDataByEmail(currUser.email!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LottieBuilder.asset("assets/lottiejson/loading.json"),
                );
              }
              final data = snapshot.data![0];
              return Scaffold(
                backgroundColor: const Color(0xfff8f8fa),
                appBar: AppBar(
                  actions: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications)),
                    IconButton(
                        onPressed: () {}, icon: const Icon(Icons.more_horiz))
                  ],
                  title: Text(
                    "${data["username"].toString()}'s Wallet",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                body: SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: Column(
                    children: [
                      TotalBalanceWidget(
                        balance: data["totalBalance"],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          BalaceDisplayBox(
                            type: TransactionType.INCOME,
                            balance: data["income"],
                          ),
                          BalaceDisplayBox(
                            type: TransactionType.EXPENSE,
                            balance: data["expense"],
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Expanded(child: RecentTransactionsWidget())
                    ],
                  ),
                ),
              );
            }));
  }
}
