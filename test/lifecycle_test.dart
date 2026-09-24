import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('dispose during a delay', () {
    testWidgets('Animate.delay: removing the widget does not throw',
        (tester) async {
      await tester.pumpWidget(
        host(box.animate(delay: 500.ms).fadeIn()),
      );
      await tester.pump(100.ms);
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump(1.seconds);
      expect(tester.takeException(), isNull);
      // testWidgets also fails if a Timer is left pending.
    });

    testWidgets('staggered list removed mid-stagger does not throw',
        (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: List.filled(8, const SizedBox(width: 10, height: 10))
                .animate(interval: 200.ms)
                .fade(duration: 300.ms),
          ),
        ),
      );
      await tester.pump(250.ms);
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump(3.seconds);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pending target delay is cancelled on dispose', (tester) async {
      await tester.pumpWidget(
        host(box.animate(target: 1, delay: 300.ms).fadeIn()),
      );
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump(1.seconds);
      expect(tester.takeException(), isNull);
    });
  });

  group('onComplete', () {
    testWidgets('fires exactly once for a simple animation', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        host(
          box.animate(onComplete: (_) => completed++).fadeIn(duration: 100.ms),
        ),
      );
      await tester.pump(50.ms);
      // Rebuilds mid-animation must not add extra listeners.
      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(
          host(
            box
                .animate(onComplete: (_) => completed++)
                .fadeIn(duration: 100.ms),
          ),
        );
      }
      await tester.pump(1.seconds);
      expect(completed, 1);
    });

    testWidgets('fires once with an external controller after timing changes',
        (tester) async {
      final c = TrackingController();
      addTearDown(c.dispose);
      var completed = 0;
      Widget build(int ms) => host(
            box
                .animate(
                  controller: c,
                  autoPlay: false,
                  onComplete: (_) => completed++,
                )
                .fadeIn(duration: Duration(milliseconds: ms)),
          );
      await tester.pumpWidget(build(100));
      await tester.pumpWidget(build(200));
      await tester.pumpWidget(build(300));
      await tester.pumpWidget(build(300));
      expect(c.statusListeners, 1);
      c.forward();
      await tester.pump();
      await tester.pump(1.seconds);
      expect(completed, 1);
      // After disposal the old listener must be gone.
      await tester.pumpWidget(const SizedBox());
      c.forward(from: 0);
      await tester.pump();
      await tester.pump(1.seconds);
      expect(completed, 1);
    });

    testWidgets('fires once per loop when repeated from onComplete',
        (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        host(
          box.animate(
            onComplete: (c) {
              completed++;
              if (completed < 3) c.forward(from: 0);
            },
          ).fadeIn(duration: 100.ms),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(50.ms);
      }
      expect(completed, 3);
    });

    testWidgets('onPlay runs before onComplete for zero-duration animations',
        (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        host(
          box
              .animate(
                onPlay: (_) => log.add('play'),
                onComplete: (_) => log.add('complete'),
              )
              .fadeIn(duration: 0.ms),
        ),
      );
      await tester.pump();
      await tester.pump(100.ms);
      expect(log, ['play', 'complete']);
    });

    testWidgets('callbacks may call setState on an ancestor', (tester) async {
      var done = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => box
                .animate(
                  onComplete: (_) => setState(() => done = true),
                )
                .fadeIn(duration: 0.ms),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(done, isTrue);
    });
  });

  group('restarting', () {
    testWidgets('rebuilding with the same chain does not restart',
        (tester) async {
      Widget build(double end) =>
          host(box.animate().fade(duration: 200.ms, begin: 0, end: end));
      await tester.pumpWidget(build(1));
      await tester.pump(100.ms);
      // Values changed, timing did not: updates in place.
      await tester.pumpWidget(build(0.5));
      expect(opacityOf(tester), closeTo(0.25, 1e-9));
      await tester.pump(100.ms);
      expect(opacityOf(tester), 0.5);
    });

    testWidgets('changing the effect timing restarts', (tester) async {
      Widget build(int ms) =>
          host(box.animate().fadeIn(duration: Duration(milliseconds: ms)));
      await tester.pumpWidget(build(200));
      await tester.pump(100.ms);
      expect(opacityOf(tester), closeTo(0.5, 1e-9));
      await tester.pumpWidget(build(400));
      expect(opacityOf(tester), 0);
      await tester.pump(100.ms);
      expect(opacityOf(tester), closeTo(0.25, 1e-9));
    });

    testWidgets('changing the effect types restarts', (tester) async {
      await tester.pumpWidget(host(box.animate().fadeIn(duration: 200.ms)));
      await tester.pump(300.ms);
      await tester.pumpWidget(
        host(box.animate().fadeIn(duration: 200.ms).scaleXY()),
      );
      expect(opacityOf(tester), 0);
    });

    testWidgets('a new key restarts', (tester) async {
      Widget build(Key key) =>
          host(box.animate(key: key).fadeIn(duration: 200.ms));
      await tester.pumpWidget(build(const ValueKey(1)));
      await tester.pump(300.ms);
      expect(opacityOf(tester), 1);
      await tester.pumpWidget(build(const ValueKey(2)));
      expect(opacityOf(tester), 0);
      await tester.pump(300.ms);
    });

    testWidgets('restartOnHotReload restarts on reassemble', (tester) async {
      addTearDown(() => Animate.restartOnHotReload = false);
      await tester.pumpWidget(host(box.animate().fadeIn(duration: 200.ms)));
      await tester.pump(300.ms);

      Animate.restartOnHotReload = false;
      tester.binding.reassembleApplication();
      await tester.pump();
      expect(opacityOf(tester), 1);

      Animate.restartOnHotReload = true;
      tester.binding.reassembleApplication();
      await tester.pump();
      expect(opacityOf(tester), 0);
      await tester.pump(100.ms);
      expect(opacityOf(tester), closeTo(0.5, 1e-9));
      await tester.pump(300.ms);
    });
  });
}
