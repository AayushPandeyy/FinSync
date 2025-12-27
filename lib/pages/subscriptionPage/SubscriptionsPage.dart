import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  // Sample subscription data
  final List<Subscription> subscriptions = [
    Subscription(
      name: 'Netflix',
      amount: 1499,
      icon: Icons.movie_outlined,
      color: const Color(0xFFFF6B6B),
      billingCycle: 'Monthly',
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
      category: 'Entertainment',
    ),
    Subscription(
      name: 'Spotify',
      amount: 119,
      icon: Icons.music_note,
      color: const Color(0xFFFF6B6B),
      billingCycle: 'Monthly',
      nextBillingDate: DateTime.now().add(const Duration(days: 12)),
      category: 'Entertainment',
    ),
    Subscription(
      name: 'Amazon Prime',
      amount: 1499,
      icon: Icons.shopping_bag_outlined,
      color: const Color(0xFFFF6B6B),
      billingCycle: 'Yearly',
      nextBillingDate: DateTime.now().add(const Duration(days: 180)),
      category: 'Shopping',
    ),
    Subscription(
      name: 'Gym Membership',
      amount: 2500,
      icon: Icons.fitness_center,
      color: const Color(0xFFFF6B6B),
      billingCycle: 'Monthly',
      nextBillingDate: DateTime.now().add(const Duration(days: 8)),
      category: 'Health',
    ),
  ];

  double get totalMonthlyExpense {
    return subscriptions.fold(0.0, (sum, sub) {
      if (sub.billingCycle == 'Monthly') {
        return sum + sub.amount;
      } else if (sub.billingCycle == 'Yearly') {
        return sum + (sub.amount / 12);
      }
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(width * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1842),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B1842).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subscriptions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  // Total monthly expense card
                  Container(
                    padding: EdgeInsets.all(width * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Monthly Expense',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: width * 0.038,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Text(
                          'Rs ${totalMonthlyExpense.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: height * 0.005),
                        Text(
                          '${subscriptions.length} active subscriptions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: width * 0.032,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Subscriptions List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: width * 0.04,
                ),
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  return SubscriptionTile(
                    subscription: subscriptions[index],
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

class SubscriptionTile extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionTile({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    final daysUntilBilling = subscription.nextBillingDate.difference(DateTime.now()).inDays;
    final isUpcoming = daysUntilBilling <= 7;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.015,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1842).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Gradient accent bar
            

            // Main content
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                children: [
                  // Upcoming badge row
                  if (isUpcoming)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.025,
                            vertical: width * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade400,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active,
                                size: width * 0.035,
                                color: Colors.white,
                              ),
                              SizedBox(width: width * 0.015),
                              Text(
                                'Due Soon',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (isUpcoming) SizedBox(height: width * 0.025),
                  
                  // Main row
                  Row(
                    children: [
                      // Icon container
                      Container(
                        width: width * 0.15,
                        height: width * 0.15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1842),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B1842).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          subscription.icon,
                          color: Colors.white,
                          size: width * 0.075,
                        ),
                      ),

                      SizedBox(width: width * 0.04),

                      // Subscription details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.name,
                              style: TextStyle(
                                fontSize: width * 0.048,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1842),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: width * 0.015),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.008,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B1842).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF0B1842).withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    subscription.category,
                                    style: TextStyle(
                                      fontSize: width * 0.03,
                                      color: const Color(0xFF0B1842),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: width * 0.025),
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: width * 0.035,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: width * 0.015),
                                Flexible(
                                  child: Text(
                                    DateFormat("d MMM").format(subscription.nextBillingDate),
                                    style: TextStyle(
                                      fontSize: width * 0.035,
                                      color: isUpcoming ? Colors.orange.shade600 : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: width * 0.02),

                      // Amount and billing cycle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs ${subscription.amount}',
                            style: TextStyle(
                              color: subscription.color,
                              fontSize: width * 0.048,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: width * 0.012),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.03,
                              vertical: width * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: subscription.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: subscription.color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              subscription.billingCycle,
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: subscription.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subscription model
class Subscription {
  final String name;
  final double amount;
  final IconData icon;
  final Color color;
  final String billingCycle;
  final DateTime nextBillingDate;
  final String category;

  Subscription({
    required this.name,
    required this.amount,
    required this.icon,
    required this.color,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
  });
}