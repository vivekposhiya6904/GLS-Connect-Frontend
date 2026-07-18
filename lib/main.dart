import 'package:alumni_management/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager(),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeManager().themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
