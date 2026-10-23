import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/billing_service.dart';
import '../core/subscription_guard.dart';
import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum PremiumPlan {
  monthly,
  threeMonths,
  sixMonths,
  yearly,
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const Color _blue = Color(0xFF39C2FF);

  static const String _privacyUrl =
      'https://sites.google.com/view/musclemind-app/privacy-policy';
  static const String _termsUrl =
      'https://sites.google.com/view/musclemind-app/terms-of-use';

  bool _loading = false;
  bool _initializing = true;
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  BillingService get _billing => BillingService();

  @override
  void initState() {
    super.initState();
    _initBilling();
  }

  Future<void> _initBilling() async {
    try {
      await _billing.init();
      await _billing.refreshProducts();
      await _billing.refreshSubscriptionStatus();
    } catch (e) {
      debugPrint('Paywall init error: $e');
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  bool get _hasPlans => _billing.hasPlans;

  String _basePlanIdForPlan(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return BillingService.monthlyBasePlanId;
      case PremiumPlan.threeMonths:
        return BillingService.threeMonthsBasePlanId;
      case PremiumPlan.sixMonths:
        return BillingService.sixMonthsBasePlanId;
      case PremiumPlan.yearly:
        return BillingService.yearlyBasePlanId;
    }
  }

  BillingPlan? _billingPlanFor(PremiumPlan plan) {
    return _billing.getPlanByBasePlanId(_basePlanIdForPlan(plan));
  }

  String _fallbackPriceForPlan(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return '\$9.99';
      case PremiumPlan.threeMonths:
        return '\$27.99';
      case PremiumPlan.sixMonths:
        return '\$49.99';
      case PremiumPlan.yearly:
        return '\$79.99';
    }
  }

  String _priceForPlan(PremiumPlan plan) {
    final BillingPlan? billingPlan = _billingPlanFor(plan);

    if (billingPlan != null && billingPlan.price.trim().isNotEmpty) {
      return billingPlan.price;
    }

    return _fallbackPriceForPlan(plan);
  }

  String _periodForPlan(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return '/ month';
      case PremiumPlan.threeMonths:
        return '/ 3 months';
      case PremiumPlan.sixMonths:
        return '/ 6 months';
      case PremiumPlan.yearly:
        return '/ year';
    }
  }

  String _subtitleForPlan(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return 'Flexible access for focused study';
      case PremiumPlan.threeMonths:
        return 'Great for one exam cycle';
      case PremiumPlan.sixMonths:
        return 'Extended prep and repetition';
      case PremiumPlan.yearly:
        return 'Best for long-term mastery';
    }
  }

  String get _selectedPlanLabel {
    switch (_selectedPlan) {
      case PremiumPlan.monthly:
        return 'Monthly';
      case PremiumPlan.threeMonths:
        return '3 Months';
      case PremiumPlan.sixMonths:
        return '6 Months';
      case PremiumPlan.yearly:
        return '1 Year';
    }
  }

  Future<void> _handleSubscribe() async {
    if (!_hasPlans) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subscription plans are not available yet. Make sure all base plans are active in Play Console and install from the Play testing or production link.',
          ),
        ),
      );
      return;
    }

    final String basePlanId = _basePlanIdForPlan(_selectedPlan);

    setState(() => _loading = true);

    try {
      await _billing.buySubscriptionByBasePlanId(basePlanId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting $_selectedPlanLabel plan...'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _loading = true);

    try {
      await _billing.refreshSubscriptionStatus();

      if (!mounted) return;

      final bool active = SubscriptionGuard.hasPremiumAccess;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active
                ? 'Premium access restored.'
                : 'No active subscription found.',
          ),
        ),
      );

      if (active) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openExternalLink(String url) async {
    final Uri uri = Uri.parse(url);

    final bool ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'MuscleMind Premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _blue.withOpacity(0.30)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.22),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo/musclemind_icon.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UNLOCK MUSCLEMIND PREMIUM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _blue,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Get full access to all MCQ lessons, all OSCE stations, full exam mode, and advanced review tools.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _featureCard('All MCQ lessons'),
              _featureCard('All OSCE stations'),
              _featureCard('Full OSCE exam mode'),
              _featureCard('Advanced review and feedback'),

              const SizedBox(height: 20),
              Text(
                'Choose your plan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.96),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              _planCard(
                plan: PremiumPlan.monthly,
                title: 'Monthly',
                price: _priceForPlan(PremiumPlan.monthly),
                period: _periodForPlan(PremiumPlan.monthly),
              ),
              _planCard(
                plan: PremiumPlan.threeMonths,
                title: '3 Months',
                price: _priceForPlan(PremiumPlan.threeMonths),
                period: _periodForPlan(PremiumPlan.threeMonths),
              ),
              _planCard(
                plan: PremiumPlan.sixMonths,
                title: '6 Months',
                price: _priceForPlan(PremiumPlan.sixMonths),
                period: _periodForPlan(PremiumPlan.sixMonths),
              ),
              _planCard(
                plan: PremiumPlan.yearly,
                title: '1 Year',
                price: _priceForPlan(PremiumPlan.yearly),
                period: _periodForPlan(PremiumPlan.yearly),
                badge: 'BEST VALUE',
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _blue.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    if (_initializing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: CircularProgressIndicator(),
                      ),

                    Text(
                      '${_priceForPlan(_selectedPlan)} ${_periodForPlan(_selectedPlan)}',
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _subtitleForPlan(_selectedPlan),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_loading || _initializing)
                            ? null
                            : _handleSubscribe,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _hasPlans
                                    ? 'Start $_selectedPlanLabel Plan'
                                    : 'Premium Unavailable',
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed:
                          (_loading || _initializing) ? null : _handleRestore,
                      child: const Text('Restore Purchase'),
                    ),

                    if (!_hasPlans) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tip: billing plans usually load only when the subscription and all base plans are active in Play Console and the app is installed from your Play testing or production link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Subscriptions renew automatically unless cancelled before the end of the billing period.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => _openExternalLink(_privacyUrl),
                    child: const Text('Privacy Policy'),
                  ),
                  Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _loading ? null : () => _openExternalLink(_termsUrl),
                    child: const Text('Terms of Use'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LuxTheme.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _blue.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: _blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard({
    required PremiumPlan plan,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final bool selected = _selectedPlan == plan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _loading ? null : () => setState(() => _selectedPlan = plan),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? _blue.withOpacity(0.10) : LuxTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _blue : _blue.withOpacity(0.22),
              width: selected ? 1.6 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _blue.withOpacity(0.10),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: _blue,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _blue.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _blue.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: _blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitleForPlan(plan),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    period,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}