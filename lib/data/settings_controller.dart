import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network_guard.dart';

enum QualityTier { low, balanced, high }

extension QualityTierX on QualityTier {
  String get label => switch (this) {
        QualityTier.low => 'Low (data saver)',
        QualityTier.balanced => 'Balanced',
        QualityTier.high => 'High',
      };
}

/// User preferences, persisted locally. Nothing leaves the device.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs, this.guard) {
    guard.blocked = _prefs.getBool(_kBlock) ?? false;
  }

  static const _kBlock = 'block_network';
  static const _kQuality = 'quality';
  static const _kAccent = 'accent';
  static const _kShared = 'scan_shared';

  final SharedPreferences _prefs;
  final NetworkGuard guard;

  static Future<SettingsController> load(NetworkGuard guard) async =>
      SettingsController._(await SharedPreferences.getInstance(), guard);

  bool get blockNetwork => guard.blocked;
  QualityTier get quality =>
      QualityTier.values[(_prefs.getInt(_kQuality) ?? 2).clamp(0, 2)];
  int get accentIndex => _prefs.getInt(_kAccent) ?? 0;
  bool get scanShared => _prefs.getBool(_kShared) ?? true;

  Future<void> setBlockNetwork(bool v) async {
    guard.blocked = v;
    await _prefs.setBool(_kBlock, v);
    notifyListeners();
  }

  Future<void> setQuality(QualityTier q) async {
    await _prefs.setInt(_kQuality, q.index);
    notifyListeners();
  }

  Future<void> setAccent(int i) async {
    await _prefs.setInt(_kAccent, i);
    notifyListeners();
  }

  Future<void> setScanShared(bool v) async {
    await _prefs.setBool(_kShared, v);
    notifyListeners();
  }
}
