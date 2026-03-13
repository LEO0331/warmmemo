import 'package:flutter/material.dart';

import 'features/memorial/memorial_page_tab.dart';
import 'features/obituary/digital_obituary_tab.dart';
import 'features/overview/overview_tab.dart';
import 'features/packages/packages_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// 暖備 WarmMemo
/// 喪葬流程簡化／固定價格方案媒合／數位紀念與訃聞
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const WarmMemoHomePage(),
    );
  }
}

class WarmMemoHomePage extends StatelessWidget {
  const WarmMemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('暖備 WarmMemo'),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.map_outlined), text: '流程總覽'),
              Tab(icon: Icon(Icons.handshake_outlined), text: '固定方案媒合'),
              Tab(icon: Icon(Icons.person_outline), text: '簡易紀念頁'),
              Tab(icon: Icon(Icons.campaign_outlined), text: '數位訃聞'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewTab(),
            PackagesTab(),
            MemorialPageTab(),
            DigitalObituaryTab(),
          ],
        ),
      ),
    );
  }
}

