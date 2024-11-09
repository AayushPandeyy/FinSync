import 'package:finance_tracker/pages/HomePage.dart';
import 'package:finance_tracker/pages/ProfilePage.dart';
import 'package:finance_tracker/pages/ReportPage.dart';
import 'package:flutter/material.dart';

class NavigatorPage extends StatefulWidget {
  const NavigatorPage({super.key});

  @override
  State<NavigatorPage> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<NavigatorPage> {
  List<Widget> pages = [
    const HomePage(),
    const ReportPage(),
    const ProfilePage()
  ];
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            unselectedItemColor: Colors.black,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.red,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart), label: "Report"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile")
            ]),
        body: pages[_currentIndex],
      ),
    );
  }
}
