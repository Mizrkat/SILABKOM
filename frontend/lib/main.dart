import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/session_manager.dart';
import 'screens/auth/login_screen.dart';
import 'screens/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi API URL (baik default 10.0.2.2/localhost maupun custom IP yang pernah disimpan)
  await SessionManager.initApiUrl();

  final bool loggedIn = await SessionManager.isLoggedIn();

  runApp(LabInventoryApp(isLoggedIn: loggedIn));
}

class LabInventoryApp extends StatelessWidget {
  final bool isLoggedIn;

  const LabInventoryApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return MaterialApp(
      title: 'SILABKOM - Lab Tekkom UNDIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
    );
  }
}
