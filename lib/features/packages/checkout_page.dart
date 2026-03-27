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
  String? _lastErrorDetail;
  String? _expectedPaymentLinkKey;
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
    try {
      final amount = _parseAmount(widget.priceLabel);
      const paymentStatus = 'checkout_created';
      _expectedPaymentLinkKey = PaymentService.instance.missingHostedLinkKeyForAmount(amount);
      final hostedUrl = PaymentService.instance.hostedCheckoutUrlForAmount(amount);
      if (hostedUrl == null || hostedUrl.isEmpty) {
        final key = PaymentService.instance.missingHostedLinkKeyForAmount(amount);
        throw StateError('payment-link-missing:$key');
      }
      final hostedUri = Uri.tryParse(hostedUrl);
      if (hostedUri == null || !(hostedUri.isScheme('https') || hostedUri.isScheme('http'))) {
        throw StateError('payment-link-invalid');
      }
      final payment = PaymentResult(
        provider: PaymentProvider.stripe,
        invoiceId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        checkoutUrl: hostedUrl,
      );
      final purchase = Purchase(
        planName: widget.planName,
        priceLabel: widget.priceLabel,
        priceAmount: amount,
        status: 'pending',
        paymentProvider: payment.provider.name,
        paymentStatus: paymentStatus,
        invoiceId: payment.invoiceId,
        checkoutUrl: payment.checkoutUrl,
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
      final opened = await _openCheckoutUri(hostedUri, preferSameTabOnWeb: true);
      if (!opened && mounted) {
        AppFeedback.show(
          context,
          message: '付款頁未成功開啟，請檢查 Payment Link 是否可公開使用。',
          tone: FeedbackTone.error,
        );
      }
      if (!mounted) return;
      setState(() {
        _createdOrder = created;
        _lastInvoiceId = payment.invoiceId;
        _lastCheckoutUrl = payment.checkoutUrl;
        _lastErrorCode = null;
      });
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();
      AppFeedback.show(
        context,
        message: '訂單已建立，正在前往 Stripe 付款。',
        tone: FeedbackTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      final errorCode = _extractErrorCode(error.toString());
      setState(() {
        _lastErrorCode = errorCode;
        _lastErrorDetail = error.toString();
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

  String _extractErrorCode(String text) {
    if (text.contains('payment-link-missing:')) {
      final key = text.split('payment-link-missing:').last;
      return 'payment-link-missing ($key)';
    }
    if (text.contains('payment-link-missing')) return 'payment-link-missing';
    if (text.contains('payment-link-invalid')) return 'payment-link-invalid';
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(text);
    if (match == null) return 'unknown';
    final raw = match.group(1) ?? 'unknown';
    return raw.contains('/') ? raw.split('/').last : raw;
  }

  Future<bool> _openCheckoutUri(Uri uri, {bool preferSameTabOnWeb = true}) {
    return launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? (preferSameTabOnWeb ? '_self' : '_blank') : null,
    );
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
                      if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
                        AppFeedback.showWithMessenger(
                          messenger,
                          colorScheme: colorScheme,
                          message: '付款連結格式錯誤，請確認為 https:// 開頭。',
                          tone: FeedbackTone.error,
                        );
                        return;
                      }
                      final opened = await _openCheckoutUri(uri, preferSameTabOnWeb: true);
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
            if (_lastErrorCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      '錯誤碼：$_lastErrorCode'
                      '${_lastErrorCode == 'payment-link-invalid' ? '（付款連結格式錯誤）' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    ),
                    if (_expectedPaymentLinkKey != null)
                      SelectableText(
                        '預期讀取 key：$_expectedPaymentLinkKey',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    if (_lastErrorDetail != null)
                      SelectableText(
                        '詳細錯誤：$_lastErrorDetail',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submitOrder,
                child: Text(_submitting ? '前往中…' : '前往 Stripe 付款'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
