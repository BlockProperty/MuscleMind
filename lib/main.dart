import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/billing_service.dart';
import 'core/subscription_guard.dart';
import 'firebase_options.dart';
import 'osce/stations/stations_menu_screen.dart';
import 'screens/animated_splash_screen.dart';
import 'screens/category_screen.dart';
import 'theme/lux_theme.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Something went wrong.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      };

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await Hive.initFlutter();

      if (!Hive.isBoxOpen('mcq_attempts')) {
        await Hive.openBox('mcq_attempts');
      }

      if (!Hive.isBoxOpen('subscription_box')) {
        await Hive.openBox('subscription_box');
      }

      await SubscriptionGuard.init();

      try {
        await BillingService().init();
      } catch (e, stack) {
        await SubscriptionGuard.deactivatePremium();

        debugPrint('Billing init failed: $e');
        debugPrintStack(stackTrace: stack);
      }

      runApp(const MuscleMindApp());
    },
    (Object error, StackTrace stack) async {
      try {
        await SubscriptionGuard.deactivatePremium();
      } catch (_) {}

      debugPrint('UNCAUGHT APP ERROR: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MuscleMindApp extends StatelessWidget {
  const MuscleMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuscleMind',
      debugShowCheckedModeBanner: false,
      theme: LuxTheme.dark(),
      home: const AnimatedSplashScreen(),
      routes: {
        '/category': (_) => const CategoryScreen(),
        StationsMenuScreen.routeName: (_) => const StationsMenuScreen(),
      },
    );
  }
}