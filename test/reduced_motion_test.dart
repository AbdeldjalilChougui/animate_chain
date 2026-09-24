import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('disableAnimations jumps to the end state, skipping delays',
      (tester) async {
    var played = 0, completed = 0;
    await tester.pumpWidget(
      host(
        box
            .animate(
              delay: 1.seconds,
              onPlay: (_) => played++,
              onComplete: (_) => completed++,
            )
            .fadeIn(delay: 500.ms, duration: 1.seconds),
        disableAnimations: true,
      ),
    );
    expect(opacityOf(tester), 1);
    await tester.pump();
    expect(completed, 1);
    expect(played, 0, reason: 'onPlay (often used to loop) is skipped');
    await tester.pump(5.seconds);
    expect(completed, 1);
  });

  testWidgets('disableAnimations with a target jumps to the target',
      (tester) async {
    Widget build(double t) => host(
          box.animate(target: t).fadeIn(duration: 200.ms),
          disableAnimations: true,
        );
    await tester.pumpWidget(build(1));
    expect(opacityOf(tester), 1);
    await tester.pumpWidget(build(0));
    expect(opacityOf(tester), 0);
  });

  testWidgets('respectReducedMotion: false keeps animating', (tester) async {
    await tester.pumpWidget(
      host(
        box.animate(respectReducedMotion: false).fadeIn(duration: 200.ms),
        disableAnimations: true,
      ),
    );
    expect(opacityOf(tester), 0);
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
  });

  testWidgets('Animate.defaultRespectReducedMotion is the global default',
      (tester) async {
    addTearDown(() => Animate.defaultRespectReducedMotion = true);
    Animate.defaultRespectReducedMotion = false;
    await tester.pumpWidget(
      host(box.animate().fadeIn(duration: 200.ms), disableAnimations: true),
    );
    expect(opacityOf(tester), 0);
    await tester.pump(300.ms);
  });

  testWidgets('turning reduced motion on mid-animation finishes it',
      (tester) async {
    Widget build(bool reduce) => host(
          box.animate().fadeIn(duration: 200.ms),
          disableAnimations: reduce,
        );
    await tester.pumpWidget(build(false));
    await tester.pump(50.ms);
    expect(opacityOf(tester), closeTo(0.25, 1e-9));
    await tester.pumpWidget(build(true));
    expect(opacityOf(tester), 1);
  });
}
