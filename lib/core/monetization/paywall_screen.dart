import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'paywall_service.dart'; // Import your service
import 'package:url_launcher/url_launcher.dart';


class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final PaywallService _paywallService = PaywallService();

  Offerings? _offerings;
  bool _isLoadingOfferings = true;
  String? _errorMessage;

  // Track which package is currently being purchased to show a loading indicator
  String? _purchasingPackageId;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    setState(() => _isLoadingOfferings = true);

    final offerings = await _paywallService.getOfferings();

    if (!mounted) return;

    setState(() {
      _offerings = offerings;
      _isLoadingOfferings = false;
      if (offerings == null) {
        _errorMessage = "Failed to load products. Please check your internet.";
      }
    });
  }

  Future<void> _handlePurchase(Package package) async {
    // 1. Prevent double-taps by setting a loading state for this specific button
    setState(() => _purchasingPackageId = package.identifier);

    // 2. Call the service
    final success = await _paywallService.purchaseProduct(package);

    if (!mounted) return;

    // 3. Clear loading state
    setState(() => _purchasingPackageId = null);

    if (success) {
      // The ValueNotifier in PaywallService will automatically update the UI
      // via the listener we added in init(), but we can also show a success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase successful! Welcome to Premium.')),
      );
      Navigator.of(context).pop(); // Close paywall
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingOfferings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOfferings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final currentOffering = _offerings?.current;
    if (currentOffering == null) {
      return const Center(child: Text('No premium options available.'));
    }

    final packages = currentOffering.availablePackages;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Get the most out of your experience',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Listen to the isPremium ValueNotifier to show current status
          ValueListenableBuilder<bool>(
            valueListenable: _paywallService.isPremium,
            builder: (context, isPremium, child) {
              if (isPremium) {
                return Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'You are already a Premium member!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),

          // Render all available packages dynamically
          ...packages.map((package) => _buildPackageCard(package)).toList(),

          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              try {
                // 1. Fetch the current CustomerInfo from RevenueCat
                final customerInfo = await Purchases.getCustomerInfo();

                // 2. Get the management URL
                // (This will be null if the user has no active subscriptions)
                final managementUrl = customerInfo.managementURL;

                if (managementUrl != null) {
                  final uri = Uri.parse(managementUrl);

                  // 3. Open the URL in the device's browser/settings
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open subscription management page.')),
                      );
                    }
                  }
                } else {
                  // If the URL is null, they likely have a Lifetime pass or no active sub
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You do not have an active subscription to manage.')),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Error fetching management URL: $e");
              }
            },
            child: const Text('Manage Subscription'),
          ),
          Text(
            'Payment will be charged to your App Store / Google Play account. Subscription automatically renews unless turned off in your Account Settings at least 24 hours prior to the end of the current period.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final isPurchasing = _purchasingPackageId == package.identifier;

    // Determine title and subtitle based on package type
    String title;
    String? subtitle;

    switch (package.packageType) {
      case PackageType.monthly:
        title = 'Monthly Subscription';
        subtitle = 'Billed every month';
        break;
      case PackageType.annual:
        title = 'Annual Subscription';
        subtitle = 'Billed every year (Best Value!)';
        break;
      case PackageType.lifetime:
        title = 'Lifetime Access';
        subtitle = 'One-time payment, yours forever';
        break;
      default:
        title = package.storeProduct.title;
        subtitle = package.storeProduct.description;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPurchasing ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPurchasing
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPurchasing ? null : () => _handlePurchase(package),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              if (isPurchasing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  package.storeProduct.priceString, // e.g., "$9.99"
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}