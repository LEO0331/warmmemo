import 'package:flutter/widgets.dart';

bool isEnglishProductLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode.toLowerCase() == 'en';
}

String productCopy(BuildContext context, {required String zh, required String en}) {
  return isEnglishProductLocale(context) ? en : zh;
}
