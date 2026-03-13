import 'package:flutter/material.dart';

import '../../data/models/purchase.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Purchase _editing;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _editing = widget.purchase;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _editing.copyWith(status: 'complete'),
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
          child: ListView(
            children: [
              Text(_editing.planName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('用戶：${_editing.userId ?? '-'}'),
              Text('價格：${_editing.priceLabel}'),
              Text('目前狀態：${_editing.status}'),
              const SizedBox(height: 16),
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
                label: const Text('儲存並標記完成'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
