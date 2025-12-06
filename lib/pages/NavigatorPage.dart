import 'package:finance_tracker/pages/AddTransactionPage.dart';
import 'package:finance_tracker/pages/GoalsPage.dart';
import 'package:finance_tracker/pages/HomePage.dart';

import 'package:finance_tracker/pages/ReportPage.dart';
import 'package:finance_tracker/pages/SubscriptionsPage.dart';
import 'package:flutter/material.dart';

class NavigatorPage extends StatefulWidget {
  const NavigatorPage({super.key});

  @override
  State<NavigatorPage> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<NavigatorPage> {
  List<Widget> pages = [
    const HomePage(),
    const SubscriptionsPage(),
    const GoalsPage(),
  ];
  int _currentIndex = 0;

  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          height: 55,
          // shape: const CircularNotchedRectangle(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          notchMargin: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildNavItem(icon: Icons.home, label: "Home", index: 0),
                _buildNavItem(
                    icon: Icons.subscriptions, label: "Subscriptions", index: 1),
                _buildNavItem(
                    icon: Icons.track_changes, label: "Goals", index: 2),
              ],
            ),
          ),
        ),
        body: pages[_currentIndex],
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xff5a8eff) : Colors.black,
            size: 25,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xff5a8eff) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
