
import 'package:finance_tracker/pages/homePage/HomePage.dart';
import 'package:finance_tracker/pages/auth/LoginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginChecker extends StatelessWidget {
  const LoginChecker({super.key});






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (snapshot.hasData) {
            return KeyedSubtree(
              key: const ValueKey('home'),
              child: const HomePage(),
            );
          } else {
            return KeyedSubtree(
              key: const ValueKey('login'),
              child: const LoginPage(),
            );
          }
        },
      ),
    );
  }
}