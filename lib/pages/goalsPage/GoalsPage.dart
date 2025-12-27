import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/pages/goalsPage/AddGoalsPage.dart';
import 'package:finance_tracker/pages/goalsPage/EditGoalPage.dart';
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
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and Add button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF000000),
                            size: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddGoalsPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    "Financial Goals",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      color: Color(0xFF000000),
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),
            
            // Goals List
            Expanded(
              child: StreamBuilder(
                stream: FirestoreService().getTotalAmountInACategory("Savings"),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF000000),
                        strokeWidth: 2,
                      ),
                    );
                  }
                  
                  final savingsAmount = snapshot.data ?? 0;
                  
                  return StreamBuilder(
                    stream: FirestoreService()
                        .getGoalsOfUser(FirebaseAuth.instance.currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF000000),
                            strokeWidth: 2,
                          ),
                        );
                      }
                      
                      final data = snapshot.data ?? [];
                      
                      if (data.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Icon(
                                  Icons.flag_outlined,
                                  size: 36,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No goals yet",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Tap + to add your first goal",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final goalData = data[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Slidable(
                              endActionPane: ActionPane(
                                extentRatio: 0.5,
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditGoalPage(
                                            goal: FinancialGoal(
                                              id: goalData["id"],
                                              title: goalData["title"],
                                              description: goalData["description"],
                                              targetAmount: goalData["amount"],
                                              currentAmount: savingsAmount,
                                              deadline: goalData["deadline"].toDate(),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    backgroundColor: const Color(0xFF000000),
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: 'Edit',
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(0),
                                      bottomLeft: Radius.circular(0),
                                    ),
                                  ),
                                  SlidableAction(
                                    onPressed: (context) async {
                                      await FirestoreService().deleteGoal(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        FinancialGoal(
                                          id: goalData["id"],
                                          title: goalData["title"],
                                          description: goalData["description"],
                                          targetAmount: goalData["amount"],
                                          currentAmount: savingsAmount,
                                          deadline: goalData["deadline"].toDate(),
                                        ),
                                      );
                                    },
                                    backgroundColor: const Color(0xFFE63946),
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: FinancialGoalWidget(
                                goal: FinancialGoal(
                                  id: goalData["id"],
                                  title: goalData["title"],
                                  description: goalData["description"],
                                  targetAmount: goalData["amount"],
                                  currentAmount: savingsAmount,
                                  deadline: goalData["deadline"].toDate(),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}