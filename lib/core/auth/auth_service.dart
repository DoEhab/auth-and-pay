import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../monetization/paywall_service.dart'; // Adjust path as needed

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    try {
      UserCredential credential = await _auth.signInAnonymously();
      if (credential.user != null) {
        // This now automatically calls restorePurchases() behind the scenes
        await PaywallService().loginUser(credential.user!.uid);
      }
      return credential.user;
    } catch (e) {
      debugPrint("Firebase sign in error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Use the centralized logout from PaywallService
    await PaywallService().logoutUser();
  }
}