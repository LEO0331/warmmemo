import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/firebase/auth_service.dart';
import '../../data/models/purchase.dart';
import '../../data/services/payment_service.dart';
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
  String? _lastInvoiceId;
  String? _lastCheckoutUrl;
  String? _lastErrorCode;

  Future<void> _submitOrder() async {
    final uid = AuthService.instance.currentUser?.uid;
    final email = AuthService.instance.currentUser?.email;
    if (uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請先登入後再結帳')));
      return;
    }
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少使用者 Email，無法建立 Stripe 結帳連結。')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final amount = _parseAmount(widget.priceLabel);
      final payment = await PaymentService.instance.createInvoice(
        email: email,
        name: email.split('@').first,
        amountCents: amount,
        description: 'WarmMemo 方案：${widget.planName}',
        provider: PaymentProvider.stripe,
      );
      final purchase = Purchase(
        planName: widget.planName,
        priceLabel: widget.priceLabel,
        status: 'pending',
        paymentProvider: payment.provider.name,
        paymentStatus: 'checkout_created',
        invoiceId: payment.invoiceId,
        checkoutUrl: payment.checkoutUrl,
        paymentCurrency: 'twd',
      );
      await PurchaseService.instance.createOrder(uid: uid, purchase: purchase);
      final checkoutUri = Uri.tryParse(payment.checkoutUrl);
      if (checkoutUri != null) {
        await launchUrl(checkoutUri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      setState(() {
        _lastInvoiceId = payment.invoiceId;
        _lastCheckoutUrl = payment.checkoutUrl;
        _lastErrorCode = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('訂單已建立，請完成 Stripe 付款。')));
    } catch (error) {
      if (!mounted) return;
      final errorCode = _extractErrorCode(error.toString());
      setState(() {
        _lastErrorCode = errorCode;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('提交失敗（$errorCode）：$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int _parseAmount(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits);
    if (parsed == null || parsed <= 0) {
      throw StateError('無法解析方案金額：$value');
    }
    return parsed;
  }

  String _extractErrorCode(String text) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(text);
    if (match == null) return 'unknown';
    final raw = match.group(1) ?? 'unknown';
    return raw.contains('/') ? raw.split('/').last : raw;
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
            SelectableText(widget.planName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            SelectableText('價格：${widget.priceLabel}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            SelectableText(
              '提交後狀態為 pending，管理員確認後會更新為 received / complete，'
              '付款狀態會先顯示 checkout_created。您可於方案列表查看最新狀態。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_lastInvoiceId != null)
              SelectableText('Invoice ID：$_lastInvoiceId', style: theme.textTheme.bodySmall),
            if (_lastCheckoutUrl != null) ...[
              SelectableText('Checkout URL：$_lastCheckoutUrl', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: _lastCheckoutUrl!));
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Checkout URL 已複製')));
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('複製付款連結'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = _lastCheckoutUrl;
                      if (url == null) return;
                      final uri = Uri.tryParse(url);
                      if (uri == null) return;
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('重新開啟付款'),
                  ),
                ],
              ),
            ],
            if (_lastErrorCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  '錯誤碼：$_lastErrorCode',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submitOrder,
                child: Text(_submitting ? '建立 Stripe 結帳中…' : '建立付款並送出訂單'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
