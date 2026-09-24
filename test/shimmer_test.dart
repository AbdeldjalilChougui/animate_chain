import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _CountingPainter extends CustomPainter {
  int paints = 0;
  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint());
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => false;
}

void main() {
  testWidgets(
      'shimmer uses one ShaderMask layer and never rebuilds or '
      'repaints the child', (tester) async {
    var builds = 0;
    final painter = _CountingPainter();
    final child = Builder(
      builder: (context) {
        builds++;
        return CustomPaint(painter: painter, size: const Size(400, 300));
      },
    );
    await tester.pumpWidget(
      host(
        child.animate(onPlay: (c) => c.repeat()).shimmer(duration: 500.ms),
      ),
    );
    final paintsAfterFirstFrame = painter.paints;
    for (var i = 0; i < 30; i++) {
      await tester.pump(16.ms);
    }
    expect(builds, 1);
    expect(painter.paints, paintsAfterFirstFrame);

    final layers = tester.layers.whereType<ShaderMaskLayer>().toList();
    expect(layers, hasLength(1));
    expect(layers.single.maskRect!.size, const Size(400, 300));
  });

  testWidgets('shimmer does not change the child size', (tester) async {
    await tester.pumpWidget(host(box.animate().shimmer()));
    expect(tester.getSize(find.byType(Animate)), const Size(100, 100));
  });

  testWidgets('shimmer shader changes as the sweep progresses', (tester) async {
    await tester.pumpWidget(host(box.animate().shimmer(duration: 200.ms)));
    await tester.pump(50.ms);
    final a = tester.layers.whereType<ShaderMaskLayer>().single.shader;
    await tester.pump(50.ms);
    final b = tester.layers.whereType<ShaderMaskLayer>().single.shader;
    expect(identical(a, b), isFalse);
  });

  testWidgets('shimmer accepts colors, stops, angle, size and blendMode',
      (tester) async {
    await tester.pumpWidget(
      host(
        box.animate().shimmer(
          colors: const [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF)
          ],
          stops: const [0, 0.5, 1],
          angle: 0.5,
          size: 2,
          blendMode: BlendMode.srcIn,
        ),
      ),
    );
    await tester.pump(100.ms);
    expect(
      tester.layers.whereType<ShaderMaskLayer>().single.blendMode,
      BlendMode.srcIn,
    );
    await tester.pump(300.ms);
  });

  testWidgets('shimmer render object detaches its listener', (tester) async {
    final c = TrackingController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      host(box.animate(controller: c, autoPlay: false).shimmer()),
    );
    expect(c.listeners, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    expect(c.listeners, 0);
    expect(c.statusListeners, 0);
  });
}
