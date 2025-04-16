import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:expense_eye/providers/theme_provider.dart';
import 'package:expense_eye/screens/home_screen.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const ExpenseEyeApp());
}

class ExpenseEyeApp extends StatelessWidget {
  const ExpenseEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6200EE);
    final secondaryColor = const Color(0xFF03DAC5);
    final errorColor = const Color(0xFFCF6679);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ExpenseEye',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.light,
                primary: primaryColor,
                onPrimary: Colors.white,
                secondary: secondaryColor,
                onSecondary: Colors.black,
                error: errorColor,
                surface: Colors.white,
                onSurface: Colors.black87,
                tertiary: const Color(0xFFFF7597),
              ),
              textTheme: GoogleFonts.poppinsTextTheme().copyWith(
                displayLarge: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                displayMedium: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                titleLarge: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                ),
                titleMedium: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                bodyLarge: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                bodyMedium: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                labelLarge: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shadowColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
              ),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 4,
                shadowColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.2,
                ),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                elevation: 8,
                shadowColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.1,
                ),
                backgroundColor: Colors.white,
                indicatorColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.12,
                ),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(color: primaryColor);
                  }
                  return const IconThemeData(color: Colors.grey);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    );
                  }
                  return GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  );
                }),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.05,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintStyle: TextStyle(color: Colors.grey[500]),
                labelStyle: TextStyle(color: Colors.grey[700]),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.black87,
                contentTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dialogTheme: DialogTheme(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.08,
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.dark,
                primary: primaryColor,
                onPrimary: Colors.white,
                secondary: secondaryColor,
                onSecondary: Colors.black,
                error: errorColor,
                surface: const Color(0xFF121212),
                onSurface: Colors.white,
                tertiary: const Color(0xFFFF7597),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme:
                  GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
                      .copyWith(
                displayLarge: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
                displayMedium: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
                titleLarge: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.25,
                  color: Colors.white,
                ),
                titleMedium: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                bodyLarge: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
                bodyMedium: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
                labelLarge: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shadowColor: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.3,
                ),
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
              ),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 4,
                shadowColor: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.3,
                ),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                elevation: 8,
                shadowColor: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.3,
                ),
                backgroundColor: const Color(0xFF1E1E1E),
                indicatorColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.2,
                ),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(color: primaryColor);
                  }
                  return const IconThemeData(color: Colors.grey);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    );
                  }
                  return GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[400],
                  );
                }),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white.withValues(
                  red: 255,
                  green: 255,
                  blue: 255,
                  alpha: 0.05,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintStyle: TextStyle(color: Colors.grey[500]),
                labelStyle: TextStyle(color: Colors.grey[400]),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.grey[800],
                contentTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dialogTheme: DialogTheme(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: primaryColor.withValues(
                  red: primaryColor.r.toDouble(),
                  green: primaryColor.g.toDouble(),
                  blue: primaryColor.b.toDouble(),
                  alpha: 0.15,
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
