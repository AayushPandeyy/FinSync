import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/service/UserFirestoreService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthFirestoreService {
  // get firebase instance
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final userFirestoreService = UserFirestoreService();

  //signIn
  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential user = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user;
    } on FirebaseAuthException catch (err) {
      // Re-throw to preserve error code for proper UI handling
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  //signUp
  Future<UserCredential> signUp(String email, String password, String username,
      String phoneNumber) async {
    try {
      UserCredential user = await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await userFirestoreService.addUserToDatabase(
          user.user!.uid, email, username, phoneNumber);

      if (!user.user!.emailVerified) {
        await user.user!.sendEmailVerification();
      }

      await FirebaseAuth.instance.signOut();
      return user;
    } on FirebaseAuthException catch (err) {
      // Re-throw to preserve error code for proper UI handling
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during registration');
    }
  }

  //signUpWithGoogle
  Future<UserCredential> signUpWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Check if user already exists in Firestore
      final userDoc = await firestore
          .collection('Users')
          .doc(userCredential.user!.uid)
          .get();

      // If user doesn't exist, add them to Firestore
      if (!userDoc.exists) {
        final displayName = userCredential.user?.displayName ?? 'User';
        final email = userCredential.user?.email ?? '';

        await userFirestoreService.addUserToDatabase(
          userCredential.user!.uid,
          email,
          displayName,
          '', // Phone number is not provided by Google
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (err) {
      rethrow;
    } catch (e) {
      throw Exception('Google sign-up failed: $e');
    }
  }

  //signInWithGoogle
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Check if user already exists in Firestore
      final userDoc = await firestore
          .collection('Users')
          .doc(userCredential.user!.uid)
          .get();

      // If user doesn't exist, add them to Firestore
      if (!userDoc.exists) {
        final displayName = userCredential.user?.displayName ?? 'User';
        final email = userCredential.user?.email ?? '';

        await userFirestoreService.addUserToDatabase(
          userCredential.user!.uid,
          email,
          displayName,
          '', // Phone number is not provided by Google
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (err) {
      rethrow;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from Google as well
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> deleteUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user!.delete();
    } catch (e) {
      throw Exception('User Deletion failed: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }

      // Delete Firestore data first (while we still have auth token)
      await userFirestoreService.deleteUser(user.uid);

      // Then delete the Firebase Auth account
      await user.delete();

      // Sign out is automatic after user.delete(), but we'll call it for safety
      await auth.signOut();
    } on FirebaseAuthException catch (e) {
      // Re-throw Firebase Auth exceptions (like requires-recent-login)
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
