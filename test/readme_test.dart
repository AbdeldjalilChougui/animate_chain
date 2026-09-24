// Keeps the README usage snippets compiling and running.
import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class SkewEffect extends Effect<double> {
  const SkewEffect({
    super.delay,
    super.duration,
    super.curve,
    super.begin = 0.3,
    super.end = 0,
  });

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final skew = buildAnimation(controller, entry);
    return AnimatedBuilder(
      animation: skew,
      child: child,
      builder: (_, child) =>
          Transform(transform: Matrix4.skewX(skew.value), child: child),
    );
  }
}

void main() {
  testWidgets('README usage snippets run', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    const items = ['a', 'b'];
    final selected = items.isNotEmpty;
    const runId = 1;
    const card = SizedBox(width: 20, height: 20);
    const placeholder = SizedBox(width: 20, height: 20);
    const header = Text('header');

    const pop = <Effect<Object?>>[
      FadeEffect(duration: Duration(milliseconds: 200)),
      ScaleEffect(begin: Offset(0.8, 0.8), curve: Curves.easeOutBack),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            controller: scrollController,
            children: [
              const Text('Hello')
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut)
                  .then(delay: 200.ms)
                  .shakeX(),
              Animate(effects: pop, child: const Icon(Icons.star)),
              Column(
                children: [
                  for (final item in items) ListTile(title: Text(item)),
                ].animate(interval: 60.ms).fadeIn().moveX(begin: -24),
              ),
              card
                  .animate(target: selected ? 1 : 0)
                  .scaleXY(begin: 1, end: 1.05)
                  .tint(end: 0.2),
              placeholder
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms),
              header
                  .animate(adapter: ScrollAdapter(scrollController, end: 300))
                  .fadeOut(begin: 1),
              box.animate(key: const ValueKey(runId)).fadeIn(),
              box.animate().addEffect(const SkewEffect()),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(100.ms);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
