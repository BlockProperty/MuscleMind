import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import '../osce/stations/stations_menu_screen.dart';
import 'osce_exam_guide_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _accent = LuxTheme.accentGlow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      body: LuxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  onSettings: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const _BrandHero(),
                const SizedBox(height: 22),
                const Text(
                  'Choose your training mode',
                  style: TextStyle(
                    color: LuxTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Build knowledge, rehearse clinical performance, and prepare for exam day.',
                  style: TextStyle(
                    color: LuxTheme.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _TrainingCard(
                  icon: Icons.quiz_outlined,
                  eyebrow: 'KNOWLEDGE',
                  title: 'MCQ Practice',
                  subtitle: 'Focused lessons, timed practice and comprehensive review.',
                  detail: '6 categories • 50 questions per lesson',
                  onTap: () => Navigator.of(context).pushNamed('/category'),
                ),
                const SizedBox(height: 14),
                _TrainingCard(
                  icon: Icons.medical_services_outlined,
                  eyebrow: 'CLINICAL PERFORMANCE',
                  title: 'OSCE Stations',
                  subtitle: 'Rehearse station flow, timing and hands-on clinical reasoning.',
                  detail: 'Practice mode • Exam simulation',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StationsMenuScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _TrainingCard(
                  icon: Icons.route_outlined,
                  eyebrow: 'EXAM STRATEGY',
                  title: 'OSCE Blueprint',
                  subtitle: 'Review a structured step-by-step guide before you enter a station.',
                  detail: 'Premium exam preparation guide',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OsceExamGuideScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                const _ExamReadyBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;

  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'MUSCLEMIND',
                style: TextStyle(
                  color: HomeScreen._accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Massage Therapy Exam Prep',
                style: TextStyle(
                  color: LuxTheme.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Settings',
          onPressed: onSettings,
          style: IconButton.styleFrom(
            backgroundColor: LuxTheme.panel,
            foregroundColor: HomeScreen._accent,
            side: BorderSide(color: HomeScreen._accent.withValues(alpha: 0.22)),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: HomeScreen._accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxTheme.panelAlt,
              border: Border.all(
                color: HomeScreen._accent.withValues(alpha: 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: HomeScreen._accent.withValues(alpha: 0.13),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset('assets/logo/musclemind_icon.png'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Train with purpose.\nPerform with confidence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LuxTheme.textPrimary,
              fontSize: 25,
              height: 1.18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'One focused space for MCQ knowledge and OSCE performance preparation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LuxTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Pill(icon: Icons.timer_outlined, label: 'Timed practice'),
              _Pill(icon: Icons.school_outlined, label: 'Exam focused'),
              _Pill(icon: Icons.replay_outlined, label: 'Practice again'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: LuxTheme.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HomeScreen._accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: HomeScreen._accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: LuxTheme.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  const _TrainingCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: HomeScreen._accent.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: LuxTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: HomeScreen._accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: HomeScreen._accent, size: 25),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: HomeScreen._accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: LuxTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LuxTheme.textSecondary,
                        fontSize: 12.8,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      detail,
                      style: TextStyle(
                        color: LuxTheme.textPrimary.withValues(alpha: 0.76),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 13),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: HomeScreen._accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamReadyBanner extends StatelessWidget {
  const _ExamReadyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: LuxTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LuxTheme.primary.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.psychology_alt_outlined, color: HomeScreen._accent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Small, consistent practice sessions can make exam-day decisions feel more familiar.',
              style: TextStyle(
                color: LuxTheme.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
