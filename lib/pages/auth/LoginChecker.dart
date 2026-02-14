import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/pages/homePage/HomePage.dart';
import 'package:finance_tracker/pages/auth/LoginPage.dart';
import 'package:finance_tracker/utilities/Globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginChecker extends StatefulWidget {
  const LoginChecker({super.key});

  @override
  State<LoginChecker> createState() => _LoginCheckerState();
}

class _LoginCheckerState extends State<LoginChecker> {
  bool _hasCheckedUpdate = false;

  Future<void> _checkForUpdate(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Globals')
          .doc('Config')
          .get();

      if (!doc.exists) return;

      final remoteVersion = (doc.data()?['VersionCode'] as num?)?.toDouble();
      if (remoteVersion == null) return;

      if (remoteVersion > Globals.versionCode && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'New Update Available!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    "We've brought you a shiny new update with improvements and new features. Update now to get the best experience!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.pandeyaayush.finsync',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upgrade_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Update Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Skip Button
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (_) {
      // Silently fail — don't block app usage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong!'));
            }
            if (snapshot.hasData) {
              if (!_hasCheckedUpdate) {
                _hasCheckedUpdate = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkForUpdate(context);
                });
              }
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
      ),
    );
  }
}
