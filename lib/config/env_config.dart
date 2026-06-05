import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get revenueCatAppleKey => dotenv.env['REVENUECAT_APPLE_KEY'] ?? '';
  static String get revenueCatGoogleKey => dotenv.env['REVENUECAT_GOOGLE_KEY'] ?? '';
}
