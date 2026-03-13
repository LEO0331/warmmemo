import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';

/// TAB 1 – 教育 + 流程總覽 + 商業模式說明
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '在失去親人的當下，\n不用邊掉眼淚邊談價格。',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '暖備 WarmMemo 協助家屬在平常就先了解流程、預先設定自己的偏好，'
              '需要時直接以「固定價格 + 透明內容」媒合合作禮儀公司，'
              '減少臨時匆忙比價與資訊不對稱。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const SectionCard(
              title: '一眼看懂喪葬流程',
              icon: Icons.timeline_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bullet('1. 通報與醫療文件'),
                  Bullet('2. 遺體接運與冰存'),
                  Bullet('3. 家屬討論儀式風格（宗教、規模、預算）'),
                  Bullet('4. 選擇場地與時間（靈堂／會館／火化／安葬）'),
                  Bullet('5. 儀式進行（致詞、祝禱、家祭、公祭等）'),
                  Bullet('6. 火化／土葬／樹葬／海葬等'),
                  Bullet('7. 後續行政（補助申請、撫卹、保險、戶政等）'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionCard(
              title: '教育：傳統知識但用白話說明',
              icon: Icons.menu_book_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('・不同宗教／文化常見儀式的差異（佛教、道教、基督宗教等）'),
                  SizedBox(height: 4),
                  Text('・需要「一定要做」與「可以省略」的項目區分'),
                  SizedBox(height: 4),
                  Text('・家族長輩常見堅持 vs. 年輕世代的實際需求'),
                  SizedBox(height: 4),
                  Text('・政府補助與保險理賠的基本概念'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionCard(
              title: '商業模式（B2C + B2B2C）',
              icon: Icons.business_center_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('・對家屬：平台提供透明「固定價格方案」，無額外臨時加價'),
                  SizedBox(height: 4),
                  Text('・對禮儀公司：平台收取媒合服務費，幫忙穩定接案'),
                  SizedBox(height: 4),
                  Text('・每一個方案都帶有：標準服務內容 + 可加購項目 + 售後滿意度回饋'),
                  SizedBox(height: 4),
                  Text('・可延伸：預立契約、信託合作、保險通路合作'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionCard(
              title: '現在可以在 App 裡先做的事',
              icon: Icons.check_circle_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bullet('瀏覽固定價格的喪禮方案結構與內容'),
                  Bullet('草擬一個「個人紀念頁」：回顧自己的生命故事與座右銘'),
                  Bullet('草擬一份「數位訃聞」：未來要如何通知親友'),
                  Bullet('思考是否需要留下遺言／重要帳號整理'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

