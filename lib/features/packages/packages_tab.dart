import 'package:flutter/material.dart';


/// TAB 2 – 固定價格方案媒合
class PackagesTab extends StatelessWidget {
  const PackagesTab({super.key});

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
              '固定價格方案設計',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '平台會事先與合作禮儀公司談好「打包價格」與「最低服務標準」，'
              '家屬只需選擇風格與預算帶，不需再臨時討價還價。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const _PackageCard(
              name: '城市極簡告別',
              price: 'NT\$ 120,000',
              target:
                  '適合希望儀式簡單、在殯儀館或小型會館完成告別的家庭，重視流程順暢與清楚說明。',
              items: [
                '24 小時遺體接運一次（市區內）',
                '停柩冰存 3 日（公立殯儀館或合作會館）',
                '禮儀師 1 名全程帶領（家屬說明會 + 儀式執行）',
                '簡約靈堂佈置（花卉、相框、桌牌）',
                '宗教儀式一次（佛／道／基督宗教擇一）',
                '火化與骨灰罈（基本款）',
                '行政協助：死亡證明、火化許可申請說明',
              ],
            ),
            const SizedBox(height: 16),
            const _PackageCard(
              name: '家庭溫馨告別',
              price: 'NT\$ 220,000',
              target:
                  '適合希望有多一點停留與親友告別時間的家庭，重視場地氛圍與紀念感。',
              items: [
                '上述「城市極簡告別」全部內容',
                '會館廳別升級（可容納 50–80 人）',
                '靈堂佈置升級（主題式花藝設計）',
                '追思影片剪輯一次（家屬提供素材）',
                '數位紀念頁製作與託管 14 日（可加價延長）',
                '現場拍照紀錄（交付數位檔案）',
              ],
            ),
            const SizedBox(height: 16),
            const _PackageCard(
              name: '自然環保告別（樹葬／海葬）',
              price: 'NT\$ 150,000（不含政府規費）',
              target:
                  '適合希望以環保、低碳方式完成身後安排的人，著重在理念與家人溝通。',
              items: [
                '遺體接運與冰存（天數依合作場地規定）',
                '簡約告別儀式一次（家祭 + 少量親友）',
                '骨灰處理與樹葬／海葬流程諮詢安排',
                '政府相關許可與規定說明',
                '線上紀念頁與地點記錄（示意）',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.name,
    required this.price,
    required this.target,
    required this.items,
  });

  final String name;
  final String price;
  final String target;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              target,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

