import 'package:finance_tracker/service/AuthFirestoreService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final dialogBox = DialogBox();

  bool obscure = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> signUp(BuildContext context) async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthFirestoreService authService = AuthFirestoreService();
    try {
      await authService.signUp(
          emailController.text.trim(),
          passwordController.text,
          usernameController.text.trim(),
          phoneController.text.trim());

      if (!mounted) return;
      dialogBox.showMessageDialog(
        context,
        isSuccess: true,
        title: "Verification Email Sent",
        message:
            "A verification email has been sent. Please verify your email and login to your account.",
      );
      // Navigate back to login after dialog is dismissed
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context); // Return to login
    } on FirebaseAuthException catch (err) {
      if (!mounted) return;

      String errorMessage;
      switch (err.code) {
        case 'email-already-in-use':
          errorMessage =
              'This email is already registered. Please login instead.';
          break;
        case 'weak-password':
          errorMessage = 'Please use a stronger password.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Registration is currently disabled. Please contact support.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Registration failed. Please try again.';
      }

      if (!mounted) return;
      dialogBox.showMessageDialog(
        context,
        isSuccess: false,
        title: "Registration Failed",
        message: errorMessage,
      );
    } catch (err) {
      if (!mounted) return;

      if (!mounted) return;
      dialogBox.showMessageDialog(
        context,
        isSuccess: false,
        title: "Error",
        message: "An unexpected error occurred. Please try again.",
      );
    }
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Join us by creating your account",
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
                          controller: usernameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                .hasMatch(value.trim())) {
                              return 'Username can only contain letters, numbers, and underscores';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: Colors.white),
                            hintText: "Username",
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
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
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
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.trim().length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.phone, color: Colors.white),
                            hintText: "Phone Number",
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
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscure,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Password must contain at least one uppercase letter';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Password must contain at least one lowercase letter';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Password must contain at least one number';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            hintText: "Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscure = !obscure;
                                });
                              },
                            ),
                            hintStyle: const TextStyle(color: Colors.white70),
                            errorStyle: const TextStyle(
                                color: Colors.yellow, fontSize: 11),
                            helperText:
                                'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                            helperStyle: const TextStyle(
                                color: Colors.white60, fontSize: 11),
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
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  const BorderSide(color: Colors.yellow),
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      signUp(context);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF8C00),
                            Color(0xFFFFD700),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 48,
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
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
                      Navigator.pop(context); // Go back to login page
                    },
                    child: const Text(
                      "Already have an account? Login",
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
      ),
    );
  }
}
