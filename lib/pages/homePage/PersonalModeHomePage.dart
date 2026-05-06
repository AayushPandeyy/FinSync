import 'package:finance_tracker/widgets/homePage/PersonalModeDrawer.dart';
import 'package:flutter/material.dart';

class PersonalModeHomePage extends StatelessWidget {
  const PersonalModeHomePage({
    super.key,
    required this.appBar,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const PersonalModeDrawer(),
      backgroundColor: const Color(0xfff8f8fa),
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: body,
      ),
    );
  }
}
