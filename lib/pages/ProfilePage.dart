import 'package:finance_tracker/pages/auth/LoginChecker.dart';
import 'package:finance_tracker/service/AuthFirebaseService.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    AuthFirebaseService authService = AuthFirebaseService();
    return SafeArea(
        child: Scaffold(
      body: Center(
        child: GestureDetector(
            onTap: () {
              authService.logout();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginChecker()));
            },
            child: const Text("profile")),
      ),
    ));
  }
}
