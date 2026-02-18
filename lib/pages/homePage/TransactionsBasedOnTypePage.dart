import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/pages/homePage/EditTransactionPage.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:finance_tracker/widgets/TransactionTile.dart';
import 'package:finance_tracker/widgets/homePage/RecentTransactionsWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsBasedOnTypePage extends StatefulWidget {
  final String type;
  const TransactionsBasedOnTypePage({super.key, required this.type});

  @override
  State<TransactionsBasedOnTypePage> createState() =>
      _TransactionsBasedOnTypePageState();
}

class _TransactionsBasedOnTypePageState
    extends State<TransactionsBasedOnTypePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: widget.type,
        useCustomDesign: true,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder(
            stream: TransactionFirestoreService().getTransactionsBasedOnType(
                FirebaseAuth.instance.currentUser!.uid, widget.type),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final data = snapshot.data;
              if (data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No Transactions Yet :(",
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                );
              }

              return ListView(
                  children: data
                      .map((data) => GestureDetector(
                            onTap: () {
                              IconData categoryIcon = Categories()
                                  .categories
                                  .firstWhere(
                                      (cat) => cat.name == data["category"],
                                      orElse: () =>
                                          Categories().categories.first)
                                  .icon;
                              DialogBox().showTransactionDetailPopUp(
                                  context,
                                  TransactionModel(
                                    id: data["id"],
                                    title: data["title"],
                                    amount: (data["amount"] as num).toDouble(),
                                    date: data["date"].toDate(),
                                    transactionDescription: data["description"],
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
                                        await TransactionFirestoreService()
                                            .deleteTransaction(
                                                FirebaseAuth
                                                    .instance.currentUser!.uid,
                                                data["id"],
                                                (data["amount"] as num)
                                                    .toDouble(),
                                                data["type"]);
                                      },
                                      backgroundColor: const Color(0xFFFE4A49),
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
                                                        title: data["title"],
                                                        description:
                                                            data["description"],
                                                        amount: (data["amount"]
                                                                as num)
                                                            .toDouble(),
                                                        category:
                                                            data["category"],
                                                        date: data["date"]
                                                            .toDate(),
                                                        wallet:
                                                            data["wallet"] ??
                                                                'Cash')));
                                      },
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit,
                                      label: 'Edit',
                                    ),
                                  ]),
                              child: TransactionTile(
                                  title: data["title"],
                                  date: data["date"].toDate(),
                                  amount: (data["amount"] as num).toDouble(),
                                  type: data["type"],
                                  category: data["category"]),
                            ),
                          ))
                      .toList());
            }),
      ),
    );
  }
}
