import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return ListView(
            children: [
              _buildSwitchSetting(
                title: 'Dark Mode',
                subtitle: 'Enable dark theme for the app',
                value: settingsProvider.isDarkMode,
                onChanged: (value) {
                  settingsProvider.setDarkMode(value);
                },
                icon: Icons.dark_mode,
              ),
              const Divider(),
              _buildSwitchSetting(
                title: 'Notifications',
                subtitle: 'Receive reminders for due loans',
                value: settingsProvider.useNotifications,
                onChanged: (value) {
                  settingsProvider.setUseNotifications(value);
                },
                icon: Icons.notifications,
              ),
              if (settingsProvider.useNotifications)
                _buildTimeSetting(
                  title: 'Reminder Time',
                  subtitle: 'Set the time for daily reminders',
                  value: settingsProvider.reminderTime,
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.setReminderTime(value);
                    }
                  },
                  icon: Icons.access_time,
                ),
              const Divider(),
              _buildCurrencySetting(
                title: 'Currency',
                subtitle: 'Change the currency symbol',
                value: settingsProvider.currency,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setCurrency(value);
                  }
                },
                icon: Icons.currency_exchange,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset Settings'),
                subtitle: const Text('Restore all settings to default values'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Settings'),
                      content: const Text(
                          'Are you sure you want to reset all settings to their default values?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            settingsProvider.resetSettings();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Settings reset to defaults')),
                            );
                          },
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('LoanBuddy v1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'LoanBuddy',
                    applicationVersion: '1.0.0',
                    applicationIcon:
                        const Icon(Icons.account_balance, size: 32),
                    children: [
                      const Text(
                          'LoanBuddy helps you keep track of your personal loans and send payment reminders via WhatsApp.'),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimeSetting({
    required String title,
    required String subtitle,
    required String value,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: TextButton(
        child: Text(value),
        onPressed: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: int.parse(value.split(':')[0]),
              minute: int.parse(value.split(':')[1]),
            ),
          );
          if (picked != null) {
            onChanged(
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
          }
        },
      ),
    );
  }

  Widget _buildCurrencySetting({
    required String title,
    required String subtitle,
    required String value,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: const [
          DropdownMenuItem(value: 'Rs.', child: Text('Rs. (INR)')),
          DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
          DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
          DropdownMenuItem(value: '£', child: Text('£ (GBP)')),
        ],
      ),
    );
  }
}
