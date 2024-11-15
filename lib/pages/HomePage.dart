import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/pages/AddTransactionPage.dart';
import 'package:finance_tracker/pages/auth/LoginChecker.dart';
import 'package:finance_tracker/service/AuthFirebaseService.dart';
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
  int savingAmount = 0;
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
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddTransactionPage()));
                        },
                        icon: const Icon(Icons.add)),
                    IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Logout"),
                              content: const Text(
                                  "You are about to logout. Are you sure you want to continue?"),
                              actions: [
                                TextButton(
                                  onPressed: () => {
                                    Navigator.pop(context),
                                  },
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => {
                                    Navigator.pop(context),
                                    AuthFirebaseService().logout(),
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginChecker()))
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout)),
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
                      SizedBox(
                        height: 150,
                        child: StreamBuilder(
                          stream: FirestoreService()
                              .getTotalAmountInACategory("Savings"),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.yellow,
                                ),
                              );
                            }
                            double amount = snapshot.data!;
                            double usableAmount =
                                (data["totalBalance"] as num).toDouble() -
                                    amount;
                            return ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TotalBalanceWidget(
                                        balance: usableAmount,
                                        title: "Usable Amount"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TotalBalanceWidget(
                                        balance: amount, title: "Total Saving"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TotalBalanceWidget(
                                      title: "Total Balance",
                                      balance: (data["totalBalance"] as num)
                                          .toDouble(),
                                    ),
                                  ),
                                ]);
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          BalaceDisplayBox(
                            type: TransactionType.INCOME,
                            balance: (data["income"] as num).toDouble(),
                          ),
                          BalaceDisplayBox(
                            type: TransactionType.EXPENSE,
                            balance: (data["expense"] as num).toDouble(),
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
