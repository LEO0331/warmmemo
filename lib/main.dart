import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WarmMemoApp());
}

class WarmMemoApp extends StatelessWidget {
  const WarmMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const warmPrimary = Color(0xFFC8744F);
    const warmSecondary = Color(0xFFDEA47E);
    const warmSurface = Color(0xFFFFF8F2);
    const warmOutline = Color(0xFFE8D7CC);

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansTC',
      colorScheme: ColorScheme.fromSeed(
        seedColor: warmPrimary,
        primary: warmPrimary,
        secondary: warmSecondary,
        brightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: '暖備 WarmMemo',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: warmSurface,
        visualDensity: VisualDensity.comfortable,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF4B352B),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFCFA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: warmOutline),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFDFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: warmOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: warmOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: warmPrimary, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 160),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return const Color(0xFFA45A39);
              if (states.contains(WidgetState.hovered)) return const Color(0xFFB96543);
              return warmPrimary;
            }),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.16);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.white.withValues(alpha: 0.08);
              }
              return null;
            }),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 1;
              if (states.contains(WidgetState.hovered)) return 3;
              return 2;
            }),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 160),
            foregroundColor: const WidgetStatePropertyAll(Color(0xFF7A4C39)),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
                return const BorderSide(color: Color(0xFFCF9B79));
              }
              return const BorderSide(color: warmOutline);
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x33C8744F);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x1FC8744F);
              }
              return null;
            }),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            ),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: warmOutline),
          backgroundColor: const Color(0xFFFFFCFA),
          selectedColor: const Color(0xFFF8E5D8),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          labelStyle: const TextStyle(color: Color(0xFF5A3D31)),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minVerticalPadding: 10,
          minLeadingWidth: 24,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
