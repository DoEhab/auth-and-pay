import 'package:flutter/material.dart';
import '../monetization/paywall_service.dart';
import 'auth_service.dart'; // Adjust path as needed
// import 'home_screen.dart'; // Import your actual home screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGetStarted() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await AuthService().signInAnonymously();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      // Navigate to your main app screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Home Screen')))), // Replace with HomeScreen()
      );
    } else {
      setState(() {
        _errorMessage = "Couldn't connect. Please check your internet.";
      });
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);

    final restored = await PaywallService().restorePurchases();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored successfully!')),
      );
      // Navigate to Home if restored
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active purchases found on this account.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),

              // App Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome, // Replace with your app's icon
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Headline
              Text(
                'Welcome to Your App',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subheadline
              Text(
                'Sign in anonymously to start exploring. No email or password required.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Error Message
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Primary "Get Started" Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary "Restore Purchases" Button
              TextButton(
                onPressed: _isLoading ? null : _handleRestore,
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}