import 'package:flutter/material.dart';

import '../../data/models/purchase.dart';

class OrderTile extends StatefulWidget {
  const OrderTile({
    super.key,
    required this.purchase,
    required this.onSave,
  });

  final Purchase purchase;
  final void Function(Purchase updated) onSave;

  @override
  State<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<OrderTile> {
  late Purchase _editing;

  @override
  void initState() {
    super.initState();
    _editing = widget.purchase;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_editing.planName, style: theme.textTheme.titleMedium),
                DropdownButton<String>(
                  value: _editing.status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('pending')),
                    DropdownMenuItem(value: 'received', child: Text('received')),
                    DropdownMenuItem(value: 'complete', child: Text('complete')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _editing = _editing.copyWith(status: value));
                  },
                ),
              ],
            ),
            Text('用戶：${_editing.userId ?? 'unknown'}'),
            Text('價格：${_editing.priceLabel}'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _editing.companyName,
              decoration: const InputDecoration(labelText: '公司名稱'),
              onChanged: (v) => _editing = _editing.copyWith(companyName: v),
            ),
            TextFormField(
              initialValue: _editing.contactNumber,
              decoration: const InputDecoration(labelText: '聯絡電話'),
              onChanged: (v) => _editing = _editing.copyWith(contactNumber: v),
            ),
            TextFormField(
              initialValue: _editing.agentName,
              decoration: const InputDecoration(labelText: '專員姓名'),
              onChanged: (v) => _editing = _editing.copyWith(agentName: v),
            ),
            TextFormField(
              initialValue: _editing.notes,
              decoration: const InputDecoration(labelText: '備註'),
              maxLines: 2,
              onChanged: (v) => _editing = _editing.copyWith(notes: v),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('儲存'),
                onPressed: () => widget.onSave(_editing),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
