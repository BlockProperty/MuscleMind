import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import '../widgets/shimmer.dart';
import '../osce/stations/stations_menu_screen.dart';
import 'osce_exam_guide_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      body: LuxBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandHero(),
                    const SizedBox(height: 22),
                    _LuxDivider(),
                    const SizedBox(height: 18),
                    _LuxAction(
                      title: 'MCQ Practice',
                      subtitle: 'Timed lessons • Exam mode • Resume support',
                      onTap: () {
                        Navigator.of(context).pushNamed('/category');
                      },
                    ),
                    const SizedBox(height: 16),
                    _LuxAction(
                      title: 'OSCE Stations',
                      subtitle: 'Practice stations or run full OSCE exams',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StationsMenuScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _LuxAction(
                      title: 'OSCE Blueprint',
                      subtitle:
                          'Premium step-by-step exam guide for massage therapy students',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OsceExamGuideScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _LuxDivider(),
                    const SizedBox(height: 18),
                    Text(
                      'Luxury learning. Real exam pressure.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.50),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LuxTheme.panel.withOpacity(0.95),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _blue.withOpacity(0.65),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.18),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: _blue,
                        size: 22,
                      ),
                    ),
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

class _BrandHero extends StatelessWidget {
  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _blue.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.08),
            blurRadius: 20,
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
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo/musclemind_icon.png',
              width: 110,
              height: 110,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'MUSCLEMIND',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _blue,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'MCQs and OSCE simulations designed to build confidence under real exam pressure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxDivider extends StatelessWidget {
  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: _blue.withOpacity(0.18),
    );
  }
}

class _LuxAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LuxAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Shimmer(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _blue.withOpacity(0.50)),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _blue),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: _blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
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