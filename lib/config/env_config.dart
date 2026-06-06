class EnvConfig {
  // These will be injected at compile time
  static const String revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'fallback_key_for_testing',
  );

  static const String revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'fallback_key_for_testing',
  );
}