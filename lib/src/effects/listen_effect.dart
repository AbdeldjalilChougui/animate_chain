import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../effect.dart';
import '../internal.dart';

/// Calls [callback] with the value tweened from [begin] (default 0) to
/// [end] (default 1), whenever it changes. Useful to drive a
/// `ValueNotifier` or other state from the animation.
///
/// The callback only fires while this effect's interval is progressing,
/// and the listener is removed when the widget is disposed.
@immutable
class ListenEffect extends Effect<double> {
  /// Creates a listen effect.
  const ListenEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    required this.callback,
  }) : super(begin: begin ?? 0.0, end: end ?? 1.0);

  /// Receives the current value.
  final ValueChanged<double> callback;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return AnimationTicker(
      animation: controller,
      onTick: (prev, cur) {
        final p = entry.linearProgress(cur);
        if (p == entry.linearProgress(prev)) return;
        callback(lerpDouble(begin, end, entry.curve.transform(p))!);
      },
      child: child,
    );
  }
}

/// Adds `listen()` to chains.
extension ListenEffectExtensions<T extends EffectChain<T>> on T {
  /// Adds a [ListenEffect].
  T listen({
    required ValueChanged<double> callback,
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) =>
      addEffect(
        ListenEffect(
          callback: callback,
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        ),
      );
}
