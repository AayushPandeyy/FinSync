import 'package:finance_tracker/pages/auth/ForgotPasswordPage.dart';
import 'package:finance_tracker/pages/auth/RegisterPage.dart';
import 'package:finance_tracker/service/AuthFirestoreService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool isObscured = true;
  bool _isLoggingIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthFirestoreService authService = AuthFirestoreService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login(BuildContext context) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      UserCredential user = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!user.user!.emailVerified) {
        if (!mounted) return;
        setState(() {
          _isLoggingIn = false;
        });
        await authService.logout();

        if (!mounted) return;
        DialogBox().showMessageDialog(
          context,
          isSuccess: false,
          title: "Email Verification Required",
          message:
              "Your email has not yet been verified. Please verify your email and try again.",
        );
      } else {
        if (!mounted) return;
        _resetFields();

        // Don't navigate manually - LoginChecker's StreamBuilder will automatically
        // detect the auth state change and show HomePage
        // Keep _isLoggingIn = true since we're navigating away
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
      });

      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      if (!mounted) return;
      DialogBox().showMessageDialog(
        context,
        isSuccess: false,
        title: "Login Failed",
        message: errorMessage,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
      });

      if (!mounted) return;
      DialogBox().showMessageDialog(
        context,
        isSuccess: false,
        title: "Login Failed",
        message: "An unknown error occurred. Please try again.",
      );
    }
  }

  void _resetFields() {
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00B4DB),
              Color(0xFF0083B0),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Login to your account",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: Colors.white),
                          hintText: "Email",
                          hintStyle: const TextStyle(color: Colors.white70),
                          errorStyle: const TextStyle(color: Colors.yellow),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.yellow),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.yellow),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: isObscured,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                isObscured = !isObscured;
                              });
                            },
                          ),
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Colors.white70),
                          errorStyle: const TextStyle(color: Colors.yellow),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.yellow),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.yellow),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _isLoggingIn
                      ? null
                      : () {
                          login(context);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF8C00),
                          const Color(0xFFFFD700),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        _isLoggingIn ? "Logging in..." : "Login",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const RegisterPage()));
                  },
                  child: const Text(
                    "Dont Have An Account? Register Here",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle forgot password
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const ForgotPasswordPage()));
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
