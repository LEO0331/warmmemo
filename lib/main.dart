import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/theme/motion_tokens.dart';
import 'data/firebase/auth_service.dart';
import 'firebase_options.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.instance.configurePersistence();
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
      // Web first paint: avoid downloading 20MB+ custom TTF before first render.
      // Keep NotoSansTC on non-web platforms; web uses system CJK fallback stack.
      fontFamily: kIsWeb ? null : 'NotoSansTC',
      fontFamilyFallback: kIsWeb
          ? const [
              'PingFang TC',
              'Microsoft JhengHei',
              'Noto Sans CJK TC',
              'Heiti TC',
              'sans-serif',
            ]
          : null,
      colorScheme: ColorScheme.fromSeed(
        seedColor: warmPrimary,
        primary: warmPrimary,
        secondary: warmSecondary,
        brightness: Brightness.light,
      ),
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontSize: 30,
        height: 1.15,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        height: 1.22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 18,
        height: 1.28,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.55),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.58,
      ),
    );

    return MaterialApp(
      title: '暖備 WarmMemo',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: textTheme,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
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
            animationDuration: MotionTokens.button,
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFFA45A39);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFB96543);
              }
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
              if (states.contains(WidgetState.pressed)) {
                return 1;
              }
              if (states.contains(WidgetState.hovered)) {
                return 3;
              }
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
            animationDuration: MotionTokens.button,
            foregroundColor: const WidgetStatePropertyAll(Color(0xFF7A4C39)),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: warmOutline),
          backgroundColor: const Color(0xFFFFFCFA),
          selectedColor: const Color(0xFFF8E5D8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          labelStyle: const TextStyle(color: Color(0xFF5A3D31), height: 1.25),
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
