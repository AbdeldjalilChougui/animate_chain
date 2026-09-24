import 'package:flutter/widgets.dart';

import '../effect.dart';
import '../internal.dart';

/// Calls [callback] when the playhead crosses this effect's end time.
///
/// The argument is `false` when crossing forward and `true` when crossing in
/// reverse. Looping forward (`repeat()`) fires once per loop. The listener is
/// removed when the widget is disposed.
@immutable
class CallbackEffect extends Effect<void> {
  /// Creates a callback effect.
  const CallbackEffect({
    super.delay,
    super.duration,
    super.curve,
    required this.callback,
  });

  /// Called with `isReverse` on each crossing.
  final ValueChanged<bool> callback;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    final at = entry.endRatio;
    bool forwardHit(double from, double to) =>
        at == 0 ? (from <= 0 && to > 0) : (from < at && at <= to);
    return AnimationTicker(
      animation: controller,
      onTick: (prev, cur) {
        final looping = controller.isAnimating;
        final status = controller.status;
        if (looping && status == AnimationStatus.forward && cur < prev) {
          // Wrapped from the end back to the start.
          if (forwardHit(prev, 1)) callback(false);
          if (forwardHit(-1, cur)) callback(false);
        } else if (looping && status == AnimationStatus.reverse && cur > prev) {
          // Wrapped from the start back to the end.
          if (forwardHit(-1, prev)) callback(true);
          if (forwardHit(cur, 1)) callback(true);
        } else if (cur > prev && forwardHit(prev, cur)) {
          callback(false);
        } else if (cur < prev && forwardHit(cur, prev)) {
          callback(true);
        }
      },
      child: child,
    );
  }
}

/// Adds `callback()` to chains.
extension CallbackEffectExtensions<T extends EffectChain<T>> on T {
  /// Calls [callback] when this effect ends (see [CallbackEffect]).
  T callback({
    required ValueChanged<bool> callback,
    Duration? delay,
    Duration? duration,
  }) =>
      addEffect(
        CallbackEffect(callback: callback, delay: delay, duration: duration),
      );
}
