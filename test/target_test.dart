import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Widget targeted(double target, {Duration delay = Duration.zero}) => host(
      box.animate(target: target, delay: delay).fadeIn(duration: 200.ms),
    );

void main() {
  testWidgets('target animates from 0 to the target on mount', (tester) async {
    await tester.pumpWidget(targeted(1));
    expect(opacityOf(tester), 0);
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 1);
  });

  testWidgets('target 0 on mount does not animate', (tester) async {
    await tester.pumpWidget(targeted(0));
    await tester.pump(300.ms);
    expect(opacityOf(tester), 0);
  });

  testWidgets('changing target animates smoothly to the new value',
      (tester) async {
    await tester.pumpWidget(targeted(1));
    await tester.pump(300.ms);
    expect(opacityOf(tester), 1);
    await tester.pumpWidget(targeted(0));
    expect(opacityOf(tester), 1);
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 0);
  });

  testWidgets('a quick target reversal continues from the current value',
      (tester) async {
    await tester.pumpWidget(targeted(1));
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pumpWidget(targeted(0));
    // No restart: still at the midpoint, now heading down.
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(50.ms);
    expect(opacityOf(tester), closeTo(0.25, 1e-9));
    await tester.pumpWidget(targeted(1));
    expect(opacityOf(tester), closeTo(0.25, 1e-9));
    await tester.pump(50.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(500.ms);
    expect(opacityOf(tester), 1);
  });

  testWidgets('rebuilding with the same target does not restart',
      (tester) async {
    await tester.pumpWidget(targeted(1));
    await tester.pump(100.ms);
    await tester.pumpWidget(targeted(1));
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(50.ms);
    expect(opacityOf(tester), closeTo(0.75, 1e-9));
  });

  testWidgets(
      'delay applies to every target change, and only the latest '
      'target inside the delay window is played', (tester) async {
    await tester.pumpWidget(targeted(0, delay: 100.ms));
    await tester.pumpWidget(targeted(1, delay: 100.ms));
    await tester.pump(50.ms);
    await tester.pumpWidget(targeted(0, delay: 100.ms));
    // The pending "go to 1" must never fire.
    for (var i = 0; i < 10; i++) {
      await tester.pump(50.ms);
      expect(opacityOf(tester), 0);
    }
    await tester.pumpWidget(targeted(1, delay: 100.ms));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 0);
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
  });

  testWidgets('autoPlay: false with a target jumps to it on mount',
      (tester) async {
    await tester.pumpWidget(
      host(box.animate(target: 1, autoPlay: false).fadeIn()),
    );
    expect(opacityOf(tester), 1);
  });
}
