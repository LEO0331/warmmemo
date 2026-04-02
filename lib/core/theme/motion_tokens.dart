import 'package:flutter/material.dart';

class MotionTokens {
  const MotionTokens._();

  static const Duration button = Duration(milliseconds: 180);
  static const Duration reveal = Duration(milliseconds: 460);
  static const Duration dialog = Duration(milliseconds: 320);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve gentleCurve = Curves.easeOutSine;

  static const int heroDelayMs = 40;
  static const int sectionDelayMs = 70;
  static const int listStartDelayMs = 80;
  static const int listStepDelayMs = 42;

  static int staggerDelay(int index, {int start = listStartDelayMs}) {
    return start + (index * listStepDelayMs);
  }
}
