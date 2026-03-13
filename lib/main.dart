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
    return MaterialApp(
      title: '暖備 WarmMemo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C8383),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
