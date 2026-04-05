import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';

class PublicObituaryPage extends StatelessWidget {
  const PublicObituaryPage({super.key, required this.encodedPayload});

  final String encodedPayload;

  @override
  Widget build(BuildContext context) {
    final data = _decodePayload(encodedPayload);
    if (data == null) {
      return const Scaffold(
        body: WarmBackdrop(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyStateCard(
                  title: '此訃聞頁目前無法顯示',
                  description: '連結可能已失效，或內容格式不完整。',
                  icon: Icons.link_off_outlined,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final text = _resolvedObituaryText(data);
    final name = (data['name'] as String? ?? '').trim();
    final relationship = (data['relationship'] as String? ?? '').trim();
    final date = (data['date'] as String? ?? '').trim();
    final location = (data['location'] as String? ?? '').trim();
    final note = (data['note'] as String? ?? '').trim();
    final titleName = name.isEmpty ? '訃聞通知' : '$name 訃聞通知';

    return Scaffold(
      body: WarmBackdrop(
        child: SafeArea(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHero(
                    eyebrow: 'WarmMemo Obituary',
                    icon: Icons.campaign_outlined,
                    title: titleName,
                    subtitle: '感謝親友撥冗閱讀與關心。',
                    badges: const ['公開訃聞', '可轉傳', '唯讀'],
                  ),
                  const SizedBox(height: 16),
                  if (relationship.isNotEmpty ||
                      date.isNotEmpty ||
                      location.isNotEmpty)
                    SectionCard(
                      title: '儀式資訊',
                      icon: Icons.event_note_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (relationship.isNotEmpty)
                            Text('發文人：$relationship'),
                          if (date.isNotEmpty) Text('時間：$date'),
                          if (location.isNotEmpty) Text('地點：$location'),
                        ],
                      ),
                    ),
                  if (relationship.isNotEmpty ||
                      date.isNotEmpty ||
                      location.isNotEmpty)
                    const SizedBox(height: 16),
                  if (text.isNotEmpty)
                    SectionCard(
                      title: '訃聞內容',
                      icon: Icons.article_outlined,
                      child: SelectableText(text),
                    ),
                  if (text.isNotEmpty) const SizedBox(height: 16),
                  if (note.isNotEmpty)
                    SectionCard(
                      title: '補充說明',
                      icon: Icons.info_outline,
                      child: Text(note),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic>? _decodePayload(String encodedPayload) {
  try {
    final normalized = base64Url.normalize(encodedPayload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(decoded);
    if (map is! Map<String, dynamic>) return null;
    return map;
  } catch (_) {
    return null;
  }
}

String _resolvedObituaryText(Map<String, dynamic> data) {
  final provided = (data['text'] as String? ?? '').trim();
  if (provided.isNotEmpty) return provided;

  final name = (data['name'] as String? ?? '').trim();
  final relationship = (data['relationship'] as String? ?? '家屬').trim();
  final date = (data['date'] as String? ?? '').trim();
  final location = (data['location'] as String? ?? '').trim();
  final note = (data['note'] as String? ?? '').trim();
  final tone = (data['tone'] as String? ?? '溫和正式').trim();

  String base;
  switch (tone) {
    case '宗教色彩':
      base =
          '敬啟者：$relationship謹此告知，至親「$name」已安息。追思儀式將於 $date 在 $location 舉行，敬邀親友同來追思與祝禱。';
      break;
    case '極簡通知':
      base = '各位親友好：親人「$name」已辭世，告別式將於 $date 在 $location 舉行。';
      break;
    default:
      base =
          '親愛的親友們：$relationship在此告知，我們深愛的「$name」已離世。追思儀式訂於 $date 在 $location 舉行。';
  }
  if (note.isNotEmpty) {
    return '$base\n\n$note';
  }
  return base;
}
