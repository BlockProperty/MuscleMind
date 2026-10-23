import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text('About MuscleMind'),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _blue.withOpacity(0.28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _blue.withOpacity(0.18),
                              blurRadius: 26,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo/musclemind_icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ABOUT MUSCLEMIND',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _blue,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Built to support massage therapy learning, structured practice, and exam confidence.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.74),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'What MuscleMind Offers',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _BulletPoint(text: 'Multiple choice question practice'),
                      SizedBox(height: 10),
                      _BulletPoint(text: 'OSCE simulations'),
                      SizedBox(height: 10),
                      _BulletPoint(text: 'Timed exam preparation'),
                      SizedBox(height: 10),
                      _BulletPoint(text: 'Structured lesson-based learning'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Our Goal',
                  child: Text(
                    'MuscleMind is designed to help users strengthen knowledge retention, improve exam readiness, and build confidence through repeated practice.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.76),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Educational Use',
                  child: Text(
                    'MuscleMind is intended for educational and exam preparation purposes only. It is not a substitute for professional training, certification, or clinical judgment.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.76),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _blue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.check_circle,
            size: 16,
            color: _blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
