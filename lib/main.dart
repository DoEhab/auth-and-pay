import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/env_config.dart';
import 'core/monetization/paywall_service.dart';
//import 'screens/calculator_home.dart'; // Your unique app UI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase for THIS specific app configuration
  await Firebase.initializeApp();

  // 2. Initialize RevenueCat with THIS specific app's keys
  await PaywallService().init(
    appleApiKey: EnvConfig.revenueCatAppleKey,
    googleApiKey: EnvConfig.revenueCatGoogleKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
    //  home: CalculatorHomeScreen(), // Launches your app
    );
  }
}
