import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  String _currency = 'Rs.';
  bool _useNotifications = true;
  String _reminderTime = '10:00';

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  bool get useNotifications => _useNotifications;
  String get reminderTime => _reminderTime;

  // Constructor - Load settings
  SettingsProvider() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    _currency = _prefs?.getString('currency') ?? 'Rs.';
    _useNotifications = _prefs?.getBool('useNotifications') ?? true;
    _reminderTime = _prefs?.getString('reminderTime') ?? '10:00';
    notifyListeners();
  }

  // Update dark mode setting
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs?.setBool('isDarkMode', value);
    notifyListeners();
  }

  // Update currency setting
  Future<void> setCurrency(String value) async {
    _currency = value;
    await _prefs?.setString('currency', value);
    notifyListeners();
  }

  // Update notifications setting
  Future<void> setUseNotifications(bool value) async {
    _useNotifications = value;
    await _prefs?.setBool('useNotifications', value);
    notifyListeners();
  }

  // Update reminder time
  Future<void> setReminderTime(String value) async {
    _reminderTime = value;
    await _prefs?.setString('reminderTime', value);
    notifyListeners();
  }

  // Reset all settings to default
  Future<void> resetSettings() async {
    _isDarkMode = false;
    _currency = 'Rs.';
    _useNotifications = true;
    _reminderTime = '10:00';

    await _prefs?.setBool('isDarkMode', false);
    await _prefs?.setString('currency', 'Rs.');
    await _prefs?.setBool('useNotifications', true);
    await _prefs?.setString('reminderTime', '10:00');

    notifyListeners();
  }
}
