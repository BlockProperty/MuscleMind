import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class SubscriptionGuard {
  static const String _boxName = 'subscription_box';

  static const String _premiumKey = 'is_premium';
  static const String _devUnlockKey = 'dev_force_unlock';

  static bool _isPremium = false;
  static bool _devForceUnlock = false;
  static bool _initialized = false;

  static bool get isPremium => _isPremium || _effectiveDevUnlock;
  static bool get hasPremiumAccess => isPremium;

  static bool get storedPremium => _isPremium;
  static bool get devForceUnlock => _effectiveDevUnlock;
  static bool get isInitialized => _initialized;

  static bool get _effectiveDevUnlock => kDebugMode && _devForceUnlock;

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  static Future<void> init() async {
    final Box box = await _openBox();

    _isPremium = (box.get(_premiumKey, defaultValue: false) as bool?) ?? false;

    final bool storedDevUnlock =
        (box.get(_devUnlockKey, defaultValue: false) as bool?) ?? false;

    if (kDebugMode) {
      _devForceUnlock = storedDevUnlock;
    } else {
      _devForceUnlock = false;

      // Safety:
      // Never allow dev unlock to remain stored in production.
      await box.put(_devUnlockKey, false);
    }

    _initialized = true;
  }

  static Future<void> activatePremium() async {
    _isPremium = true;

    final Box box = await _openBox();
    await box.put(_premiumKey, true);
  }

  static Future<void> deactivatePremium() async {
    _isPremium = false;

    final Box box = await _openBox();
    await box.put(_premiumKey, false);

    if (!kDebugMode) {
      _devForceUnlock = false;
      await box.put(_devUnlockKey, false);
    }
  }

  static Future<void> reset() async {
    _isPremium = false;
    _devForceUnlock = false;

    final Box box = await _openBox();
    await box.put(_premiumKey, false);
    await box.put(_devUnlockKey, false);
  }

  static Future<void> enableDevUnlock() async {
    if (!kDebugMode) return;

    _devForceUnlock = true;

    final Box box = await _openBox();
    await box.put(_devUnlockKey, true);
  }

  static Future<void> disableDevUnlock() async {
    _devForceUnlock = false;

    final Box box = await _openBox();
    await box.put(_devUnlockKey, false);
  }

  static Future<void> toggleDevUnlock() async {
    if (!kDebugMode) return;

    _devForceUnlock = !_devForceUnlock;

    final Box box = await _openBox();
    await box.put(_devUnlockKey, _devForceUnlock);
  }
}