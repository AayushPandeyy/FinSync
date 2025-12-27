import 'package:finance_tracker/models/Subscription.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Main content row
          Row(
            children: [
              // Icon
              

              SizedBox(width: width * 0.04),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: TextStyle(
                        fontSize: width * 0.042,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: width * 0.01),
                    Row(
                      children: [
                        Text(
                          subscription.category,
                          style: TextStyle(
                            fontSize: width * 0.032,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCCCCCC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        Text(
                          subscription.billingCycle,
                          style: TextStyle(
                            fontSize: width * 0.032,
                            color: const Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                'Rs ${subscription.amount}',
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontSize: width * 0.042,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Next billing date row
          if (isUpcoming) ...[
            SizedBox(height: width * 0.03),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.03,
                vertical: width * 0.02,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: width * 0.035,
                    color: const Color(0xFFF57C00),
                  ),
                  SizedBox(width: width * 0.015),
                  Text(
                    'Due ${DateFormat("d MMM").format(subscription.nextBillingDate)}',
                    style: TextStyle(
                      fontSize: width * 0.032,
                      color: const Color(0xFFF57C00),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: width * 0.02),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: width * 0.03,
                  color: const Color(0xFF999999),
                ),
                SizedBox(width: width * 0.015),
                Text(
                  'Next: ${DateFormat("d MMM yyyy").format(subscription.nextBillingDate)}',
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: const Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}