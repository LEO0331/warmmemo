import 'package:flutter/material.dart';

import '../../data/firebase/auth_service.dart';
import '../../data/models/purchase.dart';
import '../../data/services/purchase_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.planName,
    required this.priceLabel,
  });

  final String planName;
  final String priceLabel;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _submitting = false;

  Future<void> _submitOrder() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請先登入後再結帳')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final purchase = Purchase(
        planName: widget.planName,
        priceLabel: widget.priceLabel,
        status: 'pending',
      );
      await PurchaseService.instance.createOrder(uid: uid, purchase: purchase);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已送出，狀態為 pending')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('提交失敗：$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('確認方案並結帳')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('方案', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(widget.planName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('價格：${widget.priceLabel}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              '提交後狀態為 pending，管理員確認後會更新為 received / complete，'
              '您可於方案列表查看最新狀態。',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submitOrder,
                child: Text(_submitting ? '送出中…' : '送出並等待確認'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
