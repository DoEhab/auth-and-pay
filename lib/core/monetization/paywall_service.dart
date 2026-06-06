import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallService {
  static final PaywallService _instance = PaywallService._internal();
  factory PaywallService() => _instance;
  PaywallService._internal();

  ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  Future<void> init({
    required String appleApiKey,
    required String googleApiKey,
  }) async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    PurchasesConfiguration configuration;
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration(appleApiKey);
    } else if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(googleApiKey);
    } else {
      throw UnsupportedError("Unsupported platform for RevenueCat");
    }

    await Purchases.configure(configuration);

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      isPremium.value =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
    });

    await updatePremiumStatus();
  }

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint("Error fetching offerings: $e");
      return null;
    }
  }

  Future<void> loginUser(String firebaseUid) async {
    try {
      await Purchases.logIn(firebaseUid);

      // 🔥 CRITICAL FIX: Restore purchases to sync with the device's App Store/Google account.
      // This merges the purchase from the anonymous ID into the new Firebase UID.
      final restoredInfo = await Purchases.restorePurchases();

      isPremium.value =
          restoredInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      debugPrint("Error logging in to RevenueCat: $e");
    }
  }

  // Centralized logout method
  Future<void> logoutUser() async {
    await Purchases.logOut();
    isPremium.value = false;
  }

  // Manual restore method (Useful for a "Restore Purchases" button in the UI)
  Future<bool> restorePurchases() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      isPremium.value =
          restoredInfo.entitlements.all['premium']?.isActive ?? false;
      return isPremium.value;
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
      return false;
    }
  }

  Future<void> updatePremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      isPremium.value =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      isPremium.value = false;
    }
  }

  // Process a purchase using an abstract entitlement ID
  Future<bool> purchaseProduct(Package package) async {
    try {
      // 🔥 FIX: In v10.x, this returns a PurchaseResult, not CustomerInfo
      final purchaseResult = await Purchases.purchasePackage(package);

      // 🔥 FIX: Access .customerInfo on the result object
      final bool hasPremium = purchaseResult.customerInfo.entitlements.all['premium']?.isActive ?? false;

      isPremium.value = hasPremium;
      return hasPremium;

    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("User cancelled the purchase.");
      } else {
        debugPrint("Purchase failed with error: $e");
      }
      return false;
    } catch (e) {
      debugPrint("Unexpected purchase error: $e");
      return false;
    }
  }
}
