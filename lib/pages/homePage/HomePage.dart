import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/pages/analyticsPage/ReportPage.dart';
import 'package:finance_tracker/pages/budgetPage/BudgetPage.dart';
import 'package:finance_tracker/pages/goalsPage/GoalsPage.dart';
import 'package:finance_tracker/pages/subscriptionPage/SubscriptionsPage.dart';
import 'package:finance_tracker/pages/transactionsPage/SeeAllTransactionsPage.dart';
import 'package:finance_tracker/pages/homePage/AddTransactionPage.dart';
import 'package:finance_tracker/pages/auth/LoginChecker.dart';
import 'package:finance_tracker/service/AuthFirebaseService.dart';
import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:finance_tracker/widgets/homePage/BalanceDisplayBox.dart';
import 'package:finance_tracker/widgets/homePage/RecentTransactionsWidget.dart';
import 'package:finance_tracker/widgets/homePage/TotalBalanceWidget.dart';
import 'package:finance_tracker/widgets/homePage/featureBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  @override
  void initState() {
    super.initState();

    // Initialize banner ad
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-3804780729029008/8582553165', // test ID, replace with your own
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
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder(
        stream: service.getUserDataByEmail(currUser.email!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: LottieBuilder.asset("assets/lottiejson/loading.json"),
            );
          }

          final data = snapshot.data![0];

          return Scaffold(
            backgroundColor: const Color(0xfff8f8fa),
            appBar: AppBar(
              backgroundColor: const Color(0xfff8f8fa),
              elevation: 0,
              title: Text(
                "Hello ${data["username"]} :)",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF1A1A1A))),
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
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              AuthFirebaseService().logout();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginChecker()),
                              );
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance cards section
                  SizedBox(
                    height: 200,
                    child: StreamBuilder(
                      stream: FirestoreService()
                          .getTotalAmountInACategory("Savings"),
                      builder: (context, snapshot) {
                        /// ----------- FIXED SAVINGS LOADER ----------
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator.adaptive(),
                          );
                        }

                        double amount = snapshot.data!;
                        double usableAmount =
                            (data["totalBalance"] as num).toDouble() - amount;

                        return Center(
                          child: TotalBalanceWidget(
                            title: "Total Balance",
                            balance: (data["totalBalance"] as num).toDouble(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Income and Expense boxes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BalanceDisplayBox(
                          type: TransactionType.INCOME,
                          balance: (data["income"] as num).toDouble(),
                        ),
                        BalanceDisplayBox(
                          type: TransactionType.EXPENSE,
                          balance: (data["expense"] as num).toDouble(),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Services section header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Services",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Feature boxes section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          FeatureBox(
                            title: "Transactions",
                            subtitle: "View all transactions",
                            icon: Icons.receipt_long,
                            accentColor: const Color(0xFF4A90E2),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SeeAllTransactionsPage(),
                                ),
                              );
                            },
                          ),

                          FeatureBox(
                            title: "Goals",
                            subtitle: "Your financial goals",
                            icon: Icons.savings,
                            accentColor: const Color(0xFFE67E22),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GoalsPage(),
                                ),
                              );
                            },
                          ),
                          FeatureBox(
                            title: "Analytics",
                            subtitle: "View insights",
                            icon: Icons.analytics,
                            accentColor: const Color(0xFFE74C3C),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReportPage(),
                                ),
                              );
                            },
                          ),
                          // FeatureBox(
                          //   title: "Subscriptions",
                          //   subtitle: "Manage subscriptions",
                          //   icon: Icons.sync_alt,
                          //   accentColor: const Color(0xFF9B59B6),
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) =>
                          //             const SubscriptionsPage(),
                          //       ),
                          //     );
                          //   },
                          // ),
                          FeatureBox(
                            title: "Budget ",
                            subtitle: "Set your budget",
                            icon: Icons.pie_chart,
                            accentColor: const Color(0xFF16A085),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BudgetPage()));
                            },
                          ),

                          // FeatureBox(
                          //   title: "Coming Soon",
                          //   subtitle: "Manage categories",
                          //   icon: Icons.category,
                          //   accentColor: const Color(0xFF3498DB),
                          //   onTap: () {},
                          // ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_isBannerAdLoaded)
                    Center(
                      child: Container(
                        width: _bannerAd.size.width.toDouble(),
                        height: _bannerAd.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Recent Transactions Widget (if you have it)
                  // const RecentTransactionsWidget(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
