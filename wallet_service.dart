
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  late SharedPreferences _prefs;
  final ValueNotifier<double> balanceNotifier = ValueNotifier(0.0);

  // Business rules
  final double perAd = 0.25; // ₹0.25 per rewarded ad
  final double dailyCap = 5.0; // max ₹5.00 per day

  double todayEarning = 0.0;
  DateTime _today = DateTime.now();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    _rolloverIfNeeded();
  }

  void _load() {
    final bal = _prefs.getDouble('balance') ?? 0.0;
    balanceNotifier.value = bal;

    final todayStr = _prefs.getString('today') ?? _dateKey(DateTime.now());
    final earn = _prefs.getDouble('todayEarning') ?? 0.0;
    _today = _dateFromKey(todayStr);
    todayEarning = earn;
  }

  void _save() {
    _prefs.setDouble('balance', balanceNotifier.value);
    _prefs.setString('today', _dateKey(_today));
    _prefs.setDouble('todayEarning', todayEarning);
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  DateTime _dateFromKey(String s) {
    final p = s.split('-').map((e) => int.parse(e)).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  void _rolloverIfNeeded() {
    final now = DateTime.now();
    final nowKey = _dateKey(now);
    if (_dateKey(_today) != nowKey) {
      _today = now;
      todayEarning = 0.0;
      _save();
    }
  }

  bool addEarningPerAd() {
    _rolloverIfNeeded();
    if (todayEarning + perAd > dailyCap + 1e-6) {
      return false;
    }
    todayEarning += perAd;
    balanceNotifier.value += perAd;
    _save();
    return true;
  }

  bool withdrawAll() {
    if (balanceNotifier.value <= 0.0) return false;
    balanceNotifier.value = 0.0;
    _save();
    return true;
  }
}
