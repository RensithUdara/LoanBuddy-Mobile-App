import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/loan_provider.dart';
import 'controllers/payment_provider.dart';
import 'controllers/report_provider.dart';
import 'controllers/settings_provider.dart';
// Commented out to fix build error
// import 'services/simple_notification_service.dart';
import 'utils/app_utils.dart';
import 'views/screens/new_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notification service commented out as it's not needed at this stage
  // await SimpleNotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up multi-providers for state management
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProxyProvider<LoanProvider, PaymentProvider>(
          create: (context) => PaymentProvider(
              Provider.of<LoanProvider>(context, listen: false)),
          update: (context, loanProvider, previous) =>
              previous ?? PaymentProvider(loanProvider),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'LoanBuddy',
            debugShowCheckedModeBanner: false,
            theme: settingsProvider.isDarkMode
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
