import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/app_error_info.dart';
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
  String? _lastPaymentProvider;
  String? _lastErrorCode;
  String? _lastRequestId;
  String? _lastErrorDetail;
  String? _expectedPaymentLinkKey;
  Purchase? _createdOrder;

  Future<void> _submitOrder() async {
    final uid = AuthService.instance.currentUser?.uid;
    final email = AuthService.instance.currentUser?.email;
    if (uid == null) {
      AppFeedback.show(context, message: '請先登入後再結帳', tone: FeedbackTone.error);
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
      _expectedPaymentLinkKey = PaymentService.instance
          .missingHostedLinkKeyForAmount(amount);
      // Validate configuration before creating an order. The stable Firestore
      // order ID is added after creation for Stripe Dashboard reconciliation.
      PaymentService.instance.hostedCheckoutUriForAmount(amount);
      final purchase = Purchase(
        planName: widget.planName,
        priceLabel: widget.priceLabel,
        priceAmount: amount,
        status: 'pending',
        paymentProvider: PaymentProvider.stripe.name,
        paymentStatus: 'awaiting_checkout',
        paymentCurrency: 'twd',
      );
      Purchase created;
      if (_createdOrder == null) {
        created = await PurchaseService.instance.createOrder(
          uid: uid,
          purchase: purchase,
        );
      } else {
        created = _createdOrder!;
      }
      final orderReference = created.id;
      if (orderReference == null || orderReference.isEmpty) {
        throw StateError('payment-order-reference-missing');
      }
      final hostedUri = PaymentService.instance.hostedCheckoutUriForAmount(
        amount,
        clientReferenceId: orderReference,
      );
      final payment = PaymentResult(
        provider: PaymentProvider.stripe,
        invoiceId: 'hosted_$orderReference',
        checkoutUrl: hostedUri.toString(),
      );
      final checkoutOrder = created.copyWith(
        paymentProvider: payment.provider.name,
        paymentStatus: 'checkout_created',
        invoiceId: payment.invoiceId,
        checkoutUrl: payment.checkoutUrl,
        paymentCurrency: 'twd',
      );
      await PurchaseService.instance.updateOrder(
        uid: uid,
        purchase: checkoutOrder,
      );
      final opened = await _openCheckoutUri(
        hostedUri,
        preferSameTabOnWeb: true,
      );
      if (!opened && mounted) {
        AppFeedback.show(
          context,
          message: '付款頁未成功開啟，請檢查 Payment Link 是否可公開使用。',
          tone: FeedbackTone.error,
        );
      }
      if (!mounted) return;
      setState(() {
        _createdOrder = checkoutOrder;
        _lastInvoiceId = payment.invoiceId;
        _lastCheckoutUrl = payment.checkoutUrl;
        _lastPaymentProvider = payment.provider.name;
        _lastErrorCode = null;
        _lastRequestId = null;
        _lastErrorDetail = null;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      AppFeedback.show(
        context,
        message: '訂單已建立，正在前往 Stripe 付款。',
        tone: FeedbackTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      final info = appErrorInfo(error, fallback: '發生未知錯誤，請稍後再試。');
      setState(() {
        _lastErrorCode = info.code;
        _lastRequestId = info.requestId;
        _lastErrorDetail = info.rawDebug;
      });
      logDebugError('checkout.submit.stripe', error);
      AppFeedback.show(
        context,
        message: '${info.message}（${info.code}）',
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

  Future<bool> _openCheckoutUri(Uri uri, {bool preferSameTabOnWeb = true}) {
    return launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb
          ? (preferSameTabOnWeb ? '_self' : '_blank')
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('確認方案與付款方式')),
      body: WarmBackdrop(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHero(
                eyebrow: 'Checkout',
                icon: Icons.credit_card_outlined,
                title: widget.planName,
                subtitle: '參考費用：${widget.priceLabel}；付款前請再次確認方案內容。',
                badges: const ['建立訂單', '前往付款', '回來追蹤狀態'],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              SelectableText(
                '建立訂單後會先顯示為「待確認」。管理員確認付款與服務安排後，會更新處理進度；你可隨時回到「我的方案與狀態」查看。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (_lastInvoiceId != null)
                SelectableText(
                  '付款單號：$_lastInvoiceId',
                  style: theme.textTheme.bodySmall,
                ),
              if (_lastPaymentProvider != null)
                SelectableText(
                  '付款方式：$_lastPaymentProvider',
                  style: theme.textTheme.bodySmall,
                ),
              if (_lastCheckoutUrl != null) ...[
                SelectableText(
                  '付款連結：$_lastCheckoutUrl',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final colorScheme = Theme.of(context).colorScheme;
                        await Clipboard.setData(
                          ClipboardData(text: _lastCheckoutUrl!),
                        );
                        if (!mounted) return;
                        AppFeedback.showWithMessenger(
                          messenger,
                          colorScheme: colorScheme,
                          message: '付款連結已複製；可貼到瀏覽器開啟。',
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
                        if (uri == null ||
                            !(uri.isScheme('https') || uri.isScheme('http'))) {
                          AppFeedback.showWithMessenger(
                            messenger,
                            colorScheme: colorScheme,
                            message: '付款連結格式錯誤，請確認為 https:// 開頭。',
                            tone: FeedbackTone.error,
                          );
                          return;
                        }
                        final opened = await _openCheckoutUri(
                          uri,
                          preferSameTabOnWeb: true,
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
                      label: const Text('再次開啟付款頁'),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      if (_expectedPaymentLinkKey != null)
                        SelectableText(
                          '預期讀取 key：$_expectedPaymentLinkKey',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      if (_lastRequestId != null)
                        SelectableText(
                          'Request ID：$_lastRequestId',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      if (_lastErrorDetail != null)
                        SelectableText(
                          '詳細錯誤：$_lastErrorDetail',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: kIsWeb ? 320 : double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submitOrder,
                  icon: const Icon(Icons.credit_card),
                  label: Text(_submitting ? '正在開啟付款頁…' : '前往 Stripe 安全付款'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '目前免費方案使用 Stripe Payment Link，付款後由管理員依訂單參考編號人工核對。LINE Pay 需要可執行後端確認流程，因此暫不提供。',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
