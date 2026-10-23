import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';

class OsceExamGuideScreen extends StatelessWidget {
  const OsceExamGuideScreen({super.key});

  static const String routeName = '/osce-exam-guide';
  static const String _productUrl = 'https://lifestestsandtestimonies.com/products/';

  Future<void> _openLink(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link right now. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong while opening the page.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('OSCE Blueprint'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: LuxTheme.accentGlow.withValues(alpha: 0.18),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: LuxTheme.accentGlow.withValues(alpha: 0.08),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: LuxTheme.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Premium Study Resource',
                          style: textTheme.labelMedium?.copyWith(
                            color: LuxTheme.accentGlow,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pass Your OSCE With More Structure, Clarity, and Confidence',
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'The MuscleMind OSCE Blueprint is a step-by-step exam guide designed for massage therapy students preparing for practical exam success.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _FeatureBullet(
                        text: 'Covers all 7 OSCE stations',
                      ),
                      const SizedBox(height: 10),
                      _FeatureBullet(
                        text: 'Built around real exam-style structure',
                      ),
                      const SizedBox(height: 10),
                      _FeatureBullet(
                        text: 'Helps you prepare with more confidence',
                      ),
                      const SizedBox(height: 10),
                      _FeatureBullet(
                        text: 'Instant access through our website',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'What You Get',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This blueprint is designed to support your OSCE preparation with a clear, organized, and premium study experience.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        runSpacing: 10,
                        spacing: 10,
                        children: const <Widget>[
                          _InfoChip(label: '80-page guide'),
                          _InfoChip(label: 'Structured walkthrough'),
                          _InfoChip(label: 'Massage therapy focused'),
                          _InfoChip(label: 'External purchase link'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _PrimaryActionButton(
                  label: 'Get Full OSCE Blueprint',
                  onPressed: () => _openLink(context, _productUrl),
                ),
                const SizedBox(height: 12),
                _SecondaryActionButton(
                  label: 'Open Product Page',
                  onPressed: () => _openLink(context, _productUrl),
                ),
                const SizedBox(height: 18),
                Text(
                  'Purchases are completed securely on our website.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: LuxTheme.primary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: LuxTheme.accentGlow.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.check,
            size: 14,
            color: LuxTheme.accentGlow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LuxTheme.primaryDark.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LuxTheme.accentGlow.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuxTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: LuxTheme.accentGlow.withValues(alpha: 0.22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}