import 'package:flutter/services.dart';
import 'package:alumni_management/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'services/fcm_service.dart';
import 'services/notification_navigation_service.dart';
import 'theme/app_theme.dart';
import 'utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ThemeManager().init();
  try {
    await FcmService.initialize();
  } catch (e) {
    debugPrint("Failed to initialize FcmService: $e");
  }
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
          navigatorKey: NotificationNavigationService.navigatorKey,
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
