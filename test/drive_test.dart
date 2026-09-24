import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('an external controller drives the effects', (tester) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    await tester.pumpWidget(
      host(
        box.animate(controller: c, autoPlay: false).fadeIn(duration: 200.ms),
      ),
    );
    expect(c.duration, 200.ms, reason: 'duration is set to the total');
    c.value = 0.4;
    await tester.pump();
    expect(opacityOf(tester), closeTo(0.4, 1e-9));
    c.forward();
    await tester.pump();
    await tester.pump(60.ms);
    expect(opacityOf(tester), closeTo(0.7, 1e-9));
    await tester.pump(1.seconds);
  });

  testWidgets('external controller autoPlays like the internal one',
      (tester) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    await tester.pumpWidget(
      host(box.animate(controller: c).fadeIn(duration: 200.ms)),
    );
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(1.seconds);
  });

  testWidgets('switching between internal and external controllers',
      (tester) async {
    final c = TrackingController();
    addTearDown(c.dispose);
    Widget build(AnimationController? ctrl) => host(
          box.animate(controller: ctrl, autoPlay: false).fadeIn(),
        );
    await tester.pumpWidget(build(null));
    await tester.pumpWidget(build(c));
    c.value = 0.5;
    await tester.pump();
    expect(opacityOf(tester), 0.5);
    await tester.pumpWidget(build(null));
    await tester.pumpWidget(build(c));
    await tester.pumpWidget(const SizedBox());
    expect(c.listeners, 0);
    expect(c.statusListeners, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ValueNotifierAdapter drives the value', (tester) async {
    final n = _TrackingNotifier(0.25);
    addTearDown(n.dispose);
    await tester.pumpWidget(
      host(box.animate(adapter: ValueNotifierAdapter(n)).fadeIn()),
    );
    await tester.pump();
    expect(opacityOf(tester), 0.25);
    n.value = 0.8;
    await tester.pump();
    expect(opacityOf(tester), 0.8);
    await tester.pump(1.seconds);
    expect(opacityOf(tester), 0.8, reason: 'adapters prevent autoPlay');
    await tester.pumpWidget(const SizedBox());
    expect(n.attached, isFalse, reason: 'adapter detached on dispose');
  });

  testWidgets('animated adapter eases to the new value', (tester) async {
    final n = ValueNotifier<double>(0);
    addTearDown(n.dispose);
    await tester.pumpWidget(
      host(
        box
            .animate(adapter: ValueNotifierAdapter(n, animated: true))
            .fadeIn(duration: 200.ms),
      ),
    );
    n.value = 1;
    await tester.pump();
    await tester.pump(100.ms);
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    await tester.pump(100.ms);
    expect(opacityOf(tester), 1);
  });

  testWidgets('ChangeNotifierAdapter reads a getter', (tester) async {
    final n = _Counter();
    addTearDown(n.dispose);
    await tester.pumpWidget(
      host(
        box
            .animate(adapter: ChangeNotifierAdapter(n, () => n.count / 10))
            .fadeIn(),
      ),
    );
    n.increment(3);
    await tester.pump();
    expect(opacityOf(tester), closeTo(0.3, 1e-9));
    n.increment(20);
    await tester.pump();
    expect(opacityOf(tester), 1, reason: 'values are clamped to 0-1');
  });

  Widget scrollHost(ScrollController sc, Widget? animated) => host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (animated != null) animated,
            SizedBox(
              height: 200,
              child: ListView(
                controller: sc,
                children: const [SizedBox(height: 1200)],
              ),
            ),
          ],
        ),
      );

  testWidgets('ScrollAdapter maps scroll offset to progress', (tester) async {
    final sc = ScrollController();
    addTearDown(sc.dispose);
    Widget animated() => box.animate(adapter: ScrollAdapter(sc)).fadeIn();
    await tester.pumpWidget(scrollHost(sc, animated()));
    await tester.pump();
    expect(opacityOf(tester), 0);
    // max extent = 1200 - 200 = 1000
    sc.jumpTo(500);
    await tester.pump();
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
    sc.jumpTo(1000);
    await tester.pump();
    expect(opacityOf(tester), 1);
    // Removing the animated widget and scrolling must not throw.
    await tester.pumpWidget(scrollHost(sc, null));
    sc.jumpTo(10);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScrollAdapter attached before the list has clients',
      (tester) async {
    final sc = ScrollController();
    addTearDown(sc.dispose);
    await tester.pumpWidget(
      host(box.animate(adapter: ScrollAdapter(sc)).fadeIn()),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(opacityOf(tester), 0);
  });

  testWidgets('ScrollAdapter begin/end are pixel offsets', (tester) async {
    final sc = ScrollController();
    addTearDown(sc.dispose);
    await tester.pumpWidget(
      scrollHost(
        sc,
        box.animate(adapter: ScrollAdapter(sc, begin: 100, end: 300)).fadeIn(),
      ),
    );
    sc.jumpTo(50);
    await tester.pump();
    expect(opacityOf(tester), 0);
    sc.jumpTo(200);
    await tester.pump();
    expect(opacityOf(tester), closeTo(0.5, 1e-9));
  });
}

class _Counter extends ChangeNotifier {
  int count = 0;
  void increment(int by) {
    count += by;
    notifyListeners();
  }
}

class _TrackingNotifier extends ValueNotifier<double> {
  _TrackingNotifier(super.value);
  bool get attached => hasListeners;
}
