
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Memuat konfigurasi dari file .env
  await dotenv.load(fileName: '.env');

  runApp(const LabIotLogbookApp());
}

class LabIotLogbookApp extends StatefulWidget {
  const LabIotLogbookApp({super.key});

  @override
  State<LabIotLogbookApp> createState() => _LabIotLogbookAppState();
}

class _LabIotLogbookAppState extends State<LabIotLogbookApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabIotLogbook',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: MainScreen(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
