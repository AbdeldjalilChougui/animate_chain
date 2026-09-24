import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('list.animate(interval) staggers each child', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [box, box, box]
              .animate(interval: 100.ms)
              .fadeIn(duration: 200.ms),
        ),
      ),
    );
    expect(find.byType(Animate), findsNWidgets(3));
    await tester.pump(100.ms);
    expect(opacityOf(tester, index: 0), closeTo(0.5, 1e-9));
    expect(opacityOf(tester, index: 1), 0);
    expect(opacityOf(tester, index: 2), 0);
    await tester.pump(100.ms);
    expect(opacityOf(tester, index: 0), 1);
    expect(opacityOf(tester, index: 1), closeTo(0.5, 1e-9));
    expect(opacityOf(tester, index: 2), 0);
    await tester.pump(100.ms);
    expect(opacityOf(tester, index: 1), 1);
    expect(opacityOf(tester, index: 2), closeTo(0.5, 1e-9));
    await tester.pump(100.ms);
    expect(opacityOf(tester, index: 2), 1);
  });

  testWidgets('AnimateList adds its base delay to every child', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          children: AnimateList(
            delay: 100.ms,
            interval: 50.ms,
            effects: const [FadeEffect(duration: Duration(milliseconds: 100))],
            children: const [box, box],
          ),
        ),
      ),
    );
    await tester.pump(100.ms);
    expect(opacityOf(tester, index: 0), 0);
    await tester.pump(50.ms);
    expect(opacityOf(tester, index: 0), closeTo(0.5, 1e-9));
    expect(opacityOf(tester, index: 1), 0);
    await tester.pump(50.ms);
    expect(opacityOf(tester, index: 1), closeTo(0.5, 1e-9));
  });

  testWidgets('Spacer children are passed through unwrapped', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 400,
          child: Column(
            children: const [box, Spacer(), box].animate().fadeIn(),
          ),
        ),
      ),
    );
    expect(find.byType(Animate), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('AnimateList is unmodifiable', () {
    final list = [box].animate();
    expect(() => list.add(box), throwsUnsupportedError);
  });
}
