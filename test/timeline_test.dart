import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('first effect uses Animate defaults', () {
    final a = box.animate().fadeIn();
    expect(a.entries.single.delay, Duration.zero);
    expect(a.entries.single.duration, Animate.defaultDuration);
    expect(a.entries.single.curve, Animate.defaultCurve);
    expect(a.duration, const Duration(milliseconds: 300));
  });

  test('omitted delay, duration and curve inherit from the previous effect',
      () {
    final a = box
        .animate()
        .fadeIn(
          delay: 50.ms,
          duration: 100.ms,
          curve: Curves.easeIn,
        )
        .scale();
    final scale = a.entries[1];
    expect(scale.delay, 50.ms);
    expect(scale.duration, 100.ms);
    expect(scale.curve, Curves.easeIn);
    expect(a.duration, 150.ms);
  });

  test('then() starts following effects at the previous end', () {
    final a = box
        .animate()
        .fade(duration: 100.ms)
        .then(delay: 20.ms)
        .scale(duration: 200.ms)
        .then()
        .slide();
    expect(a.entries[2].delay, 120.ms);
    expect(a.entries[2].duration, 200.ms);
    // The second then() starts at the scale's end (120 + 200).
    expect(a.entries[4].delay, 320.ms);
    // slide inherits the duration carried by then(), from scale.
    expect(a.entries[4].duration, 200.ms);
    expect(a.duration, 520.ms);
  });

  test('explicit delay after then() is relative to the then() baseline', () {
    final a = box.animate().fade(duration: 100.ms).then().scale(delay: 50.ms);
    expect(a.entries[2].delay, 150.ms);
    expect(a.duration, 250.ms);
  });

  test('then() itself never extends the total duration', () {
    final a = box
        .animate()
        .slideX(duration: 3000.ms)
        .then(delay: 0.ms)
        .slideX(duration: 400.ms);
    expect(a.duration, 3400.ms);
  });

  test('then(duration, curve) sets values inherited by the next effects', () {
    final a = box
        .animate()
        .fade(duration: 100.ms)
        .then(duration: 40.ms, curve: Curves.easeOut)
        .scale();
    expect(a.entries[2].duration, 40.ms);
    expect(a.entries[2].curve, Curves.easeOut);
  });

  test('Animate.defaultDuration and defaultCurve are configurable', () {
    addTearDown(() {
      Animate.defaultDuration = const Duration(milliseconds: 300);
      Animate.defaultCurve = Curves.linear;
    });
    Animate.defaultDuration = 1.seconds;
    Animate.defaultCurve = Curves.bounceOut;
    final a = box.animate().fadeIn();
    expect(a.entries.single.duration, 1.seconds);
    expect(a.entries.single.curve, Curves.bounceOut);
  });

  test('declarative effects list equals the chained form', () {
    final a = Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 80)),
        ScaleEffect()
      ],
      child: box,
    );
    expect(a.entries[1].duration, 80.ms);
    expect(a.duration, 80.ms);
  });

  test('entry progress maps controller time through interval and curve', () {
    final a = box
        .animate()
        .fade(duration: 100.ms)
        .scale(delay: 100.ms, duration: 100.ms, curve: Curves.easeIn);
    final scale = a.entries[1];
    expect(scale.progress(0), 0);
    expect(scale.progress(0.5), 0);
    expect(scale.progress(0.75), closeTo(Curves.easeIn.transform(0.5), 1e-9));
    expect(scale.progress(1), 1);
  });

  test('duration extensions', () {
    expect(250.ms, const Duration(milliseconds: 250));
    expect(1.5.seconds, const Duration(milliseconds: 1500));
    expect(2.minutes, const Duration(minutes: 2));
    expect(10.milliseconds, const Duration(milliseconds: 10));
  });
}
