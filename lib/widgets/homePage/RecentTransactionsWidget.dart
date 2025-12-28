// ignore_for_file: non_constant_identifier_names

import 'package:finance_tracker/models/Category.dart';
import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/pages/homePage/EditTransactionPage.dart';
import 'package:finance_tracker/pages/transactionsPage/SeeAllTransactionsPage.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/TransactionTile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const SeeAllTransactionsPage()));
                },
                child: const Text(
                  "See All",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        StreamBuilder(
            stream: FirestoreService().getRecentTransactionsOfUser(
                FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(
                    backgroundColor: Colors.yellow,
                  ),
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
                          .map((data) => GestureDetector(
                                onTap: () {
                                  IconData categoryIcon = Categories()
                                      .categories
                                      .firstWhere(
                                          (cat) =>
                                              cat.name == data["category"],
                                          orElse: () => Category(
                                                name: 'Unknown',
                                                icon: Icons.help_outline
                                              )).icon;
                                  DialogBox().showTransactionDetailPopUp(
                                      context,
                                      TransactionModel(
                                        id: data["id"],
                                        title: data["title"],
                                        amount:
                                            (data["amount"] as num).toDouble(),
                                        date: data["date"].toDate(),
                                        transactionDescription:
                                            data["description"],
                                        category: data["category"],
                                        type: data["type"],
                                      ),
                                      categoryIcon);
                                },
                                child: Slidable(
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
                                                (data["amount"] as num)
                                                    .toDouble(),
                                                data["type"]);
                                          },
                                          backgroundColor:
                                              const Color(0xFFFE4A49),
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Delete',
                                        ),
                                        SlidableAction(
                                          onPressed: (context) {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditTransactionPage(
                                                            id: data["id"],
                                                            type: data["type"],
                                                            title:
                                                                data["title"],
                                                            description: data[
                                                                "description"],
                                                            amount:
                                                                (data["amount"] as num).toDouble(),
                                                            category: data[
                                                                "category"],
                                                            date: data["date"]
                                                                .toDate())));
                                          },
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit,
                                          label: 'Edit',
                                        ),
                                      ]),
                                  child: TransactionTile(
                                    title: 
                                      data["title"],
                                      date: 
                                      data["date"].toDate(),
                                      amount: 
                                      (data["amount"] as num).toDouble(),
                                      type: 
                                      data["type"],
                                      category: 
                                      data["category"]),
                                ),
                              ))
                          .toList()));
            })
      ],
    );
  }
}

