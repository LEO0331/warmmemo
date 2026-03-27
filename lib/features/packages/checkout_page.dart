import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/widgets/app_feedback.dart';
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
  Purchase? _createdOrder;

  Future<void> _submitOrder() async {
    final uid = AuthService.instance.currentUser?.uid;
    final email = AuthService.instance.currentUser?.email;
    if (uid == null) {
      AppFeedback.show(
        context,
        message: '請先登入後再結帳',
        tone: FeedbackTone.error,
      );
      return;
    }
    if (email == null || email.isEmpty) {
      AppFeedback.show(
        context,
        message: '缺少使用者 Email，無法建立 Stripe 結帳連結。',
        tone: FeedbackTone.error,
      );
      return;
    }

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final amount = _parseAmount(widget.priceLabel);
      PaymentResult? payment;
      var paymentStatus = 'awaiting_checkout';
      try {
        payment = await PaymentService.instance.createInvoice(
          email: email,
          name: email.split('@').first,
          amountCents: amount,
          description: 'WarmMemo 方案：${widget.planName}',
          provider: PaymentProvider.stripe,
        );
        paymentStatus = 'checkout_created';
      } catch (error) {
        // Web 常見 XHR/CORS 問題下，先保留訂單讓客服可後續跟進與補發連結。
        final errorCode = _extractErrorCode(error.toString());
        setState(() {
          _lastErrorCode = errorCode;
          _lastCheckoutUrl = null;
          _lastInvoiceId = null;
        });
        AppFeedback.showWithMessenger(
          messenger,
          colorScheme: colorScheme,
          message: '付款連結建立失敗（$errorCode），已先建立待付款訂單，請稍後重試。',
          tone: FeedbackTone.error,
        );
      }
      final purchase = Purchase(
        planName: widget.planName,
        priceLabel: widget.priceLabel,
        priceAmount: amount,
        status: 'pending',
        paymentProvider: payment?.provider.name ?? PaymentProvider.stripe.name,
        paymentStatus: paymentStatus,
        invoiceId: payment?.invoiceId,
        checkoutUrl: payment?.checkoutUrl,
        paymentCurrency: 'twd',
      );
      Purchase created;
      if (_createdOrder == null) {
        created = await PurchaseService.instance.createOrder(uid: uid, purchase: purchase);
      } else {
        created = _createdOrder!.copyWith(
          paymentProvider: purchase.paymentProvider,
          paymentStatus: purchase.paymentStatus,
          invoiceId: purchase.invoiceId,
          checkoutUrl: purchase.checkoutUrl,
          paymentCurrency: purchase.paymentCurrency,
        );
        await PurchaseService.instance.updateOrder(uid: uid, purchase: created);
      }
      final checkoutUri = Uri.tryParse(payment?.checkoutUrl ?? '');
      if (checkoutUri != null) {
        final opened = await launchUrl(
          checkoutUri,
          mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        if (!opened && mounted) {
          AppFeedback.show(
            context,
            message: '付款頁未成功開啟，請使用「重新開啟付款」或複製連結手動開啟。',
            tone: FeedbackTone.error,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _createdOrder = created;
        _lastInvoiceId = payment?.invoiceId;
        _lastCheckoutUrl = payment?.checkoutUrl;
        if (payment != null) _lastErrorCode = null;
      });
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();
      if (payment != null) {
        AppFeedback.show(
          context,
          message: '訂單已建立，請完成 Stripe 付款。',
          tone: FeedbackTone.success,
        );
      } else {
        AppFeedback.show(
          context,
          message: '訂單已建立為待付款。你可稍後重試建立付款連結。',
          tone: FeedbackTone.info,
        );
      }
    } catch (error) {
      if (!mounted) return;
      final errorCode = _extractErrorCode(error.toString());
      setState(() {
        _lastErrorCode = errorCode;
      });
      AppFeedback.show(
        context,
        message: '提交失敗（$errorCode）',
        tone: FeedbackTone.error,
        actionLabel: '重試',
        onAction: _submitOrder,
      );
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

  Future<void> _markPaymentStatus(String paymentStatus) async {
    final uid = AuthService.instance.currentUser?.uid;
    final order = _createdOrder;
    if (uid == null || order == null) return;
    setState(() => _submitting = true);
    try {
      final updated = order.copyWith(
        paymentStatus: paymentStatus,
      );
      await PurchaseService.instance.updateOrder(uid: uid, purchase: updated);
      if (!mounted) return;
      setState(() {
        _createdOrder = updated;
      });
      AppFeedback.show(
        context,
        message: '已更新付款狀態：$paymentStatus',
        tone: FeedbackTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      final code = _extractErrorCode(error.toString());
      setState(() => _lastErrorCode = code);
      AppFeedback.show(
        context,
        message: '更新付款狀態失敗（$code）',
        tone: FeedbackTone.error,
        actionLabel: '重試',
        onAction: () => _markPaymentStatus(paymentStatus),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              '付款狀態會先顯示 checkout_created（Spark 模式可使用固定 Payment Link）。您可於方案列表查看最新狀態。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_lastInvoiceId != null)
              SelectableText('付款單號：$_lastInvoiceId', style: theme.textTheme.bodySmall),
            if (_lastCheckoutUrl != null) ...[
              SelectableText('Checkout URL：$_lastCheckoutUrl', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final colorScheme = Theme.of(context).colorScheme;
                      await Clipboard.setData(ClipboardData(text: _lastCheckoutUrl!));
                      if (!mounted) return;
                      AppFeedback.showWithMessenger(
                        messenger,
                        colorScheme: colorScheme,
                        message: 'Checkout URL 已複製',
                        tone: FeedbackTone.success,
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('複製付款連結'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final colorScheme = Theme.of(context).colorScheme;
                      final url = _lastCheckoutUrl;
                      if (url == null) return;
                      final uri = Uri.tryParse(url);
                      if (uri == null) return;
                      final opened = await launchUrl(
                        uri,
                        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
                        webOnlyWindowName: '_blank',
                      );
                      if (!opened && mounted) {
                        AppFeedback.showWithMessenger(
                          messenger,
                          colorScheme: colorScheme,
                          message: '付款頁未成功開啟，請先複製連結再於瀏覽器貼上。',
                          tone: FeedbackTone.error,
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('重新開啟付款'),
                  ),
                ],
              ),
            ],
            if (_createdOrder != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_lastCheckoutUrl == null)
                    OutlinedButton(
                      onPressed: _submitting ? null : _submitOrder,
                      child: const Text('重試建立付款連結'),
                    ),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _markPaymentStatus('cancelled'),
                    child: const Text('取消付款'),
                  ),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _markPaymentStatus('expired'),
                    child: const Text('付款逾時'),
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
