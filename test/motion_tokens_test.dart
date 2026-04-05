import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/theme/motion_tokens.dart';
import 'package:flutter/animation.dart';

void main() {
  test('MotionTokens expose expected timing rhythm', () {
    expect(MotionTokens.button.inMilliseconds, 180);
    expect(MotionTokens.reveal.inMilliseconds, greaterThan(MotionTokens.button.inMilliseconds));
    expect(MotionTokens.dialog.inMilliseconds, 320);
    expect(MotionTokens.heroDelayMs, 40);
    expect(MotionTokens.sectionDelayMs, 70);
    expect(MotionTokens.enterCurve, Curves.easeOutCubic);
    expect(MotionTokens.gentleCurve, Curves.easeOutSine);
  });

  test('MotionTokens staggerDelay increases by step', () {
    expect(MotionTokens.staggerDelay(0), MotionTokens.listStartDelayMs);
    expect(
      MotionTokens.staggerDelay(3),
      MotionTokens.listStartDelayMs + (3 * MotionTokens.listStepDelayMs),
    );
    expect(
      MotionTokens.staggerDelay(2, start: 120),
      120 + (2 * MotionTokens.listStepDelayMs),
    );
  });
}
