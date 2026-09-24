import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_strings.dart';
import 'routes/app_routes.dart';
import 'screens/splash/splash_screen.dart';
import 'services/firebase_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with graceful fallback
  await QuickRideFirebaseService().initialize();

  // Configure modern edge-to-edge transparent system overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const QuickRideApp());
}

/// Root Widget for the QuickRide User Application.
class QuickRideApp extends StatelessWidget {
  const QuickRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: SettingsService().themeMode,
          onGenerateRoute: AppRoutes.generateRoute,
          home: const SplashScreen(),
        );
      },
    );
  }
}

