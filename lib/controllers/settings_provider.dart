import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_model.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  String _currency = 'Rs.';
  bool _useNotifications = true;
  String _reminderTime = '10:00';

  // Report Settings
  final ReportType _defaultReportType = ReportType.summary;
  final DateFilterType _defaultDateFilter = DateFilterType.thisMonth;
  final bool _includeCharts = true;
  final String _exportFormat = 'PDF'; // PDF or CSV

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  bool get useNotifications => _useNotifications;
  String get reminderTime => _reminderTime;

  // Report Settings Getters
  ReportType get defaultReportType => _defaultReportType;
  DateFilterType get defaultDateFilter => _defaultDateFilter;
  bool get includeCharts => _includeCharts;
  String get exportFormat => _exportFormat;

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
    
    // Load report settings
    final savedReportType = _prefs?.getString('defaultReportType');
    if (savedReportType != null) {
      _defaultReportType = ReportType.values.firstWhere(
        (type) => type.name == savedReportType,
        orElse: () => ReportType.summary,
      );
    }
    
    final savedDateFilter = _prefs?.getString('defaultDateFilter');
    if (savedDateFilter != null) {
      _defaultDateFilter = DateFilterType.values.firstWhere(
        (type) => type.name == savedDateFilter,
        orElse: () => DateFilterType.thisMonth,
      );
    }
    
    _includeCharts = _prefs?.getBool('includeCharts') ?? true;
    _exportFormat = _prefs?.getString('exportFormat') ?? 'PDF';
    
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
