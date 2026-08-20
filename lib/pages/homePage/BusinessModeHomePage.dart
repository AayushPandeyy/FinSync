import 'package:flutter/material.dart';

class BusinessModeHomePage extends StatelessWidget {
  const BusinessModeHomePage({
    super.key,
    required this.appBar,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8fa),
      appBar: appBar,
      body: body,
    );
  }
}
