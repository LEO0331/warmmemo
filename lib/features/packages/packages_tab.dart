import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/models/draft_models.dart';
import '../../data/models/purchase.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/purchase_service.dart';
import 'checkout_page.dart';

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
            _PackageCard(
              name: '城市極簡告別',
              price: 'NT\$ 120,000',
              target:
                  '適合希望儀式簡單、在殯儀館或小型會館完成告別的家庭，重視流程順暢與清楚說明。',
              items: const [
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
            _PackageCard(
              name: '家庭溫馨告別',
              price: 'NT\$ 220,000',
              target:
                  '適合希望有多一點停留與親友告別時間的家庭，重視場地氛圍與紀念感。',
              items: const [
                '上述「城市極簡告別」全部內容',
                '會館廳別升級（可容納 50–80 人）',
                '靈堂佈置升級（主題式花藝設計）',
                '追思影片剪輯一次（家屬提供素材）',
                '數位紀念頁製作與託管 14 日（可加價延長）',
                '現場拍照紀錄（交付數位檔案）',
              ],
            ),
            const SizedBox(height: 16),
            _PackageCard(
              name: '自然環保告別（樹葬／海葬）',
              price: 'NT\$ 150,000（不含政府規費）',
              target:
                  '適合希望以環保、低碳方式完成身後安排的人，著重在理念與家人溝通。',
              items: const [
                '遺體接運與冰存（天數依合作場地規定）',
                '簡約告別儀式一次（家祭 + 少量親友）',
                '骨灰處理與樹葬／海葬流程諮詢安排',
                '政府相關許可與規定說明',
                '線上紀念頁與地點記錄（示意）',
              ],
            ),
            const SizedBox(height: 24),
            _OrdersPanel(),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(
                        planName: name,
                        priceLabel: price,
                      ),
                    ),
                  );
                },
                child: const Text('前往結帳'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersPanel extends StatefulWidget {
  @override
  State<_OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<_OrdersPanel> {
  String? _paymentStatusFilter;
  bool _onlyPendingPayment = false;

  List<Purchase> _applyFilters(List<Purchase> source) {
    return source.where((order) {
      final payment = order.paymentStatus ?? '';
      final matchesStatus =
          _paymentStatusFilter == null || payment == _paymentStatusFilter;
      final matchesPending = !_onlyPendingPayment ||
          payment == 'awaiting_checkout' ||
          payment == 'checkout_created';
      return matchesStatus && matchesPending;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      title: '我的方案與狀態',
      icon: Icons.receipt_long_outlined,
      child: StreamBuilder<List<Purchase>>(
        stream: PurchaseService.instance.userOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonOrderList(count: 3);
          }
          final orders = snapshot.data ?? [];
          final statuses = orders
              .map((o) => o.paymentStatus)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final filteredOrders = _applyFilters(orders);
          if (orders.isEmpty) {
            return const EmptyStateCard(
              title: '尚未建立方案訂單',
              description: '選擇方案後可建立訂單並追蹤付款狀態。',
              icon: Icons.receipt_long_outlined,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationCenterCard(uid: uid),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('全部付款狀態'),
                    selected: _paymentStatusFilter == null,
                    onSelected: (_) => setState(() => _paymentStatusFilter = null),
                  ),
                  ...statuses.map(
                    (s) => ChoiceChip(
                      label: Text(s),
                      selected: _paymentStatusFilter == s,
                      onSelected: (_) => setState(() => _paymentStatusFilter = s),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilterChip(
                label: const Text('僅顯示待付款'),
                selected: _onlyPendingPayment,
                onSelected: (value) => setState(() => _onlyPendingPayment = value),
              ),
              const SizedBox(height: 8),
              if (filteredOrders.isEmpty)
                const Text('目前篩選條件下沒有訂單。')
              else
                ...filteredOrders
                .map(
                  (order) => ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(order.planName),
                    subtitle: Text(
                      '狀態：${order.status}｜付款：${order.paymentStatus ?? '-'}｜價格：${order.priceLabel}\n'
                      '最近核對：${_latestVerificationSummary(order)}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      order.createdAt.toLocal().toString().split('.').first,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(order.planName),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText('價格：${order.priceLabel}'),
                              SelectableText('狀態：${order.status}'),
                              if (order.paymentProvider != null)
                                SelectableText('付款方式：${order.paymentProvider}'),
                              if (order.paymentStatus != null)
                                SelectableText('付款狀態：${order.paymentStatus}'),
                              if (order.invoiceId != null)
                                SelectableText('付款單號：${order.invoiceId}'),
                              if (order.checkoutUrl != null)
                                SelectableText('付款連結：${order.checkoutUrl}'),
                              if (order.companyName != null)
                                SelectableText('公司：${order.companyName}'),
                              if (order.agentName != null)
                                SelectableText('專員：${order.agentName}'),
                              if (order.contactNumber != null)
                                SelectableText('聯絡方式：${order.contactNumber}'),
                              if (order.notes != null) SelectableText('備註：${order.notes}'),
                              if (order.verificationLogs.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const SelectableText('人工核對紀錄：'),
                                ...order.verificationLogs.reversed.map(
                                  (log) => SelectableText(
                                    '${log.actedAt.toLocal().toString().split('.').first}｜${log.actor}｜${log.summary}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton.icon(
                              onPressed: () async {
                                final buffer = StringBuffer()
                                  ..writeln('方案：${order.planName}')
                                  ..writeln('價格：${order.priceLabel}')
                                  ..writeln('狀態：${order.status}');
                                if (order.paymentProvider != null) {
                                  buffer.writeln('付款方式：${order.paymentProvider}');
                                }
                                if (order.paymentStatus != null) {
                                  buffer.writeln('付款狀態：${order.paymentStatus}');
                                }
                                if (order.invoiceId != null) {
                                  buffer.writeln('付款單號：${order.invoiceId}');
                                }
                                if (order.checkoutUrl != null) {
                                  buffer.writeln('付款連結：${order.checkoutUrl}');
                                }
                                if (order.companyName != null) {
                                  buffer.writeln('公司：${order.companyName}');
                                }
                                if (order.agentName != null) {
                                  buffer.writeln('專員：${order.agentName}');
                                }
                                if (order.contactNumber != null) {
                                  buffer.writeln('聯絡方式：${order.contactNumber}');
                                }
                                if (order.notes != null) {
                                  buffer.writeln('備註：${order.notes}');
                                }
                                if (order.verificationLogs.isNotEmpty) {
                                  buffer.writeln('人工核對紀錄：');
                                  for (final log in order.verificationLogs.reversed) {
                                    buffer.writeln(
                                      '${log.actedAt.toLocal().toString().split('.').first}｜${log.actor}｜${log.summary}',
                                    );
                                  }
                                }
                                await Clipboard.setData(ClipboardData(text: buffer.toString()));
                                if (!context.mounted) return;
                                AppFeedback.show(
                                  context,
                                  message: '訂單資訊已複製',
                                  tone: FeedbackTone.success,
                                );
                              },
                              icon: const Icon(Icons.copy_all_outlined),
                              label: const Text('一鍵複製'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('關閉'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
                ,
            ],
          );
        },
      ),
    );
  }

  String _latestVerificationSummary(Purchase order) {
    if (order.verificationLogs.isEmpty) return '尚未人工核對';
    final latest = order.verificationLogs.last;
    final time = latest.actedAt.toLocal().toString().split('.').first;
    return '$time｜${latest.actor}';
  }
}

class _NotificationCenterCard extends StatelessWidget {
  const _NotificationCenterCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '通知中心',
      icon: Icons.notifications_active_outlined,
      child: StreamBuilder<List<NotificationEvent>>(
        stream: NotificationService.instance.streamForUser(uid, limit: 6),
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Text('目前尚未有通知紀錄。');
          }
          return Column(
            children: events
                .map(
                  (event) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      event.status == 'read'
                          ? Icons.mark_email_read_outlined
                          : Icons.notifications_none_outlined,
                    ),
                    title: Text(event.draftType ?? '草稿通知'),
                    subtitle: Text('${event.channel} · ${event.status}'),
                    trailing: Text(
                      event.occurredAt.toLocal().toString().split('.').first,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
