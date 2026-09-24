import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Slides by a fraction of the child's size (via [SlideTransition]).
///
/// Defaults: `begin` `Offset(0, -0.5)` and `end` `Offset.zero`. If only
/// `end` is given, `begin` is `Offset.zero`.
@immutable
class SlideEffect extends Effect<Offset> {
  /// Creates a slide effect.
  const SlideEffect({
    super.delay,
    super.duration,
    super.curve,
    Offset? begin,
    Offset? end,
  }) : super(
          begin: begin ?? (end == null ? const Offset(0, -0.5) : Offset.zero),
          end: end ?? Offset.zero,
        );

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return SlideTransition(
      position: buildAnimation(controller, entry),
      child: child,
    );
  }
}

/// Adds slide effects to chains.
extension SlideEffectExtensions<T extends EffectChain<T>> on T {
  /// Slides between two fractional offsets (see [SlideEffect]).
  T slide({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    Offset? begin,
    Offset? end,
  }) =>
      addEffect(
        SlideEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
        ),
      );

  /// Slides horizontally. Defaults: `begin` -0.5, `end` 0.
  T slideX({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) {
    final b = begin ?? (end == null ? -0.5 : 0.0);
    return addEffect(
      SlideEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: Offset(b, 0),
        end: Offset(end ?? 0, 0),
      ),
    );
  }

  /// Slides vertically. Defaults: `begin` -0.5, `end` 0.
  T slideY({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) {
    final b = begin ?? (end == null ? -0.5 : 0.0);
    return addEffect(
      SlideEffect(
        delay: delay,
        duration: duration,
        curve: curve,
        begin: Offset(0, b),
        end: Offset(0, end ?? 0),
      ),
    );
  }
}
