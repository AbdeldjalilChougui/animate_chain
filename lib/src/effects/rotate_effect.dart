import 'package:flutter/widgets.dart';

import '../effect.dart';

/// Rotates, in turns (1 = 360 degrees), via [RotationTransition].
///
/// Defaults: `begin` -1 and `end` 0. If only `end` is given, `begin` is 0.
@immutable
class RotateEffect extends Effect<double> {
  /// Creates a rotate effect.
  const RotateEffect({
    super.delay,
    super.duration,
    super.curve,
    double? begin,
    double? end,
    this.alignment = Alignment.center,
  }) : super(begin: begin ?? (end == null ? -1.0 : 0.0), end: end ?? 0.0);

  /// The rotation origin, relative to the child.
  final Alignment alignment;

  @override
  Widget build(
    BuildContext context,
    Widget child,
    AnimationController controller,
    EffectEntry entry,
  ) {
    return RotationTransition(
      turns: buildAnimation(controller, entry),
      alignment: alignment,
      child: child,
    );
  }
}

/// Adds `rotate()` to chains.
extension RotateEffectExtensions<T extends EffectChain<T>> on T {
  /// Rotates between two values in turns (see [RotateEffect]).
  T rotate({
    Duration? delay,
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
    Alignment alignment = Alignment.center,
  }) =>
      addEffect(
        RotateEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
          end: end,
          alignment: alignment,
        ),
      );
}
