import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

List<double> saturationMatrix(double s) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final i = 1 - s;
  return [
    lr * i + s, lg * i, lb * i, 0, 0, //
    lr * i, lg * i + s, lb * i, 0, 0, //
    lr * i, lg * i, lb * i + s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

void main() {
  testWidgets('slide / slideX / slideY', (tester) async {
    await tester.pumpWidget(host(box.animate().slideY(duration: 100.ms)));
    Offset pos() => effectWidget<SlideTransition>(tester).position.value;
    expect(pos(), const Offset(0, -0.5));
    await tester.pump(100.ms);
    expect(pos(), Offset.zero);

    await tester.pumpWidget(host(box.animate().slideX(begin: 1)));
    expect(pos(), const Offset(1, 0));

    await tester.pumpWidget(
      host(box.animate().slide(begin: const Offset(1, 1), end: Offset.zero)),
    );
    expect(pos(), const Offset(1, 1));
  });

  testWidgets('move / moveX / moveY translate in pixels', (tester) async {
    await tester.pumpWidget(host(box.animate().move(duration: 100.ms)));
    double tx() => transformOf(tester).getTranslation().x;
    double ty() => transformOf(tester).getTranslation().y;
    expect(ty(), -16);
    await tester.pump(50.ms);
    expect(ty(), -8);
    await tester.pump(50.ms);
    expect(ty(), 0);

    await tester.pumpWidget(host(box.animate().moveX(begin: 20)));
    expect(tx(), 20);
    await tester.pumpWidget(host(box.animate().moveY(begin: 0, end: 30)));
    expect(ty(), 0);
  });

  testWidgets('scale / scaleX / scaleY / scaleXY', (tester) async {
    await tester.pumpWidget(
      host(box.animate().scaleXY(begin: 0.5, duration: 100.ms)),
    );
    Matrix4 m() => transformOf(tester);
    expect(m().entry(0, 0), 0.5);
    await tester.pump(50.ms);
    expect(m().entry(0, 0), 0.75);
    expect(m().entry(1, 1), 0.75);

    await tester.pumpWidget(host(box.animate().scaleX(begin: 0.2)));
    expect(m().entry(0, 0), closeTo(0.2, 1e-9));
    expect(m().entry(1, 1), 1);

    await tester.pumpWidget(host(box.animate().scaleY(begin: 0.2)));
    expect(m().entry(0, 0), 1);
    expect(m().entry(1, 1), closeTo(0.2, 1e-9));

    // A zero scale is clamped so the matrix stays invertible.
    await tester.pumpWidget(host(box.animate().scale()));
    expect(m().entry(0, 0), greaterThan(0));
    expect(m().determinant(), isNot(0));
  });

  testWidgets('rotate in turns', (tester) async {
    await tester.pumpWidget(host(box.animate().rotate(duration: 100.ms)));
    double turns() => effectWidget<RotationTransition>(tester).turns.value;
    expect(turns(), -1);
    await tester.pump(50.ms);
    expect(turns(), -0.5);
    await tester.pump(50.ms);
    expect(turns(), 0);
  });

  testWidgets('flip / flipH / flipV', (tester) async {
    await tester.pumpWidget(host(box.animate().flip(duration: 100.ms)));
    Matrix4 m() => transformOf(tester);
    // Half a turn back (-0.5) about the X axis: edge-on at the start.
    expect(m().entry(1, 1), closeTo(0, 1e-9));
    await tester.pump(100.ms);
    expect(m().entry(1, 1), closeTo(1, 1e-9));
    expect(m().entry(0, 0), closeTo(1, 1e-9));

    await tester.pumpWidget(host(box.animate().flipH(begin: 0.25)));
    expect(m().entry(0, 0), closeTo(math.cos(math.pi / 4), 1e-9));
    expect(m().entry(1, 1), closeTo(1, 1e-9));

    await tester.pumpWidget(host(box.animate().flipV(begin: 0.25)));
    expect(m().entry(1, 1), closeTo(math.cos(math.pi / 4), 1e-9));
  });

  testWidgets('blur / blurX / blurY / blurXY', (tester) async {
    await tester.pumpWidget(host(box.animate().blur(duration: 100.ms)));
    ImageFiltered f() => effectWidget<ImageFiltered>(tester);
    expect(f().enabled, isFalse, reason: 'sigma 0 disables the filter');
    await tester.pump(50.ms);
    expect(f().enabled, isTrue);
    expect(f().imageFilter, ImageFilter.blur(sigmaX: 2, sigmaY: 2));

    await tester.pumpWidget(host(box.animate().blurX(begin: 6)));
    expect(f().imageFilter, ImageFilter.blur(sigmaX: 6, sigmaY: 0));
    await tester.pumpWidget(host(box.animate().blurY(begin: 6)));
    expect(f().imageFilter, ImageFilter.blur(sigmaX: 0, sigmaY: 6));
    await tester.pumpWidget(host(box.animate().blurXY(begin: 3)));
    expect(f().imageFilter, ImageFilter.blur(sigmaX: 3, sigmaY: 3));
  });

  testWidgets('blur never goes negative with an overshooting curve',
      (tester) async {
    await tester.pumpWidget(
      host(
        box.animate().blurXY(
            begin: 4, end: 0, duration: 100.ms, curve: Curves.easeInBack),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(10.ms);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tint mixes a colour over the content', (tester) async {
    const red = Color(0xFFFF0000);
    await tester.pumpWidget(
      host(box.animate().tint(color: red, duration: 100.ms)),
    );
    ColorFilter? f() => effectWidget<ColorFiltered>(tester).colorFilter;
    expect(
      f(),
      ColorFilter.mode(Color.lerp(null, red, 0)!, BlendMode.srcATop),
    );
    await tester.pump(50.ms);
    expect(
      f(),
      ColorFilter.mode(Color.lerp(null, red, 0.5)!, BlendMode.srcATop),
    );
    await tester.pumpWidget(host(box.animate().untint(color: red)));
    expect(f(), const ColorFilter.mode(red, BlendMode.srcATop));
  });

  testWidgets('color applies a ColorFilter.mode', (tester) async {
    const blue = Color(0xFF0000FF);
    await tester.pumpWidget(
      host(
        box
            .animate()
            .color(end: blue, blendMode: BlendMode.modulate, duration: 100.ms),
      ),
    );
    ColorFilter? f() => effectWidget<ColorFiltered>(tester).colorFilter;
    await tester.pump(50.ms);
    expect(
      f(),
      ColorFilter.mode(Color.lerp(null, blue, 0.5)!, BlendMode.modulate),
    );
    await tester.pump(50.ms);
    expect(f(), const ColorFilter.mode(blue, BlendMode.modulate));
  });

  testWidgets('saturate / desaturate', (tester) async {
    await tester.pumpWidget(host(box.animate().saturate(duration: 100.ms)));
    ColorFilter? f() => effectWidget<ColorFiltered>(tester).colorFilter;
    expect(f(), ColorFilter.matrix(saturationMatrix(0)));
    await tester.pump(50.ms);
    expect(f(), ColorFilter.matrix(saturationMatrix(0.5)));
    await tester.pump(50.ms);
    expect(f(), ColorFilter.matrix(saturationMatrix(1)));

    await tester.pumpWidget(host(box.animate().desaturate()));
    expect(f(), ColorFilter.matrix(saturationMatrix(1)));
  });

  testWidgets('shake / shakeX / shakeY rest at zero at both ends',
      (tester) async {
    await tester.pumpWidget(host(box.animate().shakeX(duration: 500.ms)));
    double x() => transformOf(tester).getTranslation().x;
    expect(x(), closeTo(0, 1e-9));
    var maxAbs = 0.0;
    for (var i = 0; i < 50; i++) {
      await tester.pump(10.ms);
      maxAbs = math.max(maxAbs, x().abs());
    }
    expect(maxAbs, greaterThan(1));
    expect(maxAbs, lessThanOrEqualTo(5 + 1e-9));
    expect(x(), closeTo(0, 1e-9));

    await tester.pumpWidget(host(box.animate().shakeY(amount: 10)));
    await tester.pump(20.ms);
    expect(transformOf(tester).getTranslation().x, closeTo(0, 1e-9));

    // Default shake rotates.
    await tester.pumpWidget(host(box.animate().shake(duration: 500.ms)));
    await tester.pump(20.ms);
    expect(transformOf(tester).entry(0, 1), isNot(closeTo(0, 1e-6)));
  });

  testWidgets('custom receives the tweened value', (tester) async {
    await tester.pumpWidget(
      host(
        box.animate().custom(
              duration: 100.ms,
              begin: 10,
              end: 20,
              builder: (context, value, child) => Text('v=$value'),
            ),
      ),
    );
    expect(find.text('v=10.0'), findsOneWidget);
    await tester.pump(50.ms);
    expect(find.text('v=15.0'), findsOneWidget);
    await tester.pump(50.ms);
    expect(find.text('v=20.0'), findsOneWidget);
  });

  testWidgets('visibility / show / hide switch at the effect end',
      (tester) async {
    await tester.pumpWidget(
      host(box.animate().visibility(duration: 100.ms)),
    );
    bool visible() => effectWidget<Visibility>(tester).visible;
    expect(visible(), isFalse);
    await tester.pump(50.ms);
    expect(visible(), isFalse);
    await tester.pump(50.ms);
    expect(visible(), isTrue);

    // A new key starts a fresh animation.
    await tester.pumpWidget(
      host(box.animate(key: const ValueKey('h')).hide(duration: 100.ms)),
    );
    expect(visible(), isTrue);
    await tester.pump(100.ms);
    expect(visible(), isFalse);
    expect(effectWidget<Visibility>(tester).maintainSize, isTrue);
  });

  testWidgets('callback fires once when the playhead passes its end',
      (tester) async {
    final calls = <bool>[];
    await tester.pumpWidget(
      host(
        box
            .animate()
            .fadeIn(duration: 200.ms)
            .callback(duration: 100.ms, callback: calls.add),
      ),
    );
    await tester.pump(50.ms);
    expect(calls, isEmpty);
    await tester.pump(60.ms);
    expect(calls, [false]);
    await tester.pump(200.ms);
    expect(calls, [false]);
  });

  testWidgets('callback reports reverse crossings', (tester) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    final calls = <bool>[];
    await tester.pumpWidget(
      host(
        box
            .animate(controller: c, autoPlay: false)
            .fadeIn(duration: 200.ms)
            .callback(duration: 100.ms, callback: calls.add),
      ),
    );
    c.value = 0.8;
    await tester.pump();
    c.value = 0.2;
    await tester.pump();
    expect(calls, [false, true]);
    await tester.pumpWidget(const SizedBox());
    c.value = 0.9;
    expect(calls, [false, true], reason: 'listener removed on dispose');
  });

  testWidgets('listen reports values between begin and end', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(
      host(
        box.animate().listen(
              duration: 100.ms,
              begin: 0,
              end: 10,
              callback: values.add,
            ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(10.ms);
    }
    expect(values, isNotEmpty);
    expect(values.last, 10);
    for (var i = 1; i < values.length; i++) {
      expect(values[i], greaterThanOrEqualTo(values[i - 1]));
    }
    final count = values.length;
    await tester.pump(100.ms);
    expect(values.length, count, reason: 'no calls once the value is stable');
  });

  testWidgets('swap replaces the child and preceding effects', (tester) async {
    await tester.pumpWidget(
      host(
        const Text('A').animate().fadeOut(duration: 100.ms).swap(
            builder: (context, original) =>
                Column(children: [original, const Text('B')])),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    await tester.pump(100.ms);
    expect(find.text('B'), findsOneWidget);
    // The original child is passed without the fadeOut.
    expect(
      find.ancestor(of: find.text('A'), matching: find.byType(FadeTransition)),
      findsNothing,
    );
  });

  testWidgets('toggle passes true before and false after the effect end',
      (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      host(
        Animate().toggle(
          duration: 100.ms,
          builder: (context, value, child) {
            builds++;
            return Text(value ? 'before' : 'after');
          },
        ),
      ),
    );
    expect(find.text('before'), findsOneWidget);
    await tester.pump(50.ms);
    await tester.pump(40.ms);
    expect(find.text('before'), findsOneWidget);
    await tester.pump(10.ms);
    expect(find.text('after'), findsOneWidget);
    expect(builds, 2, reason: 'rebuilds only when the value flips');
  });

  test('effects are const-constructible with sensible defaults', () {
    const fade = FadeEffect();
    expect(fade.begin, 0);
    expect(fade.end, 1);
    const fadeTo = FadeEffect(end: 0.5);
    expect(fadeTo.begin, 1);
    const blur = BlurEffect();
    expect(blur.begin, Offset.zero);
    expect(blur.end, const Offset(4, 4));
  });
}
