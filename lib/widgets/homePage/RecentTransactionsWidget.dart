// ignore_for_file: non_constant_identifier_names

import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class RecentTransactionsWidget extends StatefulWidget {
  const RecentTransactionsWidget({super.key});

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  @override
  Widget build(BuildContext context) {
    FirestoreService service = FirestoreService();
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50), topRight: Radius.circular(50))),
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transactions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "See All",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          StreamBuilder(
              stream: FirestoreService().getTransactionsOfUser(
                  FirebaseAuth.instance.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final data = snapshot.data;
                if (data!.isEmpty) {
                  return const Expanded(
                      child: Center(
                    child: Text(
                      "No Transactions Yet :(",
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ));
                }

                return Expanded(
                    child: ListView(
                        children: data
                            .map((data) => Slidable(
                                  endActionPane: ActionPane(
                                      extentRatio: 0.6,
                                      motion: const ScrollMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) async {
                                            await service.deleteTransaction(
                                                FirebaseAuth
                                                    .instance.currentUser!.uid,
                                                data["id"],
                                                data["amount"],
                                                data["type"]);
                                          },
                                          backgroundColor:
                                              const Color(0xFFFE4A49),
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Delete',
                                        ),
                                        SlidableAction(
                                          onPressed: (context) {},
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit,
                                          label: 'Edit',
                                        ),
                                      ]),
                                  child: TransactionTile(
                                      data["title"],
                                      data["date"].toDate(),
                                      data["amount"],
                                      data["type"]),
                                ))
                            .toList()));
              })
        ],
      ),
    );
  }
}

Widget TransactionTile(String title, DateTime date, int amount, String type) {
  bool isExpense = TransactionType.EXPENSE.name == type;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              child: CircleAvatar(
                  backgroundColor: !isExpense
                      ? const Color.fromARGB(255, 161, 225, 163)
                      : const Color.fromARGB(255, 233, 156, 151),
                  radius: 24,
                  child: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isExpense ? Colors.red : Colors.green,
                  )),
            ),
            const SizedBox(width: 16), // Spacing between avatar and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat("d MMM yyyy").format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isExpense ? "- ₹$amount" : "+ ₹$amount",
              style: TextStyle(
                color: isExpense ? Colors.red.shade400 : Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    ),
  );
}
