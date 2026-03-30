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

  Widget _networkImage({
    required String url,
    required double height,
    double? width,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
  }) {
    // Important: don't pass `double.infinity` to Image's width/height; keep sizing
    // on the parent BoxConstraints to avoid blank rendering on web in some layouts.
    final image = Image.network(
      url,
      width: null,
      height: null,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFEEDFD5),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFEEDFD5),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth ? constraints.maxWidth : null;
        final requested = width;
        final resolvedW = (requested == null || requested.isInfinite)
            ? (maxW ?? 320.0)
            : requested;
        final sized = SizedBox(
          width: resolvedW,
          height: height,
          child: image,
        );
        if (borderRadius == null) return sized;
        return ClipRRect(borderRadius: borderRadius, child: sized);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(context, isWide),
                const SizedBox(height: 24),
                _buildFeatureRow(theme, isWide),
                const SizedBox(height: 24),
                _buildPhotoStrip(isWide),
                const SizedBox(height: 24),
                _buildPackageRow(theme, isWide),
                const SizedBox(height: 24),
                _buildProofRow(theme),
                const SizedBox(height: 24),
                _buildFaqSection(),
                const SizedBox(height: 24),
                _buildFooter(theme, isWide),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFFFFCFA),
          border: Border.all(color: const Color(0xFFE8D7CC)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WarmMemo 暖備',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '提前整理重要資訊與通知草稿，讓家人在需要時能更快、更安心地完成安排。',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A3D31)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isWide ? 280 : double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('聯絡方式', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Bullet('客服信箱：support@warmmemo.example'),
                        const Bullet('服務時間：週一至週五 10:00–18:00'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 320 : double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('功能與輸出', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Bullet('固定方案對照：清楚的項目與參考費用'),
                        const Bullet('紀念頁/訃聞草稿：分享連結與匯出圖片'),
                        const Bullet('合規備存：PDF/CSV 匯出保存'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 320 : double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('提醒', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Bullet('本頁價格與方案為示意，實際以合作單位與地區條件為準。'),
                        const Bullet('請於重要決策前，與家人充分討論並保留書面紀錄。'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 10),
              Text(
                '© 2026 WarmMemo. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A4A3B)),
              ),
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
          colors: [Color(0xFFB96843), Color(0xFFE2A37C), Color(0xFFF2C8AB)],
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
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8F4F36),
                  foregroundColor: Colors.white,
                ),
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
      {
        'title': '透明固定方案',
        'desc': '價格、服務與流程一次看清楚。',
        'icon': Icons.receipt_long_outlined,
        'image':
            'https://images.unsplash.com/photo-1554224155-1696413565d3?auto=format&fit=crop&w=600&q=80',
      },
      {
        'title': '簡易紀念頁',
        'desc': '快速生成，分享給親友與長輩。',
        'icon': Icons.favorite_border,
        'image':
            'https://images.unsplash.com/photo-1520975958225-2b8f9b82e6b4?auto=format&fit=crop&w=600&q=80',
      },
      {
        'title': '數位訃聞草稿',
        'desc': '多語氣、多渠道，一鍵套用。',
        'icon': Icons.campaign_outlined,
        'image':
            'https://images.unsplash.com/photo-1522881451255-f59ad836fdfb?auto=format&fit=crop&w=600&q=80',
      },
      {
        'title': '合規匯出備存',
        'desc': 'PDF/CSV 留存，家人也好接手。',
        'icon': Icons.verified_user_outlined,
        'image':
            'https://images.unsplash.com/photo-1554224154-22dec7ec8818?auto=format&fit=crop&w=600&q=80',
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('為何選擇 WarmMemo？', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWide ? 1.25 : 1.35,
            physics: const NeverScrollableScrollPhysics(),
            children: features
                .asMap()
                .entries
                .map(
                  (entry) => AppearMotion(
                    delayMs: 50 * entry.key,
                    child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8E5D8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  entry.value['icon'] as IconData,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value['title'] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _networkImage(
                              url: entry.value['image'] as String,
                              width: double.infinity,
                              height: 88,
                              borderRadius: BorderRadius.circular(14),
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            entry.value['desc'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5A3D31),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
        'image':
            'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
        'bullets': [
          '基礎流程規劃：告別儀式／火化或安葬動線',
          '標準化清單：用品與費用透明列示',
          '通知素材：訃聞草稿 + QR code 分享',
          '紀錄留存：PDF 匯出給家人備存',
        ],
      },
      {
        'name': '家庭溫馨告別',
        'price': 'NT\$ 220,000',
        'target': '追求溫馨場域與紀念氛圍',
        'image':
            'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=900&q=80',
        'bullets': [
          '紀念頁製作：照片、故事與留言整理',
          '現場氛圍：花藝/佈置方向與需求彙整',
          '親友通知：分組名單、送達追蹤回報',
          '後續協助：感謝文與資料匯出保存',
        ],
      },
      {
        'name': '自然環保告別',
        'price': 'NT\$ 150,000',
        'target': '著重理念的樹葬／海葬家庭',
        'image':
            'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=80',
        'bullets': [
          '理念對齊：儀式簡化與環保需求確認',
          '文件備妥：必要資料與流程提醒清單',
          '通知說明：用語柔和、重點清楚好轉傳',
          '紀錄追蹤：通知開啟/點擊統計回報',
        ],
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('固定方案示意', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            '依不同需求提供可對照的方案組合：清楚的服務範圍、參考價格與適用情境，方便家屬快速討論與決策。',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A3D31)),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: isWide ? 3 : 1,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: packages
                .asMap()
                .entries
                .map(
                  (entry) => AppearMotion(
                    delayMs: 70 * entry.key,
                    child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _networkImage(
                          url: entry.value['image'] as String,
                          width: double.infinity,
                          height: isWide ? 120 : 110,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.value['name'] as String,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    entry.value['price'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.value['target'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF5A3D31),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...((entry.value['bullets'] as List<dynamic>)
                                  .cast<String>()
                                  .map((text) => Bullet(text))),
                            ],
                          ),
                        ),
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

  Widget _buildPhotoStrip(bool isWide) {
    // Free images via Unsplash CDN (hotlink). If you later want local assets,
    // replace these with `Image.asset` and add files to `assets/`.
    final items = const [
      {
        'url':
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=85',
        'caption': '把想說的話先寫下來，讓家人不必猜。',
      },
      {
        'url':
            'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1400&q=85',
        'caption': '流程與費用透明，選擇更踏實。',
      },
      {
        'url':
            'https://images.unsplash.com/photo-1526779259212-939e64788e3c?auto=format&fit=crop&w=1400&q=85',
        'caption': '重要通知一鍵整理，送達也能追蹤。',
      },
      {
        'url':
            'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1400&q=85',
        'caption': '紀念頁與訃聞草稿，溫柔又清楚。',
      },
      {
        'url':
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=85&sat=-20',
        'caption': '每一步都有記錄，關鍵時刻更安心。',
      },
    ];
    return SizedBox(
      height: isWide ? 240 : 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index % items.length];
          final url = item['url']!;
          final caption = item['caption']!;
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Image.network(
                  url,
                  width: isWide ? 360 : 260,
                  height: isWide ? 240 : 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: isWide ? 360 : 260,
                      height: isWide ? 240 : 180,
                      color: const Color(0xFFEEDFD5),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: isWide ? 360 : 260,
                    height: isWide ? 240 : 180,
                    color: const Color(0xFFEEDFD5),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      caption,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        // ignore: unnecessary_underscores
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
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
