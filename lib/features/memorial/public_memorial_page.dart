import 'package:flutter/material.dart';

import '../../core/utils/meaning_memory_copy.dart';
import '../../core/utils/product_locale.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/draft_service.dart';
import '../../data/models/draft_models.dart';

class PublicMemorialPage extends StatefulWidget {
  const PublicMemorialPage({super.key, required this.slug});

  final String slug;

  @override
  State<PublicMemorialPage> createState() => _PublicMemorialPageState();
}

class _PublicMemorialPageState extends State<PublicMemorialPage> {
  late final Future<PublicMemorialProfile?> _profileFuture = _loadProfile();

  Future<PublicMemorialProfile?> _loadProfile() async {
    final profile = await FirebaseDraftService.instance
        .loadPublicMemorialBySlug(widget.slug);
    if (profile != null && profile.ownerUid.isNotEmpty) {
      try {
        await FirebaseDraftService.instance.incrementStats(
          profile.ownerUid,
          readDelta: 1,
        );
      } catch (_) {
        // Public visitors may not have write permission for owner stats.
        // Keep page rendering even when telemetry update fails.
      }
    }
    return profile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WarmBackdrop(
        child: SafeArea(
          child: SelectionArea(
            child: FutureBuilder<PublicMemorialProfile?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: SkeletonOrderList(count: 2),
                  );
                }

                final profile = snapshot.data;
                if (profile == null) {
                  return const _PublicMemorialUnavailable();
                }

                final displayName =
                    (profile.nickname?.trim().isNotEmpty ?? false)
                    ? profile.nickname!.trim()
                    : (profile.name?.trim().isNotEmpty ?? false)
                    ? profile.name!.trim()
                    : 'WarmMemo 紀念頁';
                final meaningCopy = MeaningMemoryCopy.forLocale(
                  Localizations.localeOf(context),
                );
                final isEnglish = isEnglishProductLocale(context);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHero(
                        eyebrow: 'WarmMemo Memorial',
                        icon: Icons.favorite_border,
                    title: displayName,
                    subtitle: profile.motto?.trim().isNotEmpty ?? false
                        ? profile.motto!.trim()
                        : productCopy(
                            context,
                            zh: '願這份思念能被溫柔保存，讓回憶陪伴每一次重逢。',
                            en: 'May these memories be held with care and remain close through every reunion.',
                          ),
                    badges: isEnglish
                        ? const ['Public memorial', 'View by QR code', 'Read-only']
                        : const ['公開紀念頁', '掃描可瀏覽', '唯讀追思'],
                      ),
                      const SizedBox(height: 16),
                      if (profile.bio?.trim().isNotEmpty ?? false)
                        SectionCard(
                          title: productCopy(context, zh: '生平摘要', en: 'Life summary'),
                          icon: Icons.auto_stories_outlined,
                          child: Text(profile.bio!.trim()),
                        ),
                      if (profile.bio?.trim().isNotEmpty ?? false)
                        const SizedBox(height: 16),
                      if (profile.highlights?.trim().isNotEmpty ?? false)
                        SectionCard(
                          title: productCopy(context, zh: '人生亮點', en: 'Highlights'),
                          icon: Icons.star_border_outlined,
                          child: Text(profile.highlights!.trim()),
                        ),
                      if (profile.highlights?.trim().isNotEmpty ?? false)
                        const SizedBox(height: 16),
                      if (profile.willNote?.trim().isNotEmpty ?? false)
                        SectionCard(
                          title: productCopy(context, zh: '給後人的話', en: 'A message for those they loved'),
                          icon: Icons.mail_outline,
                          child: Text(profile.willNote!.trim()),
                        ),
                      if (profile.willNote?.trim().isNotEmpty ?? false)
                        const SizedBox(height: 16),
                      if (_hasMeaningMemory(profile))
                        SectionCard(
                          title: meaningCopy.title,
                          icon: Icons.favorite_border_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (profile.meaningLifeStory?.trim().isNotEmpty ??
                                  false)
                                _ReflectionRow(
                                  label: meaningCopy.lifeStoryLabel,
                                  value: profile.meaningLifeStory!.trim(),
                                ),
                              if (profile.meaningPurpose?.trim().isNotEmpty ??
                                  false)
                                _ReflectionRow(
                                  label: meaningCopy.purposeLabel,
                                  value: profile.meaningPurpose!.trim(),
                                ),
                              if (profile.meaningMatteredTo
                                      ?.trim()
                                      .isNotEmpty ??
                                  false)
                                _ReflectionRow(
                                  label: meaningCopy.matteredToLabel,
                                  value: profile.meaningMatteredTo!.trim(),
                                ),
                              if (profile.meaningMemoriesToKeep
                                      ?.trim()
                                      .isNotEmpty ??
                                  false)
                                _ReflectionRow(
                                  label: meaningCopy.memoriesLabel,
                                  value: profile.meaningMemoriesToKeep!.trim(),
                                ),
                            ],
                          ),
                        ),
                      if (_hasMeaningMemory(profile))
                        const SizedBox(height: 16),
                      if (_hasObituarySummary(profile))
                        SectionCard(
                          title: productCopy(context, zh: '追思資訊', en: 'Memorial service details'),
                          icon: Icons.event_note_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (profile.obituaryRelationship
                                      ?.trim()
                                      .isNotEmpty ??
                                  false)
                                _InfoRow(
                                  label: productCopy(context, zh: '關係', en: 'Relationship'),
                                  value: profile.obituaryRelationship!.trim(),
                                ),
                              if (profile.obituaryServiceDate
                                      ?.trim()
                                      .isNotEmpty ??
                                  false)
                                _InfoRow(
                                  label: productCopy(context, zh: '時間', en: 'Date and time'),
                                  value: profile.obituaryServiceDate!.trim(),
                                ),
                              if (profile.obituaryLocation?.trim().isNotEmpty ??
                                  false)
                                _InfoRow(
                                  label: productCopy(context, zh: '地點', en: 'Location'),
                                  value: profile.obituaryLocation!.trim(),
                                ),
                              if (profile.obituaryCustomNote
                                      ?.trim()
                                      .isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 8),
                                Text(profile.obituaryCustomNote!.trim()),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _hasObituarySummary(PublicMemorialProfile profile) {
    return (profile.obituaryRelationship?.trim().isNotEmpty ?? false) ||
        (profile.obituaryLocation?.trim().isNotEmpty ?? false) ||
        (profile.obituaryServiceDate?.trim().isNotEmpty ?? false) ||
        (profile.obituaryCustomNote?.trim().isNotEmpty ?? false);
  }

  bool _hasMeaningMemory(PublicMemorialProfile profile) {
    return (profile.meaningLifeStory?.trim().isNotEmpty ?? false) ||
        (profile.meaningPurpose?.trim().isNotEmpty ?? false) ||
        (profile.meaningMatteredTo?.trim().isNotEmpty ?? false) ||
        (profile.meaningMemoriesToKeep?.trim().isNotEmpty ?? false);
  }
}

class _PublicMemorialUnavailable extends StatelessWidget {
  const _PublicMemorialUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: EmptyStateCard(
            title: productCopy(context, zh: '此紀念頁目前無法顯示', en: 'This memorial page is unavailable'),
            description: productCopy(context, zh: '這個頁面可能尚未公開、已停止公開，或連結有誤。請向分享者確認網址後再試。', en: 'It may not be public, may no longer be available, or the link may be incorrect. Please confirm the link with the person who shared it.'),
            icon: Icons.link_off_outlined,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ReflectionRow extends StatelessWidget {
  const _ReflectionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}
