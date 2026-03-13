import 'package:flutter/material.dart';

import '../auth/auth_page.dart';
import '../../core/widgets/common_widgets.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _openAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(context, isWide),
              const SizedBox(height: 24),
              _buildFeatureRow(theme, isWide),
              const SizedBox(height: 24),
              _buildPackageRow(theme, isWide),
              const SizedBox(height: 24),
              _buildProofRow(theme),
              const SizedBox(height: 24),
              _buildFaqSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C8383), Color(0xFF2EB5B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WarmMemo', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
              TextButton(
                onPressed: () => _openAuth(context),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('登入 / 註冊'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '提前建立完整身後通知計劃，讓親友在需要時能快速找到你想要的方式。',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '暖備 WarmMemo 結合固定方案、數位訃聞與紀念頁創建，讓您在關鍵時刻把握清楚、懂得聲明意圖，\n'
            '並進一步透過通知追蹤與點擊統計確認訊息是否送達。',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => _openAuth(context),
                child: const Text('開始規劃'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '已協助 1,200+ 家族與禮儀團隊同步通知',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeData theme, bool isWide) {
    final features = const [
      '透明固定方案讓價格與服務一目瞭然',
      '簡易紀念頁 + 點擊／閱讀統計回報',
      '數位訃聞草稿支援多語氣與渠道',
      '合規匯出 + PDF/CSV 歷史紀錄',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('為何選擇 WarmMemo？', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: isWide ? 2 : 1,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: features
                .map(
                  (feature) => Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(feature, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageRow(ThemeData theme, bool isWide) {
    final packages = const [
      {
        'name': '城市極簡告別',
        'price': 'NT\$ 120,000',
        'target': '講求流程順暢與清楚說明的家庭',
      },
      {
        'name': '家庭溫馨告別',
        'price': 'NT\$ 220,000',
        'target': '追求溫馨場域與紀念氛圍',
      },
      {
        'name': '自然環保告別',
        'price': 'NT\$ 150,000',
        'target': '著重理念的樹葬／海葬家庭',
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('固定方案示意', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: isWide ? 3 : 1,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: packages
                .map(
                  (package) => Card(
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
                                  package['name']!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                package['price']!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(package['target']!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProofRow(ThemeData theme) {
    final logos = const ['CloudMetrics', 'Orbit', 'Vita Health', 'PetDesk', 'Notion'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: '信任與實績',
        icon: Icons.verified,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('社群認證 + 場景信任'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: logos
                  .map((logo) => Chip(
                        label: Text(logo),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = const [
      {
        'q': '我可以更改語氣與渠道嗎？',
        'a': '可以，在數位訃聞與通知設定中選擇語氣、渠道與額外說明，系統會跟著更新草稿與通知紀錄。'
      },
      {
        'q': '匯出紀錄可以留給家人嗎？',
        'a': '管理端可匯出 PDF/CSV、草稿與通知歷史作記錄，合規與保存都由您掌握。'
      },
      {
        'q': '有專人協助我設定嗎？',
        'a': '不論您是個人家庭還是禮儀團隊，我們都有方案與客服協助啟動與 FAQ 解答。'
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: '常見問題 (FAQ)',
        icon: Icons.help_outline,
        child: Column(
          children: faqs
              .map(
                (faq) => ExpansionTile(
                  title: Text(faq['q']!),
                  children: [Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(faq['a']!),
                  )],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
