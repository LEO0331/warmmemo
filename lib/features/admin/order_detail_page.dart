import 'package:flutter/material.dart';

import '../../data/firebase/auth_service.dart';
import '../../data/models/purchase.dart';
import '../../data/services/purchase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _editing = widget.purchase;
    _original = widget.purchase;
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
    final actor = AuthService.instance.currentUser?.email ??
        AuthService.instance.currentUser?.uid ??
        'admin';
    final withLog = _buildLoggedPurchase(actor);
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
    if ((_original.verificationNote ?? '') != (_editing.verificationNote ?? '')) {
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

    if (changed.isEmpty) return _editing;

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
      verifiedBy: (_editing.verifiedBy == null || _editing.verifiedBy!.isEmpty) ? actor : _editing.verifiedBy,
      verifiedAt: _editing.verifiedAt ?? now,
      verificationLogs: [..._editing.verificationLogs, log],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單處理'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              SelectableText(_editing.planName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              SelectableText('用戶：${_editing.userId ?? '-'}'),
              SelectableText('價格：${_editing.priceLabel}'),
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
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
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
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _editing = _editing.copyWith(
                      paymentStatus: value,
                      paidAt: value == 'paid' ? DateTime.now() : _editing.paidAt,
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _editing.paymentIntentId,
                decoration: const InputDecoration(labelText: '交易編號 (paymentIntentId)'),
                onChanged: (v) => _editing = _editing.copyWith(paymentIntentId: v),
              ),
              const SizedBox(height: 8),
              SelectableText('付款時間：${_editing.paidAt?.toLocal().toString().split('.').first ?? '-'}'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _editing.verifiedBy ?? AuthService.instance.currentUser?.email ?? '',
                decoration: const InputDecoration(labelText: '核對人員 (verifiedBy)'),
                onChanged: (v) => _editing = _editing.copyWith(verifiedBy: v),
              ),
              SelectableText('核對時間：${_editing.verifiedAt?.toLocal().toString().split('.').first ?? '-'}'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _editing.verificationNote,
                decoration: const InputDecoration(labelText: '核對備註 (verificationNote)'),
                maxLines: 3,
                onChanged: (v) => _editing = _editing.copyWith(verificationNote: v),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _editing = _editing.copyWith(
                      verifiedBy: (_editing.verifiedBy == null || _editing.verifiedBy!.isEmpty)
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
                          if (log.paymentIntentId != null && log.paymentIntentId!.isNotEmpty)
                            SelectableText('paymentIntentId：${log.paymentIntentId}'),
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
                onChanged: (v) => _editing = _editing.copyWith(companyName: v),
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
                onChanged: (v) => _editing = _editing.copyWith(contactNumber: v),
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
    );
  }
}
