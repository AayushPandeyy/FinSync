import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/v6.dart';

class TransactionDetailPopUp extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String category;
  final String amount;
  final String type;
  final DateTime date;
  const TransactionDetailPopUp(
      {super.key,
      required this.icon,
      required this.title,
      required this.description,
      required this.category,
      required this.amount,
      required this.type,
      required this.date});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: ClipPath(
        clipper: TicketClipper(),
        child: Container(
          height: size.height * 0.5,
          width: size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    // CircleAvatar(
                    //   backgroundColor: const Color.fromARGB(255, 184, 230, 186),
                    //   radius: 24,
                    //   child: Icon(icon, color: Colors.red),
                    // ),
                    // Text(
                    //   "Transaction Successful",
                    //   style: TextStyle(
                    //       fontSize: 25,
                    //       fontWeight: FontWeight.bold,
                    //       color: Colors.white),
                    // )
                    LottieBuilder.asset("assets/lottiejson/success.json")
                  ],
                ),
                const Divider(),
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
                // Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Category",
                          style: TextStyle(color: Colors.white)),
                      Text(
                        category,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Amount",
                              style: TextStyle(color: Colors.white)),
                          FutureBuilder<String>(
                            future: CurrencyService.getCurrencySymbol(),
                            builder: (context, snapshot) {
                              final symbol = snapshot.data ?? 'Rs';
                              return Text(
                                "$symbol $amount",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Transaction Type",
                              style: TextStyle(color: Colors.white)),
                          Text(
                            type,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                    "Transaction Made On : ${DateFormat("EEE, d MMM, yyyy").format(date)}",
                    style: const TextStyle(color: Colors.white))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height / 2 - 20)
      ..quadraticBezierTo(
          size.width * 0.10, size.height / 2, 0, size.height / 2 + 20)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height / 2 + 20)
      ..quadraticBezierTo(
          size.width * 0.90, size.height / 2, size.width, size.height / 2 - 20)
      ..lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
