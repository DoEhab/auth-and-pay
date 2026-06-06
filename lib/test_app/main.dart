import 'package:flutter/material.dart';
import 'package:your_package_name/monetization/paywall_service.dart'; // Import from your package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your service with test keys
  await PaywallService().init(
    appleApiKey: 'appl_test_key_here',
    googleApiKey: 'goog_test_key_here',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Package Test')),
        body: Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: PaywallService().isPremium,
            builder: (context, isPremium, child) {
              return Text('Is Premium: $isPremium');
            },
          ),
        ),
      ),
    );
  }
}