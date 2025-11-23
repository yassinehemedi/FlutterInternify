import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/db_helper.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

/// Main entry point of the Internify app
void main() async {


  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const InternifyApp());
}

/// Main application widget
class InternifyApp extends StatelessWidget {
  const InternifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}