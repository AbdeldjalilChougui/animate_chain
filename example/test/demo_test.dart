import 'package:animate_chain_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo app builds, animates, replays and scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('fadeIn'), findsOneWidget);

    await tester.tap(find.byTooltip('Replay'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.text('target (tap me)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('target (tap me)'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Remove everything so looping animations stop.
    await tester.pumpWidget(const SizedBox());
  });
}
