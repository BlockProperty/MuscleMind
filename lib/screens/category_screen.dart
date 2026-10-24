import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import 'lesson_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  static const List<_CategoryItem> categories = [
    _CategoryItem(
      title: 'Standards of Practice',
      subtitle: 'Ethics, professionalism, consent and documentation',
      icon: Icons.verified_user_outlined,
    ),
    _CategoryItem(
      title: 'Myology',
      subtitle: 'Origins, insertions, actions and innervations',
      icon: Icons.accessibility_new_outlined,
    ),
    _CategoryItem(
      title: 'Massage Techniques and Treatments',
      subtitle: 'Applications, methods, indications and treatment planning',
      icon: Icons.pan_tool_alt_outlined,
    ),
    _CategoryItem(
      title: 'Assessments and Conditions',
      subtitle: 'Orthopedic testing, clinical reasoning and presentations',
      icon: Icons.fact_check_outlined,
    ),
    _CategoryItem(
      title: 'Remedial Exercise',
      subtitle: 'Stretching, strengthening and corrective exercise principles',
      icon: Icons.fitness_center_outlined,
    ),
    _CategoryItem(
      title: 'Comprehensive Review',
      subtitle: 'Mixed review across the major exam domains',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(title: const Text('MCQ Practice')),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              const _PracticeHeader(),
              const SizedBox(height: 20),
              const Text(
                'Select a category',
                style: TextStyle(
                  color: LuxTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Each category contains focused lessons so you can strengthen one area at a time.',
                style: TextStyle(
                  color: LuxTheme.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              ...categories.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(
                    category: entry.value,
                    number: entry.key + 1,
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

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: LuxTheme.accentGlow.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: LuxTheme.panelAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: LuxTheme.accentGlow.withValues(alpha: 0.22),
              ),
            ),
            child: Image.asset('assets/logo/musclemind_icon.png'),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MCQ TRAINING',
                  style: TextStyle(
                    color: LuxTheme.accentGlow,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Build exam-ready knowledge',
                  style: TextStyle(
                    color: LuxTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Practice with focused question sets and revisit weak areas.',
                  style: TextStyle(
                    color: LuxTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;
  final int number;

  const _CategoryCard({required this.category, required this.number});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonScreen(category: category.title),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: LuxTheme.accentGlow.withValues(alpha: 0.17),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: LuxTheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  category.icon,
                  color: LuxTheme.accentGlow,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CATEGORY $number',
                      style: const TextStyle(
                        color: LuxTheme.accentGlow,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: LuxTheme.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        color: LuxTheme.textSecondary,
                        fontSize: 11.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: LuxTheme.accentGlow,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _CategoryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
