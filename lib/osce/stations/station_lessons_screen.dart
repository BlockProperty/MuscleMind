import 'package:flutter/material.dart';

import '../../core/subscription_guard.dart';
import '../../theme/lux_theme.dart';
import '../../widgets/lux_background.dart';
import '../../widgets/shimmer.dart';
import '../../screens/paywall_screen.dart';
import 'osce_station_loader_screen.dart';

class StationLessonsScreen extends StatelessWidget {
  final String stationId;
  final String stationTitle;
  final int lessonCount;

  const StationLessonsScreen({
    super.key,
    required this.stationId,
    required this.stationTitle,
    this.lessonCount = 10,
  });

  static const Color _blue = Color(0xFF39C2FF);

  String _lessonId(int index) {
    final lessonNumber = index + 1;
    return 'lesson_${lessonNumber.toString().padLeft(2, '0')}';
  }

  int _lessonNumberFromId(String lessonId) {
    final match = RegExp(r'\d+').firstMatch(lessonId);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  String _lessonTitle(int index) => 'Lesson ${index + 1}';

  /// 🔥 UPDATED UNLOCK LOGIC (PRODUCTION SAFE)
  bool _isLessonUnlocked({
    required String stationId,
    required int lessonNumber,
  }) {
    // ✅ FREE CONTENT RULE
    if (stationId == 'therapeutic_exercise' && lessonNumber == 1) {
      return true;
    }

    // ✅ PREMIUM USERS
    if (SubscriptionGuard.isPremium) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final lessons = List.generate(
      lessonCount,
      (index) => _LessonMenuItem(
        lessonId: _lessonId(index),
        lessonTitle: _lessonTitle(index),
      ),
    );

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: Text(stationTitle),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: Column(
          children: [
            // 🔷 HEADER CARD
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _blue.withOpacity(0.30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationTitle.toUpperCase(),
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a lesson to begin OSCE simulation.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔷 LESSON LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final item = lessons[index];
                  final lessonNumber = _lessonNumberFromId(item.lessonId);

                  final isUnlocked = _isLessonUnlocked(
                    stationId: stationId,
                    lessonNumber: lessonNumber,
                  );

                  final isFree =
                      stationId == 'therapeutic_exercise' && lessonNumber == 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LessonCard(
                      item: item,
                      stationId: stationId,
                      isUnlocked: isUnlocked,
                      isFree: isFree,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final _LessonMenuItem item;
  final String stationId;
  final bool isUnlocked;
  final bool isFree;

  const _LessonCard({
    required this.item,
    required this.stationId,
    required this.isUnlocked,
    required this.isFree,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (!isUnlocked) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PaywallScreen(),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OsceStationLoaderScreen(
                stationId: stationId,
                lessonId: item.lessonId,
              ),
            ),
          );
        },
        child: Shimmer(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnlocked
                    ? _blue.withOpacity(0.45)
                    : Colors.white.withOpacity(0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUnlocked ? Icons.menu_book : Icons.lock,
                  color: isUnlocked ? _blue : Colors.white70,
                ),
                const SizedBox(width: 12),

                // 🔥 TITLE
                Expanded(
                  child: Text(
                    item.lessonTitle,
                    style: TextStyle(
                      color: isUnlocked ? _blue : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // 🔥 TAG (FREE / PREMIUM)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFree
                        ? _blue.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isFree ? "FREE" : "PREMIUM",
                    style: TextStyle(
                      color: isFree ? _blue : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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
}

class _LessonMenuItem {
  final String lessonId;
  final String lessonTitle;

  const _LessonMenuItem({
    required this.lessonId,
    required this.lessonTitle,
  });
}
