import 'package:finance_tracker/pages/GoalsPage.dart';
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
    const GoalsPage(),
    const ProfilePage()
  ];
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xff5a8eff),
          shape: const CircleBorder(),
          onPressed: () {},
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 60,
          notchMargin: 5,
          child: Row(
            // mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0
                      ? const Color(0xff5a8eff)
                      : Colors.black,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.pie_chart,
                  color: _currentIndex == 1
                      ? const Color(0xff5a8eff)
                      : Colors.black,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.track_changes,
                  color: _currentIndex == 2
                      ? const Color(0xff5a8eff)
                      : Colors.black,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _currentIndex == 3
                      ? const Color(0xff5a8eff)
                      : Colors.black,
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
              ),
            ],
          ),
        ),
        body: pages[_currentIndex],
      ),
    );
  }
}
