import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/pages/AddGoalsPage.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/widgets/goalsPage/GoalWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Your Goals",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder(
          stream: FirestoreService().getTotalAmountInACategory("Savings"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final savingsAmount = snapshot.data!;
            return SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: StreamBuilder(
                  stream: FirestoreService()
                      .getGoalsOfUser(FirebaseAuth.instance.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final data = snapshot.data;
                    if (data!.isEmpty) {
                      return Expanded(
                          child: Center(child: AddGoalButton(context)));
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: data
                                .map((data) => Slidable(
                                      endActionPane: ActionPane(
                                          extentRatio: 0.6,
                                          motion: const ScrollMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) async {
                                                FirestoreService().deleteGoal(
                                                    FirebaseAuth.instance
                                                        .currentUser!.uid,
                                                    FinancialGoal(
                                                        id: data["id"],
                                                        title: data["title"],
                                                        description:
                                                            data["description"],
                                                        targetAmount:
                                                            data["amount"],
                                                        currentAmount:
                                                            savingsAmount,
                                                        deadline:
                                                            data["deadline"]
                                                                .toDate()));
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
                                      child: FinancialGoalWidget(
                                          goal: FinancialGoal(
                                              id: data["id"],
                                              title: data["title"],
                                              description: data["description"],
                                              targetAmount: data["amount"],
                                              currentAmount: savingsAmount,
                                              deadline:
                                                  data["deadline"].toDate())),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        AddGoalButton(context),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    );
                  }),
            );
          }),
    ));
  }
}

Widget AddGoalButton(BuildContext context) {
  return InkWell(
    onTap: () {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => const AddGoalsPage()));
    },
    child: Container(
      height: 50,
      width: MediaQuery.sizeOf(context).width * 0.7,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.black),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add,
            size: 30,
            color: Colors.white,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            "Add a New Goal",
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          )
        ],
      ),
    ),
  );
}
