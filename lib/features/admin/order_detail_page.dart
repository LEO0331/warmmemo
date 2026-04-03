import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../data/firebase/auth_service.dart';
import '../../data/models/material_catalog.dart';
import '../../data/models/purchase.dart';
import '../../data/models/vendor.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/vendor_service.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Purchase _editing;
  late Purchase _original;
  final _formKey = GlobalKey<FormState>();
  String? _workflowHint;
  late List<DeliveryMilestone> _schedule;

  @override
  void initState() {
    super.initState();
    _editing = widget.purchase;
    _original = widget.purchase;
    _schedule = widget.purchase.deliverySchedule.isEmpty
        ? defaultDeliveryMilestones()
        : widget.purchase.deliverySchedule;
    if (_editing.deliverySchedule.isEmpty) {
      _editing = _editing.copyWith(deliverySchedule: _schedule);
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final caseTransitionOk = OrderWorkflow.canChangeCaseStatus(
      from: _original.status,
      to: _editing.status,
    );
    final paymentTransitionOk = OrderWorkflow.canChangePaymentStatus(
      from: _original.paymentStatus ?? 'checkout_created',
      to: _editing.paymentStatus ?? 'checkout_created',
    );
    if (!caseTransitionOk || !paymentTransitionOk) {
      setState(() {
        _workflowHint = '狀態變更不符合流程，請依序更新（pending -> received -> complete）。';
      });
      return;
    }
    if (_editing.status == 'complete' && !_isDeliveredMilestoneDone()) {
      setState(() {
        _workflowHint = '案件要標記 complete 前，請先將「已交付」里程碑設為 done。';
      });
      return;
    }
    final actor =
        AuthService.instance.currentUser?.email ??
        AuthService.instance.currentUser?.uid ??
        'admin';
    final withLog = _buildLoggedPurchase(
      actor,
    ).copyWith(deliverySchedule: _schedule);
    Navigator.of(context).pop(withLog);
  }

  Purchase _buildLoggedPurchase(String actor) {
    final changed = <String>[];
    if (_original.status != _editing.status) {
      changed.add('status ${_original.status} -> ${_editing.status}');
    }
    if ((_original.paymentStatus ?? '') != (_editing.paymentStatus ?? '')) {
      changed.add(
        'payment ${_original.paymentStatus ?? '-'} -> ${_editing.paymentStatus ?? '-'}',
      );
    }
    if ((_original.paymentIntentId ?? '') != (_editing.paymentIntentId ?? '')) {
      changed.add('paymentIntentId updated');
    }
    if ((_original.verificationNote ?? '') !=
        (_editing.verificationNote ?? '')) {
      changed.add('verificationNote updated');
    }
    if ((_original.companyName ?? '') != (_editing.companyName ?? '')) {
      changed.add('companyName updated');
    }
    if ((_original.agentName ?? '') != (_editing.agentName ?? '')) {
      changed.add('agentName updated');
    }
    if ((_original.contactNumber ?? '') != (_editing.contactNumber ?? '')) {
      changed.add('contactNumber updated');
    }
    if ((_original.notes ?? '') != (_editing.notes ?? '')) {
      changed.add('notes updated');
    }
    if ((_original.vendorAssignment?.vendorId ?? '') !=
        (_editing.vendorAssignment?.vendorId ?? '')) {
      changed.add('vendorAssignment updated');
    }
    if ((_original.materialSelection?.code ?? '') !=
        (_editing.materialSelection?.code ?? '')) {
      changed.add('materialSelection updated');
    }
    if (_scheduleDigest(_original.deliverySchedule) !=
        _scheduleDigest(_schedule)) {
      changed.add('deliverySchedule updated');
    }

    if (changed.isEmpty) return _editing.copyWith(deliverySchedule: _schedule);

    final now = DateTime.now();
    final log = VerificationLog(
      actor: actor,
      actedAt: now,
      summary: changed.join(' | '),
      fromStatus: _original.status,
      toStatus: _editing.status,
      fromPaymentStatus: _original.paymentStatus,
      toPaymentStatus: _editing.paymentStatus,
      note: _editing.verificationNote,
      paymentIntentId: _editing.paymentIntentId,
    );

    return _editing.copyWith(
      verifiedBy: (_editing.verifiedBy == null || _editing.verifiedBy!.isEmpty)
          ? actor
          : _editing.verifiedBy,
      verifiedAt: _editing.verifiedAt ?? now,
      verificationLogs: [..._editing.verificationLogs, log],
      deliverySchedule: _schedule,
    );
  }

  String _scheduleDigest(List<DeliveryMilestone> schedule) {
    return schedule
        .map(
          (item) =>
              '${item.code}:${item.status}:${item.targetDate?.toIso8601String() ?? '-'}:${item.note ?? ''}',
        )
        .join('|');
  }

  String _conversionStep(Purchase order) {
    final proposalReady = order.proposal != null && !order.proposal!.isEmpty;
    final vendorReady =
        order.vendorAssignment != null && !order.vendorAssignment!.isEmpty;
    final materialReady =
        order.materialSelection != null && !order.materialSelection!.isEmpty;
    final scheduleReady = _schedule.any(
      (item) => item.status == 'in_progress' || item.status == 'done',
    );

    if (!proposalReady) return '待提案';
    if (!vendorReady) return '待指派供應商';
    if (!materialReady) return '待確認材質';
    if (!scheduleReady) return '待建立排程';
    return '已進入製作';
  }

  void _applyProposalToFields() {
    final proposal = _editing.proposal;
    if (proposal == null) return;
    MaterialSelection? nextMaterial = _editing.materialSelection;
    final matched = kMaterialOptionsV1.where(
      (option) => option.label == proposal.materialChoice,
    );
    if (matched.isNotEmpty) {
      final material = matched.first;
      nextMaterial = MaterialSelection(
        code: material.code,
        label: material.label,
        tier: material.tier,
        priceBand: material.priceBand,
      );
    }

    setState(() {
      final mergedNotes = _mergeProposalNotes(
        base: _editing.notes,
        schedulePreference: proposal.schedulePreference,
        note: proposal.note,
      );
      _editing = _editing.copyWith(
        materialSelection: nextMaterial,
        notes: mergedNotes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('訂單處理')),
      body: WarmBackdrop(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              children: [
                PageHero(
                  eyebrow: 'Order Detail',
                  icon: Icons.assignment_turned_in_outlined,
                  title: _editing.planName,
                  subtitle:
                      '用戶：${_editing.userId ?? '-'}｜價格：${_editing.priceLabel}',
                  badges: const ['成交漏斗', '供應商指派', '交付排程'],
                ),
                const SizedBox(height: 12),
                _buildFunnelCard(theme),
                const SizedBox(height: 12),
                _buildProposalCard(),
                const SizedBox(height: 12),
                StreamBuilder<List<Vendor>>(
                  stream: VendorService.instance.streamVendors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SectionCard(
                        title: '供應商與材質',
                        icon: Icons.storefront_outlined,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return SectionCard(
                        title: '供應商與材質',
                        icon: Icons.storefront_outlined,
                        child: SelectableText('供應商讀取失敗：${snapshot.error}'),
                      );
                    }
                    final vendors = snapshot.data ?? const <Vendor>[];
                    return _buildVendorAndMaterialSection(vendors);
                  },
                ),
                const SizedBox(height: 12),
                _buildScheduleSection(theme),
                const SizedBox(height: 12),
                SelectableText('目前狀態：${_editing.status}'),
                SelectableText('付款狀態：${_editing.paymentStatus ?? '-'}'),
                if (_workflowHint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _workflowHint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _editing.status,
                  decoration: const InputDecoration(labelText: '案件狀態'),
                  items: OrderWorkflow.caseStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _editing = _editing.copyWith(status: value));
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _editing.paymentStatus ?? 'checkout_created',
                  decoration: const InputDecoration(labelText: '付款狀態'),
                  items: OrderWorkflow.paymentStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _editing = _editing.copyWith(
                        paymentStatus: value,
                        paidAt: value == 'paid'
                            ? DateTime.now()
                            : _editing.paidAt,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _editing.paymentIntentId,
                  decoration: const InputDecoration(
                    labelText: '交易編號 (paymentIntentId)',
                  ),
                  onChanged: (v) =>
                      _editing = _editing.copyWith(paymentIntentId: v),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '付款時間：${_editing.paidAt?.toLocal().toString().split('.').first ?? '-'}',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue:
                      _editing.verifiedBy ??
                      AuthService.instance.currentUser?.email ??
                      '',
                  decoration: const InputDecoration(
                    labelText: '核對人員 (verifiedBy)',
                  ),
                  onChanged: (v) => _editing = _editing.copyWith(verifiedBy: v),
                ),
                SelectableText(
                  '核對時間：${_editing.verifiedAt?.toLocal().toString().split('.').first ?? '-'}',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _editing.verificationNote,
                  decoration: const InputDecoration(
                    labelText: '核對備註 (verificationNote)',
                  ),
                  maxLines: 3,
                  onChanged: (v) =>
                      _editing = _editing.copyWith(verificationNote: v),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _editing = _editing.copyWith(
                        verifiedBy:
                            (_editing.verifiedBy == null ||
                                _editing.verifiedBy!.isEmpty)
                            ? AuthService.instance.currentUser?.email
                            : _editing.verifiedBy,
                        verifiedAt: DateTime.now(),
                      );
                    });
                  },
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('套用核對時間'),
                ),
                if (_editing.verificationLogs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('人工核對操作紀錄', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._editing.verificationLogs.reversed.map(
                    (log) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              '${log.actedAt.toLocal().toString().split('.').first}｜${log.actor}',
                            ),
                            SelectableText(log.summary),
                            if (log.note != null && log.note!.isNotEmpty)
                              SelectableText('備註：${log.note}'),
                            if (log.paymentIntentId != null &&
                                log.paymentIntentId!.isNotEmpty)
                              SelectableText(
                                'paymentIntentId：${log.paymentIntentId}',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _editing.companyName,
                  decoration: const InputDecoration(labelText: '禮儀公司名稱'),
                  onChanged: (v) =>
                      _editing = _editing.copyWith(companyName: v),
                ),
                TextFormField(
                  initialValue: _editing.agentName,
                  decoration: const InputDecoration(labelText: '聯絡人 / 專員'),
                  onChanged: (v) => _editing = _editing.copyWith(agentName: v),
                ),
                TextFormField(
                  initialValue: _editing.contactNumber,
                  decoration: const InputDecoration(labelText: '聯絡電話'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return null;
                    final ok = RegExp(r'^[0-9+\-\s()]{8,20}$').hasMatch(v);
                    if (!ok) return '電話格式不正確';
                    return null;
                  },
                  onChanged: (v) =>
                      _editing = _editing.copyWith(contactNumber: v),
                ),
                TextFormField(
                  initialValue: _editing.notes,
                  decoration: const InputDecoration(labelText: '備註 / 補充'),
                  maxLines: 3,
                  onChanged: (v) => _editing = _editing.copyWith(notes: v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('儲存訂單資料'),
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunnelCard(ThemeData theme) {
    return SectionCard(
      title: '成交轉換漏斗',
      icon: Icons.insights_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目前階段：${_conversionStep(_editing)}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _stepChip(
                label: '提案送出',
                done: _editing.proposal != null && !_editing.proposal!.isEmpty,
              ),
              _stepChip(
                label: '供應商指派',
                done:
                    _editing.vendorAssignment != null &&
                    !_editing.vendorAssignment!.isEmpty,
              ),
              _stepChip(
                label: '材質確認',
                done:
                    _editing.materialSelection != null &&
                    !_editing.materialSelection!.isEmpty,
              ),
              _stepChip(
                label: '排程建立',
                done: _schedule.any((item) => item.status != 'pending'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard() {
    final proposal = _editing.proposal;
    if (proposal == null || proposal.isEmpty) {
      return const SectionCard(
        title: '客戶提案',
        icon: Icons.campaign_outlined,
        child: Text('尚未收到客戶提案。'),
      );
    }
    return SectionCard(
      title: '客戶提案（待審核）',
      icon: Icons.campaign_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((proposal.vendorPreference ?? '').trim().isNotEmpty)
            SelectableText('供應商偏好：${proposal.vendorPreference}'),
          if ((proposal.materialChoice ?? '').trim().isNotEmpty)
            SelectableText('材質偏好：${proposal.materialChoice}'),
          if ((proposal.schedulePreference ?? '').trim().isNotEmpty)
            SelectableText('排程偏好：${proposal.schedulePreference}'),
          if ((proposal.note ?? '').trim().isNotEmpty)
            SelectableText('備註：${proposal.note}'),
          if (proposal.submittedAt != null)
            SelectableText(
              '提案時間：${proposal.submittedAt!.toLocal().toString().split('.').first}',
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _applyProposalToFields,
            icon: const Icon(Icons.playlist_add_check_outlined),
            label: const Text('套用提案到最終設定'),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorAndMaterialSection(List<Vendor> vendors) {
    final activeVendors = vendors.where((item) => item.isActive).toList();
    final selectedVendorId = _editing.vendorAssignment?.vendorId;
    final materialCode = _editing.materialSelection?.code;

    return SectionCard(
      title: '供應商與材質',
      icon: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: selectedVendorId,
            decoration: const InputDecoration(labelText: '供應商指派'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('未指定')),
              ...activeVendors.map(
                (vendor) => DropdownMenuItem<String?>(
                  value: vendor.id,
                  child: Text(vendor.name),
                ),
              ),
            ],
            onChanged: (value) {
              final picked = activeVendors.where(
                (vendor) => vendor.id == value,
              );
              if (picked.isEmpty) {
                setState(() {
                  _editing = _editing.copyWith(vendorAssignment: null);
                });
                return;
              }
              final vendor = picked.first;
              setState(() {
                _editing = _editing.copyWith(
                  vendorAssignment: VendorAssignment(
                    vendorId: vendor.id,
                    vendorName: vendor.name,
                    contactName: vendor.contactName,
                    contactPhone: vendor.contactPhone,
                    region: vendor.serviceRegion,
                  ),
                  companyName: vendor.name,
                  agentName: vendor.contactName,
                  contactNumber: vendor.contactPhone,
                );
              });
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: materialCode,
            decoration: const InputDecoration(labelText: '材質選單 v1'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('未指定')),
              ...kMaterialOptionsV1.map(
                (item) => DropdownMenuItem<String?>(
                  value: item.code,
                  child: Text('${item.label} (${item.tier})'),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                setState(
                  () => _editing = _editing.copyWith(materialSelection: null),
                );
                return;
              }
              final option = kMaterialOptionsV1.firstWhere(
                (item) => item.code == value,
              );
              setState(() {
                _editing = _editing.copyWith(
                  materialSelection: MaterialSelection(
                    code: option.code,
                    label: option.label,
                    tier: option.tier,
                    priceBand: option.priceBand,
                  ),
                );
              });
            },
          ),
          if (_editing.materialSelection != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('等級：${_editing.materialSelection!.tier ?? '-'}'),
                ),
                Chip(
                  label: Text(
                    '價格帶：${_editing.materialSelection!.priceBand ?? '-'}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection(ThemeData theme) {
    return SectionCard(
      title: '交付排程（3 里程碑）',
      icon: Icons.event_available_outlined,
      child: Column(
        children: List.generate(_schedule.length, (index) {
          final item = _schedule[index];
          final dateText = item.targetDate == null
              ? '未設定日期'
              : item.targetDate!.toLocal().toString().split(' ').first;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: item.status,
                    decoration: const InputDecoration(labelText: '進度狀態'),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('pending'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('in_progress'),
                      ),
                      DropdownMenuItem(value: 'done', child: Text('done')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _updateMilestone(
                        index,
                        item.copyWith(status: value, updatedAt: DateTime.now()),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('目標日期：$dateText'),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: item.targetDate ?? DateTime.now(),
                          );
                          if (picked == null) return;
                          _updateMilestone(
                            index,
                            item.copyWith(
                              targetDate: picked,
                              updatedAt: DateTime.now(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: const Text('設定日期'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: ValueKey('schedule-${item.code}'),
                    initialValue: item.note,
                    decoration: const InputDecoration(labelText: '里程碑備註'),
                    onChanged: (value) {
                      _updateMilestone(
                        index,
                        item.copyWith(note: value, updatedAt: DateTime.now()),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stepChip({required String label, required bool done}) {
    return Chip(
      avatar: Icon(
        done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
        size: 18,
      ),
      label: Text(label),
    );
  }

  void _updateMilestone(int index, DeliveryMilestone value) {
    if (value.status == 'done' && !_previousMilestonesCompleted(index)) {
      _showMessage('請先完成前一個里程碑，再標記此步驟為 done。');
      return;
    }
    setState(() {
      _schedule = List<DeliveryMilestone>.from(_schedule)..[index] = value;
      _editing = _editing.copyWith(deliverySchedule: _schedule);
    });
  }

  bool _isDeliveredMilestoneDone() {
    final delivered = _schedule.where((item) => item.code == 'delivered');
    if (delivered.isEmpty) return false;
    return delivered.first.status == 'done';
  }

  bool _previousMilestonesCompleted(int index) {
    if (index <= 0) return true;
    for (var i = 0; i < index; i++) {
      if (_schedule[i].status != 'done') return false;
    }
    return true;
  }

  String _mergeProposalNotes({
    String? base,
    String? schedulePreference,
    String? note,
  }) {
    final lines = (base ?? '')
        .split('\n')
        .map((line) => line.trimRight())
        .where(
          (line) =>
              line.trim().isNotEmpty &&
              !line.startsWith('客戶排程偏好：') &&
              !line.startsWith('客戶備註：'),
        )
        .toList();
    if ((schedulePreference ?? '').trim().isNotEmpty) {
      lines.add('客戶排程偏好：${schedulePreference!.trim()}');
    }
    if ((note ?? '').trim().isNotEmpty) {
      lines.add('客戶備註：${note!.trim()}');
    }
    return lines.join('\n');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
