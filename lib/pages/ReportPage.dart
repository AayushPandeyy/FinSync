import 'package:finance_tracker/widgets/reportPage/TransactionChartWidget.dart';
import 'package:finance_tracker/widgets/reportPage/TransactionPieChartWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Financial Report",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TransactionChartWidget(
                  uid: FirebaseAuth.instance.currentUser!.uid),
              const SizedBox(
                height: 30,
              ),
              const TransactionPieChartsWidget()
            ],
          ),
        ),
      ),
    ));
  }
}
