import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('fadeIn opacity at 0%, 50% and 100%', (tester) async {
    await tester.pumpWidget(host(box.animate().fadeIn(duration: 200.ms)));
    expect(opacityOf(tester), 0);
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 1);
    await tester.pump(500.ms);
    expect(opacityOf(tester), 1);
  });

  testWidgets('fadeOut goes from 1 to 0', (tester) async {
    await tester.pumpWidget(host(box.animate().fadeOut(duration: 200.ms)));
    expect(opacityOf(tester), 1);
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 0);
  });

  testWidgets('a zero-duration effect applies on the first frame',
      (tester) async {
    await tester.pumpWidget(host(box.animate().fadeOut(duration: 0.ms)));
    expect(opacityOf(tester), 0);
  });

  testWidgets('then() delays the next effect until the previous one ends',
      (tester) async {
    await tester.pumpWidget(
      host(
        box
            .animate()
            .fadeIn(duration: 100.ms)
            .then(delay: 50.ms)
            .scaleXY(duration: 200.ms),
      ),
    );
    double scale() => transformOf(tester).entry(0, 0);
    expect(scale(), closeTo(0, 1e-3));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 1);
    expect(scale(), closeTo(0, 1e-3));
    await tester.pump(50.ms);
    expect(scale(), closeTo(0, 1e-3));
    await tester.pump(100.ms);
    expect(scale(), closeTo(0.5, 1e-6));
    await tester.pump(100.ms);
    expect(scale(), 1);
  });

  testWidgets('omitted duration and curve are inherited at runtime',
      (tester) async {
    await tester.pumpWidget(
      host(
        box.animate().fadeIn(duration: 200.ms, curve: Curves.easeIn).scaleXY(),
      ),
    );
    await tester.pump(100.ms);
    final expected = Curves.easeIn.transform(0.5);
    expect(opacityOf(tester), closeTo(expected, 1e-9));
    expect(transformOf(tester).entry(0, 0), closeTo(expected, 1e-6));
    await tester.pump(100.ms);
    expect(transformOf(tester).entry(0, 0), 1);
  });

  testWidgets('Animate.delay postpones the start', (tester) async {
    var played = 0;
    await tester.pumpWidget(
      host(
        box
            .animate(delay: 100.ms, onPlay: (_) => played++)
            .fadeIn(duration: 100.ms),
      ),
    );
    await tester.pump(50.ms);
    expect(opacityOf(tester), 0);
    expect(played, 0);
    await tester.pump(50.ms);
    expect(played, 1);
    await tester.pump(50.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
  });

  testWidgets('autoPlay: false leaves the animation at its start',
      (tester) async {
    await tester.pumpWidget(
      host(box.animate(autoPlay: false).fadeIn(duration: 100.ms)),
    );
    await tester.pump(500.ms);
    expect(opacityOf(tester), 0);
  });

  testWidgets('value sets the initial position and jumps when changed',
      (tester) async {
    await tester.pumpWidget(
      host(box.animate(autoPlay: false, value: 0.25).fadeIn()),
    );
    expect(opacityOf(tester), 0.25);
    await tester.pumpWidget(
      host(box.animate(autoPlay: false, value: 0.75).fadeIn()),
    );
    expect(opacityOf(tester), 0.75);
  });

  testWidgets('onInit exposes the controller before play', (tester) async {
    AnimationController? c;
    await tester.pumpWidget(
      host(box.animate(onInit: (ctrl) => c = ctrl).fadeIn(duration: 100.ms)),
    );
    expect(c, isNotNull);
    expect(c!.duration, 100.ms);
  });
}
