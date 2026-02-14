import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/pages/goalsPage/AddGoalsPage.dart';
import 'package:finance_tracker/pages/goalsPage/EditGoalPage.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/GoalsFirestoreService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:finance_tracker/widgets/goalsPage/GoalWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3804780729029008/8582553165',
      // adUnitId:
      // 'ca-app-pub-3940256099942544/6300978111', // test ID, replace with your own
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Financial Goals',
        subtitle: 'Track your savings goals',
        useCustomDesign: true,
        actions: [
          GestureDetector(
            onTap: () async {
              final isOnline = await ConnectivityService.ensureConnected(
                context,
                actionDescription: 'add a goal',
              );
              if (!isOnline) return;

              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddGoalsPage(),
                ),
              );

              if (result == true && mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Goal saved successfully.'),
                    ),
                  );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(12),
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
            ),

            // Goals List
            Expanded(
              child: StreamBuilder(
                stream: TransactionFirestoreService()
                    .getTotalAmountInACategory("Savings"),
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
                    stream: GoalsFirestoreService()
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
                                              description:
                                                  goalData["description"],
                                              targetAmount: goalData["amount"],
                                              currentAmount: savingsAmount,
                                              deadline:
                                                  goalData["deadline"].toDate(),
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
                                      await GoalsFirestoreService().deleteGoal(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        FinancialGoal(
                                          id: goalData["id"],
                                          title: goalData["title"],
                                          description: goalData["description"],
                                          targetAmount: goalData["amount"],
                                          currentAmount: savingsAmount,
                                          deadline:
                                              goalData["deadline"].toDate(),
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
            if (_isBannerAdLoaded)
              Center(
                child: Container(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
