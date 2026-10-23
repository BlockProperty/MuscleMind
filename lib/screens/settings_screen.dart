import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/billing_service.dart';
import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _blue = Color(0xFF39C2FF);

  static const String _privacyUrl =
      'https://sites.google.com/view/musclemind-app/privacy-policy';

  static const String _termsUrl =
      'https://sites.google.com/view/musclemind-app/terms-of-use';

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.propertyblocks.musclemind';

  String _versionText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionText = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionText = 'Unavailable';
      });
    }
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link.')),
      );
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out MuscleMind on Google Play:\n$_playStoreUrl',
      subject: 'MuscleMind App',
    );
  }

  Future<void> _openPlayStore() async {
    await _openExternalLink(_playStoreUrl);
  }

  void _openInfoPage({
    required String title,
    required String content,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InfoPage(
          title: title,
          content: content,
        ),
      ),
    );
  }

  Future<void> _restorePurchase() async {
    try {
      await BillingService().restorePurchases();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase restored if available')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      body: LuxBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
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
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    const _SectionTitle('General'),
                    _SettingsCard(
                      title: 'Share App',
                      icon: Icons.share_outlined,
                      onTap: _shareApp,
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Rate App',
                      icon: Icons.star_outline,
                      onTap: _openPlayStore,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Information'),
                    _SettingsCard(
                      title: 'About MuscleMind',
                      icon: Icons.info_outline,
                      onTap: () => _openInfoPage(
                        title: 'About MuscleMind',
                        content: '''
MuscleMind is a learning and exam preparation platform designed to support massage therapy students and professionals in mastering key concepts and OSCE performance.

The app provides:
• Multiple choice questions
• OSCE simulations
• Timed exam practice
• Structured lessons

Our goal is to help users build confidence, improve knowledge retention, and succeed in their licensing exams.

MuscleMind is intended for educational purposes only.
''',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Privacy Policy',
                      icon: Icons.open_in_new,
                      onTap: () => _openExternalLink(_privacyUrl),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Terms of Use',
                      icon: Icons.open_in_new,
                      onTap: () => _openExternalLink(_termsUrl),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Disclaimer',
                      icon: Icons.gavel_outlined,
                      onTap: () => _openInfoPage(
                        title: 'Disclaimer',
                        content: '''
MuscleMind is intended for educational and exam preparation purposes only.

This application does not provide medical advice, diagnosis, or treatment.

Users should consult a qualified healthcare professional for medical concerns.

MuscleMind is not affiliated with any official licensing body.
''',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Support'),
                    _SettingsCard(
                      title: 'Contact Support',
                      icon: Icons.mail_outline,
                      onTap: () => _openInfoPage(
                        title: 'Contact Support',
                        content: '''
propertyblocks.g@gmail.com

We welcome bug reports, feature suggestions, and subscription inquiries.
''',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      title: 'Restore Purchase',
                      icon: Icons.refresh,
                      onTap: _restorePurchase,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('App'),
                    _SettingsCard(
                      title: 'App Version',
                      icon: Icons.info_outline,
                      onTap: () => _openInfoPage(
                        title: 'App Version',
                        content: 'Current version: $_versionText',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  static const Color _blue = Color(0xFF39C2FF);

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: LuxTheme.panel.withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _blue.withOpacity(0.55)),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.10),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: _blue, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      body: LuxBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: LuxTheme.panel.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF39C2FF).withOpacity(0.45),
                        ),
                      ),
                      child: Text(
                        content,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.84),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
