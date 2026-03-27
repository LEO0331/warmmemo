// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

void clearPaymentQueryParam() {
  final uri = Uri.parse(html.window.location.href);
  final params = Map<String, String>.from(uri.queryParameters);
  if (!params.containsKey('payment')) return;

  params.remove('payment');
  final cleaned = uri.replace(
    queryParameters: params.isEmpty ? null : params,
  );

  html.window.history.replaceState(null, html.document.title, cleaned.toString());
}
