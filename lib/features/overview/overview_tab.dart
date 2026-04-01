import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/common_widgets.dart';

/// TAB 1 – 教育 + 流程總覽 + 商業模式說明
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

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
              '在失去親人的當下，不用邊掉眼淚邊談價格。',
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
            SectionCard(
              title: '延伸閱讀推薦',
              icon: Icons.auto_stories_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BookLinkTile(
                    title: 'Die With Zero（把人生經驗花在最值得的時刻）',
                    subtitle: 'Bill Perkins｜建立「時間、金錢、健康」平衡觀。',
                    onTap: () => _openExternal(
                      'https://www.diewithzerobook.com/',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BookLinkTile(
                    title: 'Being Mortal（當醫療遇見生命終點）',
                    subtitle: 'Atul Gawande｜理解照護選擇與家屬溝通。',
                    onTap: () => _openExternal(
                      'https://atulgawande.com/book/being-mortal/',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BookLinkTile(
                    title: 'The Five Invitations（面對無常的五個邀請）',
                    subtitle: 'Frank Ostaseski｜練習面對失落與告別。',
                    onTap: () => _openExternal(
                      'https://fiveinvitations.com/',
                    ),
                  ),
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

class _BookLinkTile extends StatelessWidget {
  const _BookLinkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const Icon(Icons.book_outlined),
        title: SelectableText(title),
        subtitle: SelectableText(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: onTap,
      ),
    );
  }
}
