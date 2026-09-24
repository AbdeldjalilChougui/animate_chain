import 'package:animate_chain/animate_chain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] with the minimum ancestors the effects need.
Widget host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// A small fixed-size box used as animation target.
const Widget box = SizedBox(width: 100, height: 100);

/// Finds a widget of type [T] inside the [index]th [Animate].
T effectWidget<T extends Widget>(WidgetTester tester, {int index = 0}) {
  return tester.widget<T>(
    find
        .descendant(
          of: find.byType(Animate).at(index),
          matching: find.byType(T),
        )
        .first,
  );
}

/// Current opacity applied by a fade effect inside the [index]th [Animate].
double opacityOf(WidgetTester tester, {int index = 0}) =>
    effectWidget<FadeTransition>(tester, index: index).opacity.value;

/// Current transform matrix inside the [index]th [Animate].
Matrix4 transformOf(WidgetTester tester, {int index = 0}) =>
    effectWidget<Transform>(tester, index: index).transform;

/// An [AnimationController] that counts its registered listeners, used to
/// prove that nothing is left attached after disposal.
class TrackingController extends AnimationController {
  /// Creates a controller driven by a [TestVSync].
  TrackingController() : super(vsync: const TestVSync());

  /// Value listeners currently registered.
  int listeners = 0;

  /// Status listeners currently registered.
  int statusListeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners++;
    super.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners--;
    super.removeStatusListener(listener);
  }
}
